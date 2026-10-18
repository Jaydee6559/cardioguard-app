import 'package:audioplayers/audioplayers.dart';
import 'package:vibration/vibration.dart';

/// Looping alarm sound + repeating vibration for the emergency screens.
///
/// It keeps going until [stop] is called (someone responds), so the
/// Fall Detected → No Response → Emergency Alert screens can each call
/// [start] safely: a second call while it is already ringing does nothing.
class AlarmService {
  AlarmService._();

  /// Turned off in widget tests, where there is no speaker or vibrator.
  static bool enabled = true;

  static AudioPlayer? _player;
  static bool _ringing = false;
  static bool _muted = false;

  static bool get isRinging => _ringing;
  static bool get isMuted => _muted;

  /// Starts sound and vibration (if not already running).
  static Future<void> start() async {
    if (!enabled || _ringing) return;
    _ringing = true;
    _muted = false;
    await _startSound();
    await _startVibration();
  }

  /// Stops sound and vibration — call when someone responds.
  static Future<void> stop() async {
    if (!enabled) return;
    _ringing = false;
    _muted = false;
    try {
      await _player?.stop();
    } catch (_) {
      // Player already released.
    }
    try {
      await Vibration.cancel();
    } catch (_) {
      // No vibrator on this device.
    }
  }

  /// Silences the sound but keeps vibrating (e.g. in a classroom demo).
  static Future<void> mute() async {
    if (!enabled || !_ringing) return;
    _muted = true;
    try {
      await _player?.stop();
    } catch (_) {
      // Player already released.
    }
  }

  /// Turns the sound back on after [mute].
  static Future<void> unmute() async {
    if (!enabled || !_ringing || !_muted) return;
    _muted = false;
    await _startSound();
  }

  static Future<void> _startSound() async {
    try {
      final player = _player ??= AudioPlayer();
      // Play on the phone's ALARM channel, so it uses the alarm volume and
      // is heard even when media volume is turned down.
      await player.setAudioContext(AudioContext(
        android: AudioContextAndroid(
          usageType: AndroidUsageType.alarm,
          contentType: AndroidContentType.sonification,
        ),
        iOS: AudioContextIOS(),
      ));
      await player.setReleaseMode(ReleaseMode.loop);
      await player.play(AssetSource('sounds/alarm.wav'));
    } catch (_) {
      // Sound is best-effort: vibration and the screen still alert.
    }
  }

  static Future<void> _startVibration() async {
    try {
      if (await Vibration.hasVibrator() != true) return;
      // wait 0 ms, vibrate 700 ms, pause 500 ms … repeat from the start.
      await Vibration.vibrate(pattern: [0, 700, 500], repeat: 0);
    } catch (_) {
      // No vibrator on this device.
    }
  }
}
