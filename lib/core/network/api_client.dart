import 'dart:async';

import 'package:dio/dio.dart';

import 'api_config.dart';
import 'api_exception.dart';
import 'token_store.dart';

/// Marks a request that must not carry a bearer token and must not be retried
/// after a refresh — sign-in, sign-up and the refresh call itself.
const kSkipAuth = 'skipAuth';

/// The single HTTP entry point.
///
/// Every response is unwrapped from the API's `{success, data}` envelope here,
/// so no repository ever has to know the envelope exists.
class ApiClient {
  ApiClient._() {
    _dio = Dio(_options());
    // A second, interceptor-free client for the refresh call. Refreshing
    // through the same instance that retries on 401 is how you get an
    // infinite loop the first time a refresh token expires.
    _bare = Dio(_options());
    _dio.interceptors.add(_AuthInterceptor(this));
  }

  static final ApiClient instance = ApiClient._();

  late final Dio _dio;
  late final Dio _bare;

  final _tokens = TokenStore.instance;

  /// Fires when the session cannot be recovered — a revoked token family, or a
  /// refresh token past its 30 days. The app listens and returns to sign-in.
  final _expired = StreamController<void>.broadcast();
  Stream<void> get onSessionExpired => _expired.stream;

  Future<void>? _refreshing;

  BaseOptions _options() => BaseOptions(
        baseUrl: ApiConfig.baseUrl,
        connectTimeout: ApiConfig.connectTimeout,
        receiveTimeout: ApiConfig.receiveTimeout,
        contentType: Headers.jsonContentType,
        responseType: ResponseType.json,
        // Let the interceptor see 4xx bodies instead of Dio throwing first.
        validateStatus: (s) => s != null && s < 500,
      );

  Future<T> get<T>(String path, {Map<String, dynamic>? query}) =>
      _send<T>(() => _dio.get(path, queryParameters: query));

  Future<T> post<T>(
    String path, {
    Object? body,
    bool skipAuth = false,
  }) =>
      _send<T>(() => _dio.post(
            path,
            data: body,
            options: Options(extra: {kSkipAuth: skipAuth}),
          ));

  Future<T> patch<T>(String path, {Object? body}) =>
      _send<T>(() => _dio.patch(path, data: body));

  Future<T> delete<T>(String path, {Object? body}) =>
      _send<T>(() => _dio.delete(path, data: body));

  Future<T> _send<T>(Future<Response<dynamic>> Function() run) async {
    try {
      final res = await run();
      return _unwrap<T>(res);
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }

  T _unwrap<T>(Response<dynamic> res) {
    final status = res.statusCode ?? 0;
    final body = res.data;

    if (status >= 400) {
      if (body is Map && body['error'] is Map) {
        final err = body['error'] as Map;
        throw ApiException(
          ApiErrorCode.parse(err['code'] as String?),
          (err['message'] as String?) ?? 'Something went wrong.',
          details: err['details'],
          status: status,
        );
      }
      throw ApiException(
        ApiErrorCode.unknown,
        'Something went wrong. Please try again.',
        status: status,
      );
    }

    // 204 No Content — logout returns this.
    if (status == 204 || body == null || body == '') {
      if (null is T) return null as T;
      throw const ApiException(
        ApiErrorCode.malformed,
        'The server returned an empty response.',
      );
    }

    if (body is Map && body.containsKey('success')) {
      final data = body['data'];
      if (data is T) return data;
      if (null is T) return data as T;
      throw const ApiException(
        ApiErrorCode.malformed,
        'The server returned an unexpected shape.',
      );
    }

    throw const ApiException(
      ApiErrorCode.malformed,
      'The server returned an unexpected shape.',
    );
  }

  /// Exchanges the refresh token. Single-flight: several requests failing with
  /// 401 at once must produce one refresh, not one each — the API revokes the
  /// whole token family when it sees a rotated token replayed, so a burst of
  /// parallel refreshes would sign the user out.
  Future<bool> refreshSession() {
    final inFlight = _refreshing;
    if (inFlight != null) {
      return inFlight.then((_) => _tokens.cachedAccessToken != null);
    }

    final future = _doRefresh();
    _refreshing = future;
    return future.whenComplete(() => _refreshing = null).then(
          (_) => _tokens.cachedAccessToken != null,
        );
  }

  Future<void> _doRefresh() async {
    final refresh = await _tokens.readRefresh();
    if (refresh == null || refresh.isEmpty) {
      await _forceSignOut();
      return;
    }

    try {
      final res = await _bare.post<dynamic>(
        '/api/auth/refresh',
        data: {'refreshToken': refresh},
      );
      final body = res.data;
      if ((res.statusCode ?? 0) >= 400 ||
          body is! Map ||
          body['data'] is! Map) {
        await _forceSignOut();
        return;
      }
      final data = body['data'] as Map;
      final access = data['accessToken'] as String?;
      final next = data['refreshToken'] as String?;
      if (access == null || next == null) {
        await _forceSignOut();
        return;
      }
      await _tokens.saveTokens(access: access, refresh: next);
      final user = data['user'];
      if (user is Map<String, dynamic>) await _tokens.saveUser(user);
    } catch (_) {
      await _forceSignOut();
    }
  }

  Future<void> _forceSignOut() async {
    await _tokens.clear();
    if (!_expired.isClosed) _expired.add(null);
  }

  Future<void> signOutLocally() => _forceSignOut();
}

class _AuthInterceptor extends Interceptor {
  _AuthInterceptor(this._client);

  final ApiClient _client;

  @override
  Future<void> onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    if (options.extra[kSkipAuth] != true) {
      final token = await TokenStore.instance.readAccess();
      if (token != null) {
        options.headers['Authorization'] = 'Bearer $token';
      }
    }
    handler.next(options);
  }

  @override
  Future<void> onResponse(
    Response<dynamic> response,
    ResponseInterceptorHandler handler,
  ) async {
    final options = response.requestOptions;
    final is401 = response.statusCode == 401;
    final skip = options.extra[kSkipAuth] == true;
    final retried = options.extra['retried'] == true;

    // validateStatus lets 401 arrive here rather than as an error, so the
    // retry lives in onResponse.
    if (!is401 || skip || retried) {
      handler.next(response);
      return;
    }

    final ok = await _client.refreshSession();
    if (!ok) {
      handler.next(response);
      return;
    }

    try {
      final token = await TokenStore.instance.readAccess();
      final retry = await Dio(BaseOptions(
        baseUrl: options.baseUrl,
        connectTimeout: ApiConfig.connectTimeout,
        receiveTimeout: ApiConfig.receiveTimeout,
        validateStatus: (s) => s != null && s < 500,
      )).fetch<dynamic>(
        options
          ..headers['Authorization'] = 'Bearer $token'
          ..extra['retried'] = true,
      );
      handler.resolve(retry);
    } catch (_) {
      handler.next(response);
    }
  }
}
