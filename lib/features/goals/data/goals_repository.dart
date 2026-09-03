import '../../../core/models/json.dart';
import '../../../core/network/api_client.dart';
import '../domain/goal.dart';

class GoalsRepository {
  GoalsRepository({ApiClient? client}) : _api = client ?? ApiClient.instance;

  final ApiClient _api;

  Future<List<Goal>> list(String currency) async {
    final json = await _api.get<Map<String, dynamic>>('/api/goals');
    return J
        .items(json)
        .map((g) => Goal.fromJson(g, currency))
        .toList(growable: false);
  }

  Future<void> create({
    required String name,
    required int targetAmountMinor,
    DateTime? targetDate,
  }) =>
      _api.post<Map<String, dynamic>>('/api/goals', body: {
        'name': name,
        'targetAmountMinor': targetAmountMinor,
        if (targetDate != null)
          'targetDate': targetDate.toUtc().toIso8601String(),
      });

  /// Contributions are a ledger on the server, so a mistaken entry can be
  /// reversed by contributing a negative amount rather than editing a total.
  Future<void> contribute(String id, int amountMinor, {String? note}) =>
      _api.post<Map<String, dynamic>>('/api/goals/$id/contribute', body: {
        'amountMinor': amountMinor,
        if (note != null && note.trim().isNotEmpty) 'note': note.trim(),
      });

  Future<void> remove(String id) => _api.delete<void>('/api/goals/$id');
}
