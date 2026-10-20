import 'package:flutter/material.dart';

import '../services/ble_service.dart';
import '../services/arduino_protocol.dart';
import '../theme.dart';
import '../utils/formatters.dart';
import '../widgets/screen_header.dart';
import '../widgets/section_card.dart';
import '../widgets/settings_rows.dart';

class DeviceScreen extends StatelessWidget {
  const DeviceScreen({super.key});

  @override
  Widget build(BuildContext context) {
    AppColors.watch(context);
    final ble = BleService.instance;
    return AnimatedBuilder(
      animation: ble,
      builder: (context, _) {
        final busy =
            ble.isScanning ||
            ble.connectionStatus == BleConnectionStatus.connecting;
        return Scaffold(
          appBar: const SubpageAppBar(),
          body: ListView(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
            children: [
              const ScreenHeader(kicker: 'Status', title: 'Device & Sensors'),
              const SizedBox(height: 18),
              SectionCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Expanded(
                          child: CardLabel('Arduino BLE connection'),
                        ),
                        _ConnectionBadge(ble),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Bluetooth adapter: ${_adapterLabel(ble.adapterStatus)}',
                    ),
                    if (ble.selectedDevice != null) ...[
                      const SizedBox(height: 8),
                      Text(
                        ble.selectedDevice!.name,
                        style: TextStyle(
                          color: AppColors.textPrimary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 2),
                      SelectableText(
                        ble.selectedDevice!.id,
                        style: TextStyle(
                          color: AppColors.textMuted,
                          fontSize: 12,
                        ),
                      ),
                    ],
                    const SizedBox(height: 14),
                    if (ble.isConnected)
                      OutlinedButton.icon(
                        onPressed: ble.disconnect,
                        icon: const Icon(Icons.bluetooth_disabled),
                        label: const Text('Disconnect'),
                      )
                    else if (ble.selectedDevice != null)
                      OutlinedButton.icon(
                        onPressed: busy ? null : ble.reconnect,
                        icon: const Icon(Icons.bluetooth_searching),
                        label: const Text('Reconnect'),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 14),
              SectionCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Expanded(child: CardLabel('Heart rate')),
                        Text(
                          ble.heartRate == null
                              ? 'Unavailable'
                              : '${ble.heartRate} BPM',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textPrimary,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    _readingTime(ble.heartRateReceivedAt, ble.isConnected),
                  ],
                ),
              ),
              const SizedBox(height: 10),
              SectionCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Expanded(child: CardLabel('Acceleration')),
                        Text(
                          ble.accelerationG == null
                              ? 'Unavailable'
                              : '${ble.accelerationG!.toStringAsFixed(2)} g',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textPrimary,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    _readingTime(ble.accelerationReceivedAt, ble.isConnected),
                  ],
                ),
              ),
              const SizedBox(height: 10),
              SectionCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const CardLabel('Arduino emergency state'),
                    const SizedBox(height: 6),
                    Text(
                      _wearableStateLabel(ble),
                      style: TextStyle(
                        fontSize: 19,
                        fontWeight: FontWeight.w700,
                        color: _wearableStateColor(ble),
                      ),
                    ),
                    if (ble.stateReceivedAt != null) ...[
                      const SizedBox(height: 4),
                      Text(
                        'Last reported ${Formatters.date(ble.stateReceivedAt!)} at ${Formatters.clock(ble.stateReceivedAt!)}'
                        '${ble.isConnected ? '' : ' · stale while disconnected'}',
                        style: TextStyle(
                          color: AppColors.textFaint,
                          fontSize: 13,
                        ),
                      ),
                    ],
                    if (ble.lastEvent != null) ...[
                      const SizedBox(height: 12),
                      const CardLabel('Last Arduino event'),
                      const SizedBox(height: 4),
                      Text(
                        _eventLabel(ble.lastEvent!),
                        style: TextStyle(color: AppColors.textPrimary),
                      ),
                      if (ble.lastEventReceivedAt != null)
                        Text(
                          '${Formatters.date(ble.lastEventReceivedAt!)} at ${Formatters.clock(ble.lastEventReceivedAt!)}',
                          style: TextStyle(
                            color: AppColors.textFaint,
                            fontSize: 13,
                          ),
                        ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 18),
              FilledButton.icon(
                onPressed: busy || ble.isConnected ? null : ble.scan,
                icon: ble.isScanning
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.bluetooth_searching),
                label: Text(
                  ble.isScanning ? 'Scanning…' : 'Scan for BLE devices',
                ),
                style: FilledButton.styleFrom(
                  minimumSize: const Size.fromHeight(48),
                ),
              ),
              if (ble.isScanning) ...[
                const SizedBox(height: 12),
                const LinearProgressIndicator(),
                const SizedBox(height: 8),
                Text(
                  'Searching nearby BLE devices…',
                  style: TextStyle(color: AppColors.textMuted),
                ),
              ],
              if (ble.scanComplete &&
                  ble.devices.isEmpty &&
                  !ble.isScanning &&
                  ble.error == null) ...[
                const SizedBox(height: 12),
                Text(
                  'No BLE devices found. Make sure the Arduino is powered, Bluetooth is on, and the module is not connected to nRF Connect or another phone.',
                  style: TextStyle(color: AppColors.textMuted),
                ),
              ],
              if (ble.devices.isNotEmpty) ...[
                const SizedBox(height: 18),
                const CardLabel('Nearby BLE devices'),
                const SizedBox(height: 10),
                for (final device in ble.devices) ...[
                  _DeviceResult(device: device, ble: ble),
                  const SizedBox(height: 10),
                ],
              ],
              if (ble.error != null) ...[
                const SizedBox(height: 12),
                SectionCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Bluetooth needs attention',
                        style: TextStyle(
                          color: AppColors.emergency,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 6),
                      SelectableText(
                        ble.error!,
                        style: TextStyle(color: AppColors.textPrimary),
                      ),
                      if (ble.permissionSettingsRequired) ...[
                        const SizedBox(height: 8),
                        TextButton.icon(
                          onPressed: ble.openPermissionSettings,
                          icon: const Icon(Icons.settings),
                          label: const Text('Open app settings'),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ],
          ),
        );
      },
    );
  }

  static Widget _readingTime(DateTime? time, bool connected) {
    final stale =
        time != null &&
        (!connected ||
            DateTime.now().difference(time) > const Duration(seconds: 30));
    final text = time == null
        ? 'No reading received'
        : 'Last received ${Formatters.date(time)} at ${Formatters.clock(time)}${stale ? ' · stale' : ' · live'}';
    return Text(
      text,
      style: TextStyle(color: AppColors.textFaint, fontSize: 13),
    );
  }

  static String _adapterLabel(BleAdapterStatus state) => switch (state) {
    BleAdapterStatus.unknown => 'Checking',
    BleAdapterStatus.on => 'On',
    BleAdapterStatus.off => 'Off',
    BleAdapterStatus.unauthorized => 'Permission denied',
    BleAdapterStatus.unavailable => 'Unavailable',
  };

  static String _wearableStateLabel(BleService ble) {
    final prefix = ble.isReadingStale(ble.stateReceivedAt)
        ? 'Last known · '
        : '';
    return switch (ble.wearableState) {
      WearableState.normal => '${prefix}Normal',
      WearableState.fallPending =>
        '${prefix}Possible fall · awaiting Arduino outcome',
      WearableState.emergency => '${prefix}Emergency',
      null => 'Unavailable',
    };
  }

  static Color _wearableStateColor(BleService ble) =>
      switch (ble.wearableState) {
        WearableState.emergency => AppColors.emergency,
        WearableState.fallPending => AppColors.warning,
        WearableState.normal => AppColors.success,
        null => AppColors.textMuted,
      };

  static String _eventLabel(ArduinoEvent event) => switch (event) {
    ArduinoEvent.systemReady => 'System ready',
    ArduinoEvent.sos => 'SOS',
    ArduinoEvent.possibleFall => 'Possible fall',
    ArduinoEvent.fallCancelled => 'Fall cancelled · wearer OK',
    ArduinoEvent.fallEmergency => 'Fall emergency',
    ArduinoEvent.emergencyCleared => 'Emergency cleared',
    ArduinoEvent.userOk => 'Wearer pressed I’m OK',
  };
}

class _ConnectionBadge extends StatelessWidget {
  const _ConnectionBadge(this.ble);

  final BleService ble;

  @override
  Widget build(BuildContext context) {
    final connected = ble.isConnected;
    final color = connected ? AppColors.success : AppColors.textMuted;
    final label = switch (ble.connectionStatus) {
      BleConnectionStatus.connected => 'Connected',
      BleConnectionStatus.scanning => 'Scanning',
      BleConnectionStatus.connecting => 'Connecting',
      BleConnectionStatus.disconnected => 'Disconnected',
    };
    return Text(
      label,
      style: TextStyle(color: color, fontWeight: FontWeight.w600),
    );
  }
}

class _DeviceResult extends StatelessWidget {
  const _DeviceResult({required this.device, required this.ble});

  final BleDevice device;
  final BleService ble;

  @override
  Widget build(BuildContext context) {
    final selected = ble.selectedDevice?.id == device.id;
    return SectionCard(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          Icon(Icons.bluetooth, color: AppColors.primary),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  device.name,
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 2),
                SelectableText(
                  device.id,
                  style: TextStyle(fontSize: 11, color: AppColors.textMuted),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          if (selected && ble.isConnected)
            Text(
              'Connected',
              style: TextStyle(
                color: AppColors.success,
                fontWeight: FontWeight.w600,
              ),
            )
          else
            TextButton(
              onPressed:
                  ble.connectionStatus == BleConnectionStatus.connecting ||
                      ble.isScanning
                  ? null
                  : () => ble.connect(device),
              child: Text(selected ? 'Reconnect' : 'Connect'),
            ),
        ],
      ),
    );
  }
}
