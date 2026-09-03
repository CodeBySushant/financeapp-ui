import '../../../core/models/json.dart';
import '../../../core/network/api_client.dart';
import '../domain/transaction.dart';

/// Filters mirroring the `listSchema` in `transactions.routes.ts`.
class TxFilters {
  const TxFilters({this.type, this.search, this.accountId, this.categoryId});

  final TxType? type;
  final String? search;
  final String? accountId;
  final String? categoryId;

  TxFilters copyWith({
    Object? type = _unset,
    Object? search = _unset,
    Object? accountId = _unset,
    Object? categoryId = _unset,
  }) =>
      TxFilters(
        type: identical(type, _unset) ? this.type : type as TxType?,
        search: identical(search, _unset) ? this.search : search as String?,
        accountId:
            identical(accountId, _unset) ? this.accountId : accountId as String?,
        categoryId: identical(categoryId, _unset)
            ? this.categoryId
            : categoryId as String?,
      );

  static const _unset = Object();

  Map<String, dynamic> toQuery() => {
        if (type != null) 'type': type!.wire,
        if (search != null && search!.trim().isNotEmpty) 'search': search!.trim(),
        if (accountId != null) 'accountId': accountId,
        if (categoryId != null) 'categoryId': categoryId,
      };
}

class TransactionsRepository {
  TransactionsRepository({ApiClient? client})
      : _api = client ?? ApiClient.instance;

  final ApiClient _api;

  Future<TransactionPage> list({
    required String currency,
    TxFilters filters = const TxFilters(),
    String? cursor,
    int limit = 30,
  }) async {
    final json = await _api.get<Map<String, dynamic>>(
      '/api/transactions',
      query: {
        ...filters.toQuery(),
        if (cursor != null) 'cursor': cursor,
        'limit': limit,
      },
    );

    return TransactionPage(
      items: J
          .items(json)
          .map((t) => Transaction.fromJson(t, currency))
          .toList(growable: false),
      nextCursor: json['nextCursor'] as String?,
    );
  }

  Future<Transaction> create({
    required String currency,
    required TxType type,
    required String accountId,
    required int amountMinor,
    required DateTime transactionDate,
    String? toAccountId,
    String? categoryId,
    String? merchant,
    String? note,
  }) async {
    final data = await _api.post<Map<String, dynamic>>(
      '/api/transactions',
      body: {
        'type': type.wire,
        'accountId': accountId,
        'amountMinor': amountMinor,
        'transactionDate': transactionDate.toUtc().toIso8601String(),
        if (toAccountId != null) 'toAccountId': toAccountId,
        if (categoryId != null) 'categoryId': categoryId,
        if (merchant != null && merchant.trim().isNotEmpty)
          'merchant': merchant.trim(),
        if (note != null && note.trim().isNotEmpty) 'note': note.trim(),
        // Idempotency. If the request is retried after a dropped connection the
        // server returns the original row rather than writing a second expense.
        'clientRef': J.uuidV4(),
      },
    );
    return Transaction.fromJson(data, currency);
  }

  Future<Transaction> update({
    required String id,
    required String currency,
    int? amountMinor,
    String? merchant,
    String? note,
    String? categoryId,
    DateTime? transactionDate,
  }) async {
    final data = await _api.patch<Map<String, dynamic>>(
      '/api/transactions/$id',
      body: {
        if (amountMinor != null) 'amountMinor': amountMinor,
        if (merchant != null) 'merchant': merchant,
        if (note != null) 'note': note,
        if (categoryId != null) 'categoryId': categoryId,
        if (transactionDate != null)
          'transactionDate': transactionDate.toUtc().toIso8601String(),
      },
    );
    return Transaction.fromJson(data, currency);
  }

  Future<void> remove(String id) => _api.delete<void>('/api/transactions/$id');
}
