import '../../../core/cache/json_cache.dart';
import '../../../core/network/api_client.dart';
import '../../../core/network/api_exception.dart';
import '../domain/home_summary.dart';
import 'dashboard_mapper.dart';

/// What the dashboard renders, and where it came from.
class DashboardSnapshot {
  const DashboardSnapshot({
    required this.summary,
    required this.fromCache,
    this.cachedAt,
  });

  final HomeSummary summary;

  /// True when the network failed and this is the last good payload.
  final bool fromCache;
  final DateTime? cachedAt;
}

class DashboardRepository {
  DashboardRepository({ApiClient? client, JsonCache? cache})
      : _api = client ?? ApiClient.instance,
        _cache = cache ?? JsonCache.instance;

  static const _cacheKey = 'dashboard';

  final ApiClient _api;
  final JsonCache _cache;

  /// Network first, cache as a fallback.
  ///
  /// A finance dashboard showing stale figures without saying so is worse than
  /// one that admits it is offline, so the snapshot carries that fact rather
  /// than hiding it.
  Future<DashboardSnapshot> fetch() async {
    try {
      final json =
          await _api.get<Map<String, dynamic>>('/api/analytics/dashboard');
      await _cache.write(_cacheKey, json);
      return DashboardSnapshot(
        summary: DashboardMapper.fromJson(json),
        fromCache: false,
      );
    } on ApiException catch (e) {
      // Only fall back for transport failures. A 401 or a 500 is a real error
      // and must not be papered over with month-old numbers.
      if (!e.isOffline) rethrow;

      final cached = await _cache.read(_cacheKey);
      if (cached == null) rethrow;

      return DashboardSnapshot(
        summary: DashboardMapper.fromJson(cached.value),
        fromCache: true,
        cachedAt: cached.savedAt,
      );
    }
  }
}
