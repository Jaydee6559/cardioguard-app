import 'dart:convert';

enum WearableState { normal, fallPending, emergency }

enum ArduinoEvent {
  systemReady,
  sos,
  possibleFall,
  fallCancelled,
  fallEmergency,
  emergencyCleared,
  userOk,
}

enum ArduinoMessageType { heartRate, acceleration, state, event, invalid }

class ArduinoMessage {
  const ArduinoMessage({
    required this.type,
    required this.receivedAt,
    this.heartRate,
    this.accelerationG,
    this.state,
    this.event,
  });

  final ArduinoMessageType type;
  final DateTime receivedAt;
  final int? heartRate;
  final double? accelerationG;
  final WearableState? state;
  final ArduinoEvent? event;
}

class ArduinoProtocolParser {
  static const maxLineBytes = 1024;

  final List<int> _buffer = [];
  bool _discardUntilNewline = false;

  List<ArduinoMessage> addBytes(List<int> bytes, {DateTime? receivedAt}) {
    final messages = <ArduinoMessage>[];
    final time = receivedAt ?? DateTime.now();

    for (final byte in bytes) {
      if (_discardUntilNewline) {
        if (byte == 0x0A) _discardUntilNewline = false;
        continue;
      }

      if (byte == 0x0A) {
        final line = utf8.decode(_buffer, allowMalformed: true).trim();
        _buffer.clear();
        if (line.isNotEmpty) messages.add(_parseLine(line, time));
        continue;
      }

      _buffer.add(byte);
      if (_buffer.length > maxLineBytes) {
        _buffer.clear();
        _discardUntilNewline = true;
      }
    }

    return messages;
  }

  void reset() {
    _buffer.clear();
    _discardUntilNewline = false;
  }

  ArduinoMessage _parseLine(String line, DateTime receivedAt) {
    final heartRate = RegExp(r'^HR:(NA|[0-9]+)$').firstMatch(line);
    if (heartRate != null) {
      return ArduinoMessage(
        type: ArduinoMessageType.heartRate,
        heartRate: heartRate[1] == 'NA' ? null : int.parse(heartRate[1]!),
        receivedAt: receivedAt,
      );
    }

    final acceleration = RegExp(r'^G:([+-]?(?:[0-9]+(?:\.[0-9]*)?|\.[0-9]+))$')
        .firstMatch(line);
    if (acceleration != null) {
      final value = double.parse(acceleration[1]!);
      if (value.isFinite) {
        return ArduinoMessage(
          type: ArduinoMessageType.acceleration,
          accelerationG: value,
          receivedAt: receivedAt,
        );
      }
    }

    final state = switch (line) {
      'STATE:NORMAL' => WearableState.normal,
      'STATE:FALL_PENDING' => WearableState.fallPending,
      'STATE:EMERGENCY' => WearableState.emergency,
      _ => null,
    };
    if (state != null) {
      return ArduinoMessage(
        type: ArduinoMessageType.state,
        state: state,
        receivedAt: receivedAt,
      );
    }

    final event = switch (line) {
      'EVENT:SYSTEM_READY' => ArduinoEvent.systemReady,
      'EVENT:SOS' => ArduinoEvent.sos,
      'EVENT:POSSIBLE_FALL' => ArduinoEvent.possibleFall,
      'EVENT:FALL_CANCELLED' => ArduinoEvent.fallCancelled,
      'EVENT:FALL_EMERGENCY' => ArduinoEvent.fallEmergency,
      'EVENT:EMERGENCY_CLEARED' => ArduinoEvent.emergencyCleared,
      'EVENT:USER_OK' => ArduinoEvent.userOk,
      _ => null,
    };
    if (event != null) {
      return ArduinoMessage(
        type: ArduinoMessageType.event,
        event: event,
        receivedAt: receivedAt,
      );
    }

    return ArduinoMessage(
      type: ArduinoMessageType.invalid,
      receivedAt: receivedAt,
    );
  }
}
