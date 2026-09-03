import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_exception.dart';
import '../../../core/session/currency_provider.dart';
import '../data/transactions_repository.dart';
import '../domain/transaction.dart';

final transactionsRepositoryProvider =
    Provider<TransactionsRepository>((ref) => TransactionsRepository());

/// The paginated Activity list.
class TxListState {
  const TxListState({
    this.items = const [],
    this.filters = const TxFilters(),
    this.cursor,
    this.loading = true,
    this.loadingMore = false,
    this.error,
  });

  final List<Transaction> items;
  final TxFilters filters;
  final String? cursor;
  final bool loading;
  final bool loadingMore;
  final String? error;

  bool get hasMore => cursor != null;
  bool get isEmpty => !loading && error == null && items.isEmpty;

  TxListState copyWith({
    List<Transaction>? items,
    TxFilters? filters,
    Object? cursor = _unset,
    bool? loading,
    bool? loadingMore,
    Object? error = _unset,
  }) =>
      TxListState(
        items: items ?? this.items,
        filters: filters ?? this.filters,
        cursor: identical(cursor, _unset) ? this.cursor : cursor as String?,
        loading: loading ?? this.loading,
        loadingMore: loadingMore ?? this.loadingMore,
        error: identical(error, _unset) ? this.error : error as String?,
      );

  static const _unset = Object();
}

class TransactionsController extends StateNotifier<TxListState> {
  TransactionsController(this._repo, this._currency)
      : super(const TxListState()) {
    refresh();
  }

  final TransactionsRepository _repo;
  final String _currency;

  Future<void> refresh() async {
    state = state.copyWith(loading: true, error: null);
    try {
      final page = await _repo.list(
        currency: _currency,
        filters: state.filters,
      );
      state = state.copyWith(
        items: page.items,
        cursor: page.nextCursor,
        loading: false,
      );
    } on ApiException catch (e) {
      state = state.copyWith(loading: false, error: e.message);
    }
  }

  /// Cursor pagination, not offset. Adding an expense while scrolling would
  /// otherwise shift the window and show a row twice or skip one.
  Future<void> loadMore() async {
    if (state.loadingMore || !state.hasMore || state.loading) return;
    state = state.copyWith(loadingMore: true);
    try {
      final page = await _repo.list(
        currency: _currency,
        filters: state.filters,
        cursor: state.cursor,
      );
      state = state.copyWith(
        items: [...state.items, ...page.items],
        cursor: page.nextCursor,
        loadingMore: false,
      );
    } on ApiException catch (e) {
      state = state.copyWith(loadingMore: false, error: e.message);
    }
  }

  Future<void> setFilters(TxFilters filters) async {
    state = state.copyWith(filters: filters, cursor: null);
    await refresh();
  }

  /// Removes optimistically and puts the row back if the server refuses, so a
  /// failed delete never silently loses a transaction from the list.
  Future<String?> delete(Transaction tx) async {
    final previous = state.items;
    state = state.copyWith(
      items: state.items.where((t) => t.id != tx.id).toList(growable: false),
    );
    try {
      await _repo.remove(tx.id);
      return null;
    } on ApiException catch (e) {
      state = state.copyWith(items: previous);
      return e.message;
    }
  }
}

final transactionsProvider =
    StateNotifierProvider<TransactionsController, TxListState>((ref) {
  return TransactionsController(
    ref.read(transactionsRepositoryProvider),
    ref.watch(currencyProvider),
  );
});
