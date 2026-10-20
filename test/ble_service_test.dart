import 'dart:async';
import 'dart:convert';

import 'package:cardioguard/data/app_state.dart';
import 'package:cardioguard/models/alert_event.dart';
import 'package:cardioguard/services/arduino_protocol.dart';
import 'package:cardioguard/services/ble_service.dart';
import 'package:cardioguard/services/notification_service.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  late FakeBleClient client;
  late BleService service;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    await AppState.init();
    NotificationService.enabled = false;
    client = FakeBleClient();
    service = BleService(client, platformSupported: true);
    await service.initialize();
    client.adapterStatesController.add(BleAdapterStatus.on);
  });

  tearDown(() async {
    service.dispose();
    await client.close();
  });

  test(
    'coalesces duplicate scans and waits for scan completion before cleanup',
    () async {
      final firstScan = service.scan();
      final duplicateScan = service.scan();
      await Future<void>.delayed(Duration.zero);

      expect(client.startScanCalls, 1);
      expect(client.stopScanCalls, 0);

      client.resultsController.add([
        const BleDevice(id: 'AA:BB', name: 'Unnamed BLE device'),
      ]);
      await Future<void>.delayed(Duration.zero);
      expect(service.devices.single.name, 'Unnamed BLE device');
      expect(service.isScanning, isTrue);

      client.finishScan();
      await Future.wait([firstScan, duplicateScan]);
      expect(client.stopScanCalls, 1);
      expect(service.scanComplete, isTrue);
      expect(service.isScanning, isFalse);
    },
  );

  test('does not show Connected until notify enabling succeeds', () async {
    client.enableGate = Completer<void>();
    final connecting = service.connect(
      const BleDevice(id: 'AA:BB', name: 'Arduino'),
    );
    await Future<void>.delayed(const Duration(milliseconds: 1));

    expect(service.connectionStatus, BleConnectionStatus.connecting);
    expect(client.notificationSubscriptionCount, 1);
    expect(client.enableNotificationsCalls, 1);

    client.enableGate!.complete();
    await connecting;
    expect(service.connectionStatus, BleConnectionStatus.connected);
    expect(service.error, isNull);

    client.send('HR:78\r\nG:1.02\nSTATE:NORMAL\n');
    await Future<void>.delayed(Duration.zero);
    expect(service.heartRate, 78);
    expect(service.accelerationG, 1.02);
    expect(service.wearableState, WearableState.normal);
  });

  test(
    'cleans up a connection failure and reports discovered profile details',
    () async {
      client.services = [
        BleGattService(
          uuid: Guid('ABCD'),
          characteristics: [
            BleCharacteristic(
              serviceUuid: Guid('ABCD'),
              characteristicUuid: Guid('ABCE'),
              canNotify: false,
              canIndicate: false,
              properties: 'read',
            ),
          ],
        ),
      ];

      await service.connect(const BleDevice(id: 'AA:BB', name: 'Arduino'));

      expect(service.connectionStatus, BleConnectionStatus.disconnected);
      expect(service.error, contains('abcd'));
      expect(service.error, contains('abce'));
      expect(service.error, contains('read'));
      expect(service.error, isNot(contains('Bad state:')));
      expect(client.disconnectCalls, 1);
    },
  );

  test(
    'notification-enable failure stays disconnected and reports the cause',
    () async {
      client.enableGate = Completer<void>();
      final connecting = service.connect(
        const BleDevice(id: 'AA:BB', name: 'Arduino'),
      );
      await Future<void>.delayed(const Duration(milliseconds: 1));
      client.enableGate!.completeError(StateError('CCCD write was rejected'));
      await connecting;

      expect(service.connectionStatus, BleConnectionStatus.disconnected);
      expect(service.error, contains('CCCD write was rejected'));
      expect(service.error, isNot(contains('Bad state:')));
      expect(client.disconnectCalls, 1);
    },
  );

  test('possible fall stays a warning and state/event overlap raises only one emergency', () async {
    await service.connect(const BleDevice(id: 'AA:BB', name: 'Arduino'));
    client.send('STATE:FALL_PENDING\nEVENT:POSSIBLE_FALL\n');
    await Future<void>.delayed(const Duration(milliseconds: 5));

    expect(
      AppState.events.value
          .where((event) => event.title == 'Possible Fall Detected')
          .length,
      1,
    );
    expect(AppState.events.value.first.severity, Severity.warning);
    expect(client.notificationSubscriptionCount, 1);

    client.send('STATE:EMERGENCY\nEVENT:FALL_EMERGENCY\n');
    await Future<void>.delayed(const Duration(milliseconds: 5));
    expect(
      AppState.events.value
          .where((event) => event.severity == Severity.emergency)
          .length,
      1,
    );
  });

  test(
    'unexpected disconnect keeps readings and marks the device disconnected',
    () async {
      await service.connect(const BleDevice(id: 'AA:BB', name: 'Arduino'));
      client.send('HR:72\n');
      await Future<void>.delayed(Duration.zero);

      client.connectionEventsController.add(
        const BleConnectionEvent('AA:BB', false),
      );
      await Future<void>.delayed(Duration.zero);

      expect(service.connectionStatus, BleConnectionStatus.disconnected);
      expect(service.heartRate, 72);
      expect(service.isReadingStale(service.heartRateReceivedAt), isTrue);
    },
  );
}

class FakeBleClient implements BleClient {
  final adapterStatesController =
      StreamController<BleAdapterStatus>.broadcast();
  final scanningStatesController = StreamController<bool>.broadcast();
  final resultsController = StreamController<List<BleDevice>>.broadcast();
  final connectionEventsController =
      StreamController<BleConnectionEvent>.broadcast();
  final notificationController = StreamController<List<int>>.broadcast();

  bool _isScanning = false;
  int startScanCalls = 0;
  int stopScanCalls = 0;
  int disconnectCalls = 0;
  int enableNotificationsCalls = 0;
  int get notificationSubscriptionCount =>
      notificationController.hasListener ? 1 : 0;
  Completer<void>? enableGate;
  List<BleGattService> services = [
    BleGattService(
      uuid: Guid('0000FFE0-0000-1000-8000-00805F9B34FB'),
      characteristics: [
        BleCharacteristic(
          serviceUuid: Guid('0000FFE0-0000-1000-8000-00805F9B34FB'),
          characteristicUuid: Guid('FFE1'),
          canNotify: true,
          canIndicate: false,
          properties: 'notify',
        ),
      ],
    ),
  ];

  @override
  Stream<BleAdapterStatus> get adapterStates => adapterStatesController.stream;
  @override
  Stream<bool> get scanningStates => scanningStatesController.stream;
  @override
  Stream<List<BleDevice>> get scanResults => resultsController.stream;
  @override
  Stream<BleConnectionEvent> get connectionEvents =>
      connectionEventsController.stream;
  @override
  bool get isScanning => _isScanning;

  @override
  Future<void> requestPermissions() async {}

  @override
  Future<void> startScan(Duration timeout) async {
    startScanCalls++;
    _isScanning = true;
    scanningStatesController.add(true);
  }

  @override
  Future<void> stopScan() async {
    stopScanCalls++;
    _isScanning = false;
    scanningStatesController.add(false);
  }

  void finishScan() {
    _isScanning = false;
    scanningStatesController.add(false);
  }

  @override
  Future<void> connect(BleDevice device) async {
    connectionEventsController.add(BleConnectionEvent(device.id, true));
  }

  @override
  Future<List<BleGattService>> discoverServices() async => services;

  @override
  Stream<List<int>> notifications(BleCharacteristic characteristic) =>
      notificationController.stream;

  @override
  Future<void> enableNotifications(BleCharacteristic characteristic) async {
    enableNotificationsCalls++;
    await enableGate?.future;
  }

  @override
  Future<void> disconnect() async {
    disconnectCalls++;
  }

  void send(String text) => notificationController.add(utf8.encode(text));

  Future<void> close() async {
    await adapterStatesController.close();
    await scanningStatesController.close();
    await resultsController.close();
    await connectionEventsController.close();
    await notificationController.close();
  }
}
