import 'package:dio/dio.dart';

/// The error codes the API can return, plus two the client raises itself.
///
/// Mirrors `ErrorCode` in `src/lib/http.ts`. Keeping the same names means a new
/// server-side code shows up here as `unknown` rather than as a crash.
enum ApiErrorCode {
  validation,
  unauthenticated,
  forbidden,
  notFound,
  conflict,
  rateLimited,
  aiUnavailable,
  premiumRequired,
  internal,

  /// The request never reached the server.
  network,

  /// A response arrived but did not match the agreed envelope.
  malformed,

  unknown;

  static ApiErrorCode parse(String? raw) => switch (raw) {
        'VALIDATION_ERROR' => ApiErrorCode.validation,
        'UNAUTHENTICATED' => ApiErrorCode.unauthenticated,
        'FORBIDDEN' => ApiErrorCode.forbidden,
        'NOT_FOUND' => ApiErrorCode.notFound,
        'CONFLICT' => ApiErrorCode.conflict,
        'RATE_LIMITED' => ApiErrorCode.rateLimited,
        'AI_UNAVAILABLE' => ApiErrorCode.aiUnavailable,
        'PREMIUM_REQUIRED' => ApiErrorCode.premiumRequired,
        'INTERNAL_ERROR' => ApiErrorCode.internal,
        _ => ApiErrorCode.unknown,
      };
}

/// A failure the UI can render.
///
/// The API already writes user-facing messages ("That email and password do not
/// match"), so those are shown verbatim. Only transport failures and 500s get a
/// message written here, because those carry driver detail that must not reach
/// a user.
class ApiException implements Exception {
  const ApiException(this.code, this.message, {this.details, this.status});

  final ApiErrorCode code;
  final String message;
  final Object? details;
  final int? status;

  bool get isAuthFailure => code == ApiErrorCode.unauthenticated;
  bool get isOffline => code == ApiErrorCode.network;

  /// Field-level validation errors, keyed by field name, when the server sent
  /// them. Used to mark the offending input rather than only showing a banner.
  Map<String, String> get fieldErrors {
    final d = details;
    if (d is! List) return const {};
    final out = <String, String>{};
    for (final item in d) {
      if (item is Map &&
          item['field'] is String &&
          item['message'] is String) {
        out[item['field'] as String] = item['message'] as String;
      }
    }
    return out;
  }

  factory ApiException.fromDio(DioException e) {
    switch (e.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        return const ApiException(
          ApiErrorCode.network,
          'The server took too long to answer. Check your connection and try again.',
        );
      case DioExceptionType.connectionError:
      case DioExceptionType.unknown:
        return const ApiException(
          ApiErrorCode.network,
          'Could not reach Fintrak. Check your connection and try again.',
        );
      case DioExceptionType.cancel:
        return const ApiException(ApiErrorCode.unknown, 'Request cancelled.');
      case DioExceptionType.badCertificate:
        return const ApiException(
          ApiErrorCode.network,
          'The connection could not be verified.',
        );
      case DioExceptionType.badResponse:
        break;
    }

    final response = e.response;
    final body = response?.data;
    if (body is Map && body['error'] is Map) {
      final err = body['error'] as Map;
      return ApiException(
        ApiErrorCode.parse(err['code'] as String?),
        (err['message'] as String?) ?? 'Something went wrong.',
        details: err['details'],
        status: response?.statusCode,
      );
    }

    return ApiException(
      ApiErrorCode.unknown,
      'Something went wrong. Please try again.',
      status: response?.statusCode,
    );
  }
}
