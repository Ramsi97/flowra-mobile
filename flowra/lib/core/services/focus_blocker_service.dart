import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

/// A single focus block expressed as absolute epoch milliseconds plus a label
/// for the lock overlay. Mirrors the native `FocusWindow`.
class FocusPolicyWindow {
  const FocusPolicyWindow({
    required this.startMs,
    required this.endMs,
    required this.title,
  });

  final int startMs;
  final int endMs;
  final String title;
}

/// How a blocked app is stopped natively.
enum FocusBlockStyle {
  /// Cover the app with the full-screen Flowra lock (falls back to home-bounce
  /// natively when the overlay permission is missing).
  overlay,

  /// Bounce straight to the home screen.
  home,
}

extension on FocusBlockStyle {
  String get wire => this == FocusBlockStyle.overlay ? 'overlay' : 'home';
}

/// Dart-side wrapper over the `flowra/focus_blocker` MethodChannel.
///
/// The native enforcement layer only exists on Android, so every method is gated
/// on [_supported] and wrapped in try/catch: on iOS (or if the channel is missing
/// for any reason) calls become safe no-ops / `false` rather than throwing into
/// the UI or coordinator.
class FocusBlockerService {
  FocusBlockerService({MethodChannel? channel})
      : _channel = channel ?? const MethodChannel('flowra/focus_blocker');

  final MethodChannel _channel;

  bool get _supported => defaultTargetPlatform == TargetPlatform.android;

  /// Whether the platform can enforce blocking at all (Android only).
  Future<bool> isSupported() async {
    if (!_supported) return false;
    try {
      return await _channel.invokeMethod<bool>('isSupported') ?? false;
    } catch (_) {
      return false;
    }
  }

  /// Whether our accessibility service is currently enabled in system settings.
  Future<bool> isAccessibilityEnabled() async {
    if (!_supported) return false;
    try {
      return await _channel.invokeMethod<bool>('isAccessibilityEnabled') ?? false;
    } catch (_) {
      return false;
    }
  }

  /// Opens the system Accessibility settings screen so the user can enable us.
  Future<void> openAccessibilitySettings() async {
    if (!_supported) return;
    try {
      await _channel.invokeMethod<void>('openAccessibilitySettings');
    } catch (_) {
      // Best-effort; nothing to recover.
    }
  }

  /// Whether the "display over other apps" permission is granted (or unneeded).
  Future<bool> canDrawOverlays() async {
    if (!_supported) return false;
    try {
      return await _channel.invokeMethod<bool>('canDrawOverlays') ?? false;
    } catch (_) {
      return false;
    }
  }

  /// Opens the "display over other apps" settings screen for Flowra.
  Future<void> openOverlaySettings() async {
    if (!_supported) return;
    try {
      await _channel.invokeMethod<void>('openOverlaySettings');
    } catch (_) {
      // Best-effort.
    }
  }

  /// Pushes the current enforcement policy down to the native service.
  Future<void> updatePolicy({
    required bool enabled,
    required Set<String> packages,
    required List<FocusPolicyWindow> windows,
    FocusBlockStyle blockStyle = FocusBlockStyle.overlay,
  }) async {
    if (!_supported) return;
    try {
      await _channel.invokeMethod<void>('updatePolicy', <String, dynamic>{
        'enabled': enabled,
        'packages': packages.toList(),
        'windows': windows
            .map((w) => <int>[w.startMs, w.endMs])
            .toList(growable: false),
        'titles': windows.map((w) => w.title).toList(growable: false),
        'blockStyle': blockStyle.wire,
      });
    } catch (_) {
      // Best-effort; the coordinator will resync on the next trigger.
    }
  }

  /// Clears all enforcement (e.g. on logout or when focus is turned off).
  Future<void> clearPolicy() async {
    if (!_supported) return;
    try {
      await _channel.invokeMethod<void>('clearPolicy');
    } catch (_) {
      // Best-effort.
    }
  }
}
