import '../../../core/network/api_client.dart';
import '../domain/budget.dart';

class BudgetsRepository {
  BudgetsRepository({ApiClient? client}) : _api = client ?? ApiClient.instance;

  final ApiClient _api;

  Future<BudgetBoard> board(String currency) async {
    final json = await _api.get<Map<String, dynamic>>('/api/budgets');
    return BudgetBoard.fromJson(json, currency);
  }

  Future<void> create({
    required int amountMinor,
    String? categoryId,
    String period = 'MONTHLY',
  }) =>
      _api.post<Map<String, dynamic>>('/api/budgets', body: {
        'amountMinor': amountMinor,
        'period': period,
        if (categoryId != null) 'categoryId': categoryId,
      });

  Future<void> remove(String id) => _api.delete<void>('/api/budgets/$id');
}
