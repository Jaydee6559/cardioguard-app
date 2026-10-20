import 'dart:async';

import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:permission_handler/permission_handler.dart';

import 'ble_service.dart';

class FlutterBluePlusClient implements BleClient {
  final StreamController<BleConnectionEvent> _connectionEvents =
      StreamController<BleConnectionEvent>.broadcast();
  final Map<String, BluetoothDevice> _knownDevices = {};
  final Map<String, BluetoothCharacteristic> _knownCharacteristics = {};
  BluetoothDevice? _connectedDevice;
  StreamSubscription<BluetoothConnectionState>? _deviceConnectionSubscription;

  @override
  Stream<BleAdapterStatus> get adapterStates =>
      FlutterBluePlus.adapterState.map(
        (state) => switch (state) {
          BluetoothAdapterState.on => BleAdapterStatus.on,
          BluetoothAdapterState.off ||
          BluetoothAdapterState.turningOff ||
          BluetoothAdapterState.turningOn => BleAdapterStatus.off,
          BluetoothAdapterState.unauthorized => BleAdapterStatus.unauthorized,
          BluetoothAdapterState.unavailable => BleAdapterStatus.unavailable,
          BluetoothAdapterState.unknown => BleAdapterStatus.unknown,
        },
      );

  @override
  Stream<bool> get scanningStates => FlutterBluePlus.isScanning;

  @override
  Stream<List<BleDevice>> get scanResults =>
      FlutterBluePlus.scanResults.map((results) {
        return results.map((result) {
          final device = result.device;
          _knownDevices[device.remoteId.str] = device;
          final advertisedName = result.advertisementData.advName.trim();
          final platformName = device.platformName.trim();
          return BleDevice(
            id: device.remoteId.str,
            name: advertisedName.isNotEmpty
                ? advertisedName
                : platformName.isNotEmpty
                ? platformName
                : 'Unnamed BLE device',
          );
        }).toList();
      });

  @override
  Stream<BleConnectionEvent> get connectionEvents => _connectionEvents.stream;

  @override
  bool get isScanning => FlutterBluePlus.isScanningNow;

  @override
  Future<void> requestPermissions() async {
    if (defaultTargetPlatform == TargetPlatform.android) {
      final sdk = (await DeviceInfoPlugin().androidInfo).version.sdkInt;
      final permissions = sdk >= 31
          ? [Permission.bluetoothScan, Permission.bluetoothConnect]
          : [Permission.locationWhenInUse];
      final statuses = await permissions.request();
      if (statuses.values.any((status) => !status.isGranted)) {
        final denied = statuses.values.firstWhere(
          (status) => !status.isGranted,
        );
        if (denied.isPermanentlyDenied) {
          throw StateError(
            'BLE permission permanently denied. Allow Nearby devices (or Location on older Android) in app settings.',
          );
        }
        throw StateError(
          sdk >= 31
              ? 'Nearby devices permission is required to scan and connect.'
              : 'Location permission is required for BLE scanning on Android 11 and older.',
        );
      }
      if (sdk <= 30) {
        final location = await Permission.locationWhenInUse.serviceStatus;
        if (location.isDisabled) {
          throw StateError(
            'Turn on Location services to scan for BLE devices on Android 11 and older.',
          );
        }
      }
    } else if (defaultTargetPlatform == TargetPlatform.iOS) {
      final status = await Permission.bluetooth.request();
      if (!status.isGranted) {
        throw StateError('Bluetooth permission is required to connect.');
      }
    }
  }

  @override
  Future<void> startScan(Duration timeout) =>
      FlutterBluePlus.startScan(timeout: timeout);

  @override
  Future<void> stopScan() => FlutterBluePlus.stopScan();

  @override
  Future<void> connect(BleDevice device) async {
    final selected = _knownDevices[device.id];
    if (selected == null) {
      throw StateError(
        'The selected BLE device is no longer available. Scan again.',
      );
    }
    await _deviceConnectionSubscription?.cancel();
    _connectedDevice = selected;
    _deviceConnectionSubscription = selected.connectionState.listen((state) {
      _connectionEvents.add(
        BleConnectionEvent(
          device.id,
          state == BluetoothConnectionState.connected,
        ),
      );
    });
    await selected.connect(
      timeout: const Duration(seconds: 35),
      autoConnect: false,
    );
  }

  @override
  Future<List<BleGattService>> discoverServices() async {
    final device = _connectedDevice;
    if (device == null) {
      throw StateError('No BLE device is connected.');
    }

    final services = await device.discoverServices();
    final result = <BleGattService>[];
    _knownCharacteristics.clear();
    for (final service in services) {
      final characteristics = <BleCharacteristic>[];
      for (final characteristic in service.characteristics) {
        final properties = <String>[
          if (characteristic.properties.read) 'read',
          if (characteristic.properties.write) 'write',
          if (characteristic.properties.writeWithoutResponse)
            'write without response',
          if (characteristic.properties.notify) 'notify',
          if (characteristic.properties.indicate) 'indicate',
        ];
        final descriptor = BleCharacteristic(
          serviceUuid: service.uuid,
          characteristicUuid: characteristic.uuid,
          canNotify: characteristic.properties.notify,
          canIndicate: characteristic.properties.indicate,
          properties: properties.isEmpty ? 'none' : properties.join(', '),
        );
        _knownCharacteristics[_key(descriptor)] = characteristic;
        characteristics.add(descriptor);
      }
      result.add(
        BleGattService(uuid: service.uuid, characteristics: characteristics),
      );
    }
    return result;
  }

  @override
  Stream<List<int>> notifications(BleCharacteristic characteristic) {
    final native = _knownCharacteristics[_key(characteristic)];
    if (native == null) {
      throw StateError(
        'The BLE notification characteristic is no longer available.',
      );
    }
    return native.onValueReceived;
  }

  @override
  Future<void> enableNotifications(BleCharacteristic characteristic) async {
    final native = _knownCharacteristics[_key(characteristic)];
    if (native == null) {
      throw StateError(
        'The BLE notification characteristic is no longer available.',
      );
    }
    await native.setNotifyValue(
      true,
      forceIndications: !characteristic.canNotify && characteristic.canIndicate,
    );
  }

  @override
  Future<void> disconnect() async {
    await _deviceConnectionSubscription?.cancel();
    _deviceConnectionSubscription = null;
    final device = _connectedDevice;
    _connectedDevice = null;
    if (device != null) await device.disconnect();
    _knownCharacteristics.clear();
  }

  String _key(BleCharacteristic characteristic) =>
      '${characteristic.serviceUuid}/${characteristic.characteristicUuid}';
}
