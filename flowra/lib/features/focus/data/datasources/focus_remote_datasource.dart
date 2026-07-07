import 'dart:convert';
import '../../../../core/constants/endpoints.dart';
import '../../../../core/network/api_client.dart';
import '../model/focus_status_model.dart';

abstract class FocusRemoteDataSource {
  Future<FocusStatusModel> getStatus();
  Future<void> updateConfig({
    List<String>? blockedApps,
    bool? focusModeEnabled,
  });
}

class FocusRemoteDataSourceImpl implements FocusRemoteDataSource {
  final ApiClient apiClient;

  FocusRemoteDataSourceImpl({required this.apiClient});

  @override
  Future<FocusStatusModel> getStatus() async {
    final response = await apiClient.get(Endpoints.focusStatus);
    final json = (response as Map<String, dynamic>?) ?? const {};
    final status = FocusStatusModel.fromJson(json);

    // /focus/status does not echo the global toggle, so recover it from the
    // cached user object (kept in sync by updateConfig below).
    final cachedToggle = await _cachedFocusModeEnabled();
    if (cachedToggle == null) return status;
    return FocusStatusModel(
      isActive: status.isActive,
      currentItem: status.currentItem,
      blockedApps: status.blockedApps,
      focusModeEnabled: cachedToggle,
    );
  }

  @override
  Future<void> updateConfig({
    List<String>? blockedApps,
    bool? focusModeEnabled,
  }) async {
    final body = <String, dynamic>{};
    if (blockedApps != null) body['blocked_apps'] = blockedApps;
    if (focusModeEnabled != null) body['focus_mode_enabled'] = focusModeEnabled;

    await apiClient.put(Endpoints.focusConfig, body);

    // Keep the cached user in sync so the toggle survives a status refresh.
    await _updateCachedUser(
      blockedApps: blockedApps,
      focusModeEnabled: focusModeEnabled,
    );
  }

  Future<bool?> _cachedFocusModeEnabled() async {
    final userStr = await apiClient.getUser();
    if (userStr == null) return null;
    try {
      final user = json.decode(userStr) as Map<String, dynamic>;
      return user['focus_mode_enabled'] as bool?;
    } catch (_) {
      return null;
    }
  }

  Future<void> _updateCachedUser({
    List<String>? blockedApps,
    bool? focusModeEnabled,
  }) async {
    final userStr = await apiClient.getUser();
    if (userStr == null) return;
    try {
      final user = json.decode(userStr) as Map<String, dynamic>;
      if (blockedApps != null) user['blocked_apps'] = blockedApps;
      if (focusModeEnabled != null) user['focus_mode_enabled'] = focusModeEnabled;
      await apiClient.saveUser(json.encode(user));
    } catch (_) {
      // Best-effort cache update; ignore malformed cache.
    }
  }
}
