import 'dart:io';
import 'dart:typed_data';

import 'package:installed_apps/app_info.dart';
import 'package:installed_apps/installed_apps.dart';

/// A device app the user can choose to block. [packageName] is empty for
/// preset / custom entries that don't map to a real installed package.
class SelectableApp {
  final String name;
  final String packageName;
  final Uint8List? icon;

  const SelectableApp({
    required this.name,
    this.packageName = '',
    this.icon,
  });
}

/// Provides the list of apps shown in the block picker.
///
/// On Android we enumerate the user's real launchable apps. On iOS (and if the
/// Android query returns nothing) we fall back to a curated preset of commonly
/// blocked apps, since iOS sandboxing forbids listing installed apps.
class InstalledAppsService {
  const InstalledAppsService();

  /// Process-lifetime cache of lower-cased app name → package id, built lazily.
  /// Apps installed/removed after first use won't appear until the next launch —
  /// an accepted trade-off for avoiding a full enumeration on every policy sync.
  static Map<String, String>? _packageByName;

  /// Curated fallback list of frequently-distracting apps.
  static const List<String> presetApps = [
    'Instagram',
    'TikTok',
    'YouTube',
    'Facebook',
    'X',
    'Reddit',
    'Snapchat',
    'WhatsApp',
    'Netflix',
    'Twitch',
    'Discord',
    'Telegram',
    'Pinterest',
    'LinkedIn',
    'Spotify',
  ];

  Future<List<SelectableApp>> getSelectableApps() async {
    if (Platform.isAndroid) {
      try {
        final List<AppInfo> apps = await InstalledApps.getInstalledApps(
          excludeSystemApps: true,
          excludeNonLaunchableApps: true,
          withIcon: true,
        );
        if (apps.isNotEmpty) {
          return apps
              .map((a) => SelectableApp(
                    name: a.name,
                    packageName: a.packageName,
                    icon: a.icon,
                  ))
              .toList();
        }
      } catch (_) {
        // Fall through to the preset list on any platform-channel failure.
      }
    }
    return _presetSelectable();
  }

  /// Resolves display [names] (as stored in `FocusStatus.blockedApps`) to the
  /// installed package ids the native blocker enforces on.
  ///
  /// Android-only; returns an empty set elsewhere. Names with no matching
  /// installed app (uninstalled presets, custom entries) are silently dropped —
  /// they simply can't be enforced.
  Future<Set<String>> resolvePackages(List<String> names) async {
    if (!Platform.isAndroid || names.isEmpty) return <String>{};
    final map = await _ensurePackageMap();
    final result = <String>{};
    for (final name in names) {
      final pkg = map[name.toLowerCase().trim()];
      if (pkg != null && pkg.isNotEmpty) result.add(pkg);
    }
    return result;
  }

  Future<Map<String, String>> _ensurePackageMap() async {
    final cached = _packageByName;
    if (cached != null) return cached;

    final map = <String, String>{};
    try {
      // withIcon:false — we only need the name→package mapping here, so skip the
      // expensive icon decoding the picker needs.
      final List<AppInfo> apps = await InstalledApps.getInstalledApps(
        excludeSystemApps: true,
        excludeNonLaunchableApps: true,
        withIcon: false,
      );
      for (final a in apps) {
        if (a.packageName.isNotEmpty) {
          map[a.name.toLowerCase().trim()] = a.packageName;
        }
      }
    } catch (_) {
      // Leave the map empty; nothing will be resolvable this run.
    }
    _packageByName = map;
    return map;
  }

  List<SelectableApp> _presetSelectable() =>
      presetApps.map((n) => SelectableApp(name: n)).toList();
}
