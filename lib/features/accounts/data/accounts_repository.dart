import '../../../core/models/json.dart';
import '../../../core/network/api_client.dart';
import '../domain/account.dart';

class AccountsRepository {
  AccountsRepository({ApiClient? client}) : _api = client ?? ApiClient.instance;

  final ApiClient _api;

  Future<List<Account>> list(String currency) async {
    final json = await _api.get<Map<String, dynamic>>('/api/accounts');
    return J
        .items(json)
        .map((a) => Account.fromJson(a, currency))
        .toList(growable: false);
  }

  Future<void> create({
    required String name,
    required AccountType type,
    int openingBalanceMinor = 0,
    bool isDefault = false,
  }) =>
      _api.post<Map<String, dynamic>>('/api/accounts', body: {
        'name': name,
        'type': type.wire,
        'openingBalanceMinor': openingBalanceMinor,
        'isDefault': isDefault,
      });

  Future<void> rename(String id, String name) =>
      _api.patch<Map<String, dynamic>>('/api/accounts/$id', body: {'name': name});

  /// Archives rather than deletes. The API refuses while a balance remains, so
  /// the conflict message it returns is shown as-is.
  Future<void> close(String id) => _api.delete<void>('/api/accounts/$id');
}
