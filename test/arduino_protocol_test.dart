import 'dart:convert';

import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:cardioguard/services/arduino_protocol.dart';

void main() {
  group('ArduinoProtocolParser', () {
    late ArduinoProtocolParser parser;

    setUp(() => parser = ArduinoProtocolParser());

    test('parses supported sensor values, states and events', () {
      final now = DateTime(2026, 10, 20, 9);
      final messages = parser.addBytes(
        utf8.encode(
          'HR:78\nHR:NA\nG:1.02\n'
          'STATE:NORMAL\nSTATE:FALL_PENDING\nSTATE:EMERGENCY\n'
          'EVENT:SYSTEM_READY\nEVENT:SOS\nEVENT:POSSIBLE_FALL\n'
          'EVENT:FALL_CANCELLED\nEVENT:FALL_EMERGENCY\n'
          'EVENT:EMERGENCY_CLEARED\nEVENT:USER_OK\n',
        ),
        receivedAt: now,
      );

      expect(messages.map((message) => message.type), [
        ArduinoMessageType.heartRate,
        ArduinoMessageType.heartRate,
        ArduinoMessageType.acceleration,
        ArduinoMessageType.state,
        ArduinoMessageType.state,
        ArduinoMessageType.state,
        ...List.filled(7, ArduinoMessageType.event),
      ]);
      expect(messages[0].heartRate, 78);
      expect(messages[1].heartRate, isNull);
      expect(messages[2].accelerationG, 1.02);
      expect(messages[3].state, WearableState.normal);
      expect(messages[4].state, WearableState.fallPending);
      expect(messages[5].state, WearableState.emergency);
      expect(
        messages.skip(6).map((message) => message.event),
        ArduinoEvent.values,
      );
      expect(messages.every((message) => message.receivedAt == now), isTrue);
    });

    test('buffers fragmented records and handles multiple CRLF/LF records', () {
      expect(parser.addBytes(utf8.encode('HR:7')), isEmpty);
      final firstPart = parser.addBytes(utf8.encode('8\r\nG:1.'));
      expect(firstPart.single.heartRate, 78);

      final secondPart = parser.addBytes(utf8.encode('02\nSTATE:NORMAL\r\n'));
      expect(secondPart.map((message) => message.type), [
        ArduinoMessageType.acceleration,
        ArduinoMessageType.state,
      ]);
      expect(secondPart.first.accelerationG, 1.02);
      expect(secondPart.last.state, WearableState.normal);
    });

    test('ignores malformed and unknown lines including a bare EVENT', () {
      final messages = parser.addBytes([
        ...utf8.encode('EVENT\nHR:not-a-number\nG:NaN\nSTATE:EMERGENCY_NOW\n'),
        0xFF,
        0x0A,
        ...utf8.encode('HR:78\n'),
      ]);

      expect(messages.map((message) => message.type), [
        ArduinoMessageType.invalid,
        ArduinoMessageType.invalid,
        ArduinoMessageType.invalid,
        ArduinoMessageType.invalid,
        ArduinoMessageType.invalid,
        ArduinoMessageType.heartRate,
      ]);
      expect(messages.last.heartRate, 78);
      expect(
        messages.where((message) => message.event == ArduinoEvent.sos),
        isEmpty,
      );
    });

    test('discards an oversized line and resumes at the next newline', () {
      final bytes = <int>[
        ...List.filled(ArduinoProtocolParser.maxLineBytes + 10, 0x41),
        0x0A,
        ...utf8.encode('HR:72\n'),
      ];
      final messages = parser.addBytes(bytes);
      expect(messages.single.heartRate, 72);
    });
  });

  test('HM-10 short UUIDs normalize to their full UUIDs', () {
    expect(Guid('FFE0'), Guid('0000FFE0-0000-1000-8000-00805F9B34FB'));
    expect(Guid('FFE1'), Guid('0000FFE1-0000-1000-8000-00805F9B34FB'));
  });
}
