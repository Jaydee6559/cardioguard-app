import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:permission_handler/permission_handler.dart';

import '../data/app_state.dart';
import '../models/alert_event.dart';
import 'arduino_protocol.dart';
import 'flutter_blue_plus_client.dart';
import 'notification_service.dart';

enum BleConnectionStatus { disconnected, scanning, connecting, connected }

enum BleAdapterStatus { unknown, on, off, unauthorized, unavailable }

class BleDevice {
  const BleDevice({required this.id, required this.name});

  final String id;
  final String name;
}

class BleCharacteristic {
  const BleCharacteristic({
    required this.serviceUuid,
    required this.characteristicUuid,
    required this.canNotify,
    required this.canIndicate,
    required this.properties,
  });

  final Guid serviceUuid;
  final Guid characteristicUuid;
  final bool canNotify;
  final bool canIndicate;
  final String properties;
}

class BleGattService {
  const BleGattService({required this.uuid, required this.characteristics});

  final Guid uuid;
  final List<BleCharacteristic> characteristics;
}

class BleConnectionEvent {
  const BleConnectionEvent(this.deviceId, this.isConnected);

  final String deviceId;
  final bool isConnected;
}

abstract interface class BleClient {
  Stream<BleAdapterStatus> get adapterStates;
  Stream<bool> get scanningStates;
  Stream<List<BleDevice>> get scanResults;
  Stream<BleConnectionEvent> get connectionEvents;

  bool get isScanning;
  Future<void> requestPermissions();
  Future<void> startScan(Duration timeout);
  Future<void> stopScan();
  Future<void> connect(BleDevice device);
  Future<List<BleGattService>> discoverServices();
  Stream<List<int>> notifications(BleCharacteristic characteristic);
  Future<void> enableNotifications(BleCharacteristic characteristic);
  Future<void> disconnect();
}

class BleService extends ChangeNotifier {
  BleService(BleClient client, {required bool platformSupported})
    : _client = client,
      _platformSupported = platformSupported {
    if (!platformSupported) {
      adapterStatus = BleAdapterStatus.unavailable;
      error = 'Bluetooth Low Energy is not supported on this platform.';
    }
  }

  static final instance = BleService(
    FlutterBluePlusClient(),
    platformSupported:
        !kIsWeb &&
        (defaultTargetPlatform == TargetPlatform.android ||
            defaultTargetPlatform == TargetPlatform.iOS ||
            defaultTargetPlatform == TargetPlatform.macOS),
  );

  static const scanDuration = Duration(seconds: 12);

  final BleClient _client;
  final bool _platformSupported;
  final ArduinoProtocolParser _parser = ArduinoProtocolParser();
  final Map<String, BleDevice> _devices = {};
  StreamSubscription<BleAdapterStatus>? _adapterSubscription;
  StreamSubscription<List<BleDevice>>? _resultsSubscription;
  StreamSubscription<BleConnectionEvent>? _connectionSubscription;
  StreamSubscription<List<int>>? _notificationSubscription;
  Future<void>? _scanTask;
  Timer? _freshnessTimer;

  BleConnectionStatus connectionStatus = BleConnectionStatus.disconnected;
  BleAdapterStatus adapterStatus = BleAdapterStatus.unknown;
  BleDevice? selectedDevice;
  int? heartRate;
  DateTime? heartRateReceivedAt;
  double? accelerationG;
  DateTime? accelerationReceivedAt;
  WearableState? wearableState;
  DateTime? stateReceivedAt;
  ArduinoEvent? lastEvent;
  DateTime? lastEventReceivedAt;
  String? error;
  bool scanComplete = false;
  bool permissionSettingsRequired = false;
  bool _initialized = false;
  bool _disconnecting = false;
  bool _emergencyActive = false;
  bool _fallPendingLogged = false;
  bool _fallCancelledLogged = false;
  bool _systemReadyLogged = false;

  bool get isScanning => connectionStatus == BleConnectionStatus.scanning;
  bool get isConnected => connectionStatus == BleConnectionStatus.connected;
  List<BleDevice> get devices => List.unmodifiable(_devices.values);
  bool isReadingStale(DateTime? receivedAt) =>
      receivedAt == null ||
      !isConnected ||
      DateTime.now().difference(receivedAt) > const Duration(seconds: 30);

  Future<void> initialize() async {
    if (_initialized) return;
    _initialized = true;
    if (!_platformSupported) {
      notifyListeners();
      return;
    }
    _adapterSubscription = _client.adapterStates.listen(
      (state) {
        adapterStatus = state;
        if (state != BleAdapterStatus.on && isScanning) {
          error = 'Bluetooth is unavailable or turned off. Turn Bluetooth on and try again.';
        }
        notifyListeners();
      },
      onError: (Object e) {
        error = _readableError(e);
        adapterStatus = BleAdapterStatus.unavailable;
        notifyListeners();
      },
    );
    _resultsSubscription = _client.scanResults.listen(
      (results) {
        if (!isScanning) return;
        for (final device in results) {
          _devices[device.id] = device;
        }
        notifyListeners();
      },
      onError: (Object e) {
        error = 'BLE scan failed: ${_readableError(e)}';
        notifyListeners();
      },
    );
    _connectionSubscription = _client.connectionEvents.listen(
      _handleConnectionEvent,
    );
    _freshnessTimer = Timer.periodic(
      const Duration(seconds: 10),
      (_) => notifyListeners(),
    );
  }

  Future<void> scan() {
    if (isConnected || connectionStatus == BleConnectionStatus.connecting) {
      error =
          'Disconnect from the current device before starting another scan.';
      notifyListeners();
      return Future.value();
    }
    final activeScan = _scanTask;
    if (activeScan != null) return activeScan;
    final task = _runScan();
    _scanTask = task;
    return task.whenComplete(() {
      if (identical(_scanTask, task)) _scanTask = null;
    });
  }

  Future<void> _runScan() async {
    error = null;
    permissionSettingsRequired = false;
    scanComplete = false;
    _devices.clear();
    connectionStatus = BleConnectionStatus.scanning;
    notifyListeners();

    try {
      if (!_platformSupported) {
        throw StateError(
          'Bluetooth Low Energy is not supported on this platform.',
        );
      }
      await _client.requestPermissions();
      await _ensureAdapterOn('scan');
      await _client.startScan(scanDuration);
      await _client.scanningStates.where((scanning) => !scanning).first;
      await _client.stopScan();
    } catch (e) {
      error = _readableError(e);
      permissionSettingsRequired = error!.contains('permanently denied');
      if (_client.isScanning) {
        await _client.scanningStates.where((scanning) => !scanning).first;
        try {
          await _client.stopScan();
        } catch (cleanupError) {
          debugPrint(
            'BLE scan cleanup failed: ${_readableError(cleanupError)}',
          );
        }
      }
    } finally {
      if (connectionStatus == BleConnectionStatus.scanning) {
        connectionStatus = BleConnectionStatus.disconnected;
      }
      scanComplete = true;
      notifyListeners();
    }
  }

  Future<void> connect(BleDevice device) async {
    if (connectionStatus == BleConnectionStatus.connecting) return;
    if (isConnected && selectedDevice?.id == device.id) return;
    if (_client.isScanning || _scanTask != null) {
      error = 'Wait for the BLE scan to finish before connecting.';
      notifyListeners();
      return;
    }
    if (isConnected) await disconnect();

    error = null;
    permissionSettingsRequired = false;
    connectionStatus = BleConnectionStatus.connecting;
    selectedDevice = device;
    _devices[device.id] = device;
    _parser.reset();
    _systemReadyLogged = false;
    notifyListeners();

    try {
      if (!_platformSupported) {
        throw StateError(
          'Bluetooth Low Energy is not supported on this platform.',
        );
      }
      await _client.requestPermissions();
      await _ensureAdapterOn('connect');

      await _client.connect(device);
      final services = await _client.discoverServices();
      final service = services
          .where((item) => item.uuid == Guid('FFE0'))
          .firstOrNull;
      final characteristic = service?.characteristics
          .where((item) => item.characteristicUuid == Guid('FFE1'))
          .firstOrNull;
      if (characteristic == null ||
          (!characteristic.canNotify && !characteristic.canIndicate)) {
        throw StateError(_profileDiagnostic(services));
      }

      _notificationSubscription = _client
          .notifications(characteristic)
          .listen(
            _handleNotification,
            onError: (Object e) {
              error = 'BLE notification stream failed: ${_readableError(e)}';
              notifyListeners();
            },
          );
      await _client.enableNotifications(characteristic);
      connectionStatus = BleConnectionStatus.connected;
      error = null;
      notifyListeners();
    } catch (e) {
      final readable = _readableError(e);
      await _cleanupFailedConnection();
      connectionStatus = BleConnectionStatus.disconnected;
      error = readable;
      permissionSettingsRequired = readable.contains('permanently denied');
      notifyListeners();
    }
  }

  Future<void> reconnect() async {
    final device = selectedDevice;
    if (device == null) {
      error = 'No device selected. Scan for the Arduino BLE device first.';
      notifyListeners();
      return;
    }
    await connect(device);
  }

  Future<void> disconnect() async {
    if (_disconnecting) return;
    _disconnecting = true;
    connectionStatus = BleConnectionStatus.disconnected;
    error = null;
    notifyListeners();
    try {
      await _notificationSubscription?.cancel();
      _notificationSubscription = null;
      _parser.reset();
      await _client.disconnect();
    } catch (e) {
      error = 'Disconnect failed: ${_readableError(e)}';
      notifyListeners();
    } finally {
      _disconnecting = false;
    }
  }

  Future<void> openPermissionSettings() => openAppSettings();

  Future<void> _cleanupFailedConnection() async {
    await _notificationSubscription?.cancel();
    _notificationSubscription = null;
    _parser.reset();
    try {
      await _client.disconnect();
    } catch (e) {
      debugPrint('BLE connection cleanup failed: ${_readableError(e)}');
    }
  }

  Future<void> _ensureAdapterOn(String action) async {
    var state = adapterStatus;
    if (state != BleAdapterStatus.on) {
      state = await _client.adapterStates
          .firstWhere((current) => current != BleAdapterStatus.unknown)
          .timeout(
            const Duration(seconds: 5),
            onTimeout: () {
              throw StateError(
                'Could not determine Bluetooth status. Check Bluetooth and try again.',
              );
            },
          );
      adapterStatus = state;
    }
    if (state == BleAdapterStatus.on) return;
    final reason = switch (state) {
      BleAdapterStatus.unauthorized => 'Bluetooth permission is denied. Allow Nearby devices access and try again.',
      BleAdapterStatus.off =>
        'Bluetooth is off. Turn Bluetooth on, then $action again.',
      BleAdapterStatus.unavailable =>
        'Bluetooth is unavailable on this device.',
      BleAdapterStatus.unknown ||
      BleAdapterStatus.on => 'Bluetooth status is unavailable.',
    };
    throw StateError(reason);
  }

  void _handleConnectionEvent(BleConnectionEvent event) {
    if (event.deviceId != selectedDevice?.id ||
        event.isConnected ||
        _disconnecting ||
        !isConnected) {
      return;
    }
    connectionStatus = BleConnectionStatus.disconnected;
    error =
        'Connection to ${selectedDevice?.name ?? 'the BLE device'} was lost. Reconnect to resume live readings.';
    _parser.reset();
    unawaited(_notificationSubscription?.cancel());
    _notificationSubscription = null;
    notifyListeners();
  }

  void _handleNotification(List<int> bytes) {
    final messages = _parser.addBytes(bytes);
    for (final message in messages) {
      switch (message.type) {
        case ArduinoMessageType.heartRate:
          heartRate = message.heartRate;
          heartRateReceivedAt = message.receivedAt;
        case ArduinoMessageType.acceleration:
          accelerationG = message.accelerationG;
          accelerationReceivedAt = message.receivedAt;
        case ArduinoMessageType.state:
          wearableState = message.state;
          stateReceivedAt = message.receivedAt;
          if (message.state == WearableState.normal) {
            _fallPendingLogged = false;
            _fallCancelledLogged = false;
            _clearEmergency();
          } else if (message.state == WearableState.fallPending) {
            _logPossibleFall();
          } else if (message.state == WearableState.emergency) {
            _raiseEmergency(
              'Emergency state',
              'The Arduino reported STATE:EMERGENCY.',
            );
          }
        case ArduinoMessageType.event:
          _handleEvent(message.event!, message.receivedAt);
        case ArduinoMessageType.invalid:
          debugPrint('Ignored unknown or malformed Arduino line.');
      }
      if (message.type != ArduinoMessageType.invalid) notifyListeners();
    }
  }

  void _handleEvent(ArduinoEvent event, DateTime receivedAt) {
    lastEvent = event;
    lastEventReceivedAt = receivedAt;
    switch (event) {
      case ArduinoEvent.systemReady:
        if (!_systemReadyLogged) {
          _systemReadyLogged = true;
          unawaited(
            AppState.logEvent(
              'Wearable System Ready',
              'Arduino reported that its system is ready.',
              Severity.info,
            ),
          );
        }
      case ArduinoEvent.sos:
        _raiseEmergency(
          'SOS button pressed',
          'The Arduino reported EVENT:SOS.',
        );
      case ArduinoEvent.possibleFall:
        _logPossibleFall();
      case ArduinoEvent.fallCancelled:
        if (!_fallCancelledLogged) {
          unawaited(
            AppState.logEvent(
              'Fall Check Cancelled',
              "The wearer pressed the device's I'm OK button.",
              Severity.info,
            ),
          );
        }
        _fallPendingLogged = false;
        _fallCancelledLogged = true;
      case ArduinoEvent.fallEmergency:
        _raiseEmergency(
          'Fall emergency',
          'The Arduino reported EVENT:FALL_EMERGENCY.',
        );
      case ArduinoEvent.emergencyCleared:
        _emergencyActive = false;
        _fallPendingLogged = false;
        unawaited(NotificationService.clear());
      case ArduinoEvent.userOk:
        unawaited(
          AppState.logEvent(
            'Wearer Pressed I’m OK',
            'The Arduino reported EVENT:USER_OK.',
            Severity.info,
          ),
        );
        _emergencyActive = false;
        unawaited(NotificationService.clear());
    }
  }

  void _logPossibleFall() {
    if (_fallPendingLogged) return;
    _fallPendingLogged = true;
    _fallCancelledLogged = false;
    unawaited(
      AppState.logEvent(
        'Possible Fall Detected',
        'The Arduino reported a possible fall. Waiting for its authoritative outcome.',
        Severity.warning,
      ),
    );
  }

  void _raiseEmergency(String title, String description) {
    if (_emergencyActive) return;
    _emergencyActive = true;
    unawaited(AppState.logEvent(title, description, Severity.emergency));
    unawaited(
      NotificationService.showEmergency('EMERGENCY: $title', description),
    );
  }

  void _clearEmergency() {
    if (!_emergencyActive) return;
    _emergencyActive = false;
    unawaited(NotificationService.clear());
  }

  String _profileDiagnostic(List<BleGattService> services) {
    final details = services.isEmpty
        ? 'no services discovered'
        : services
              .map((service) {
                final characteristics = service.characteristics.isEmpty
                    ? 'no characteristics'
                    : service.characteristics
                          .map(
                            (item) =>
                                '${item.characteristicUuid} [${item.properties}]',
                          )
                          .join(', ');
                return '${service.uuid}: $characteristics';
              })
              .join('; ');
    return 'HM-10 profile missing or FFE1 does not support notifications/indications. '
        'Discovered service/characteristic UUIDs and properties: $details';
  }

  String _readableError(Object error) {
    final text = error
        .toString()
        .replaceFirst(RegExp(r'^(Bad state: |Exception: )'), '')
        .trim();
    if (text.contains('permanentlyDenied') ||
        text.contains('permanently denied')) {
      return 'BLE permission permanently denied. Allow Nearby devices (or Location on older Android) in app settings.';
    }
    return text.isEmpty ? 'Unknown Bluetooth error.' : text;
  }

  @override
  void dispose() {
    _freshnessTimer?.cancel();
    unawaited(_adapterSubscription?.cancel());
    unawaited(_resultsSubscription?.cancel());
    unawaited(_connectionSubscription?.cancel());
    unawaited(_notificationSubscription?.cancel());
    super.dispose();
  }
}
