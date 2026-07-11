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

  List<SelectableApp> _presetSelectable() =>
      presetApps.map((n) => SelectableApp(name: n)).toList();
}
