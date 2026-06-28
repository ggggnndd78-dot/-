import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:ghiyarak/core/config/api_endpoints.dart';
import 'package:ghiyarak/core/config/app_config.dart';
import 'package:ghiyarak/core/storage/local_storage_service.dart';
import 'package:ghiyarak/core/storage/secure_storage_service.dart';

class AuthInterceptor extends Interceptor {
  static const _retryKey = 'auth_retry_once';
  static const _localeKey = 'normalized_locale';

  final SecureStorageService secureStorageService;
  final LocalStorageService localStorageService;
  final Future<void> Function()? onInvalidToken;
  Future<bool>? _refreshFuture;

  AuthInterceptor(
    this.secureStorageService,
    this.localStorageService, {
    this.onInvalidToken,
  });

  @override
  Future<void> onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    final locale = await localStorageService.getLocaleCode();
    final normalizedLocale = locale == 'en' ? 'en' : 'ar';
    options.extra[_localeKey] = normalizedLocale;
    options.headers['Accept-Language'] = normalizedLocale;
    options.headers['X-Locale'] = normalizedLocale;

    final token = await secureStorageService.getAccessToken();

    if (token != null && token.isNotEmpty) {
      options.headers['Authorization'] = 'Bearer $token';
      options.headers.remove('X-Guest-Token');
      options.headers.remove('X-Guest-Session-Id');
    } else if (_shouldAttachGuestHeaders(options)) {
      final guestToken = await localStorageService.getGuestToken();
      final guestSessionId = await localStorageService.getGuestSessionId();
      if (guestToken.isNotEmpty) {
        options.headers['X-Guest-Token'] = guestToken;
      }
      if (guestSessionId.isNotEmpty) {
        options.headers['X-Guest-Session-Id'] = guestSessionId;
      }
    } else {
      options.headers.remove('X-Guest-Token');
      options.headers.remove('X-Guest-Session-Id');
    }

    handler.next(options);
  }

  @override
  Future<void> onError(
    DioException err,
    ErrorInterceptorHandler handler,
  ) async {
    final statusCode = err.response?.statusCode;
    final authorizationHeader =
        err.requestOptions.headers['Authorization']?.toString() ?? '';
    final hadBearerToken =
        authorizationHeader.toLowerCase().startsWith('bearer ');

    if (statusCode == 403) {
      handler.next(err);
      return;
    }

    if (_shouldAttemptRefresh(err, hadBearerToken)) {
      final locale = err.requestOptions.extra[_localeKey]?.toString();
      final refreshed = await _refreshAccessToken(locale);
      if (refreshed) {
        try {
          final response = await _retryRequest(err.requestOptions, locale);
          handler.resolve(response);
          return;
        } on DioException catch (retryError) {
          handler.next(retryError);
          return;
        }
      }
      await _clearSession();
    } else if (statusCode == 401 &&
        hadBearerToken &&
        (_isRefreshRequest(err.requestOptions) ||
            err.requestOptions.extra[_retryKey] == true)) {
      await _clearSession();
    }

    handler.next(err);
  }

  bool _shouldAttachGuestHeaders(RequestOptions options) {
    return options.extra['attachGuestSessionHeaders'] == true;
  }

  bool _shouldAttemptRefresh(DioException err, bool hadBearerToken) {
    return err.response?.statusCode == 401 &&
        hadBearerToken &&
        !_isRefreshRequest(err.requestOptions) &&
        err.requestOptions.extra[_retryKey] != true;
  }

  bool _isRefreshRequest(RequestOptions options) {
    return _normalizedPath(options.path) == ApiEndpoints.refreshToken;
  }

  String _normalizedPath(String path) {
    if (path.startsWith('http://') || path.startsWith('https://')) {
      return Uri.parse(path).path;
    }
    return path;
  }

  Future<bool> _refreshAccessToken(String? locale) async {
    final activeRefresh = _refreshFuture;
    if (activeRefresh != null) return activeRefresh;

    final future = _performRefresh(locale);
    _refreshFuture = future;
    try {
      return await future;
    } finally {
      if (identical(_refreshFuture, future)) {
        _refreshFuture = null;
      }
    }
  }

  Future<bool> _performRefresh(String? locale) async {
    final refreshToken = await secureStorageService.getRefreshToken();
    if (refreshToken == null || refreshToken.isEmpty) return false;

    final normalizedLocale = locale == 'en' ? 'en' : 'ar';
    final dio = Dio(
      BaseOptions(
        baseUrl: AppConfig.baseUrl,
        connectTimeout: const Duration(seconds: 20),
        receiveTimeout: const Duration(seconds: 20),
        sendTimeout: const Duration(seconds: 20),
        headers: {
          'Accept': 'application/json',
          'Content-Type': 'application/json',
          'Accept-Language': normalizedLocale,
          'X-Locale': normalizedLocale,
        },
      ),
    );

    try {
      final response = await dio.post(
        ApiEndpoints.refreshToken,
        data: {'refreshToken': refreshToken},
      );
      final rawData = response.data is Map ? response.data['data'] : null;
      final data = rawData is Map
          ? Map<String, dynamic>.from(rawData)
          : const <String, dynamic>{};
      final accessToken = data['access_token']?.toString() ?? '';
      final nextRefreshToken = data['refresh_token']?.toString() ?? '';
      final deviceToken = data['device_token']?.toString() ?? '';

      if (accessToken.isEmpty) return false;

      await secureStorageService.saveAccessToken(accessToken);
      if (nextRefreshToken.isNotEmpty) {
        await secureStorageService.saveRefreshToken(nextRefreshToken);
      }
      if (deviceToken.isNotEmpty) {
        await secureStorageService.saveTrustedDeviceToken(deviceToken);
      }
      await localStorageService.clearGuestSession();

      if (kDebugMode) {
        debugPrint('[Ghiyarak][Auth] Access token refreshed successfully.');
      }
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<Response<dynamic>> _retryRequest(
    RequestOptions requestOptions,
    String? locale,
  ) async {
    final accessToken = await secureStorageService.getAccessToken();
    final normalizedLocale = locale == 'en' ? 'en' : 'ar';
    final headers = Map<String, dynamic>.from(requestOptions.headers);
    headers['Accept-Language'] = normalizedLocale;
    headers['X-Locale'] = normalizedLocale;
    headers.remove('X-Guest-Token');
    headers.remove('X-Guest-Session-Id');
    if ((accessToken ?? '').isNotEmpty) {
      headers['Authorization'] = 'Bearer $accessToken';
    }

    final dio = Dio(
      BaseOptions(
        baseUrl: AppConfig.baseUrl,
        connectTimeout: const Duration(seconds: 20),
        receiveTimeout: const Duration(seconds: 20),
        sendTimeout: const Duration(seconds: 20),
      ),
    );

    return dio.request<dynamic>(
      requestOptions.path,
      data: requestOptions.data,
      queryParameters: requestOptions.queryParameters,
      cancelToken: requestOptions.cancelToken,
      options: Options(
        method: requestOptions.method,
        headers: headers,
        responseType: requestOptions.responseType,
        contentType: requestOptions.contentType,
        receiveDataWhenStatusError: requestOptions.receiveDataWhenStatusError,
        followRedirects: requestOptions.followRedirects,
        validateStatus: requestOptions.validateStatus,
        sendTimeout: requestOptions.sendTimeout,
        receiveTimeout: requestOptions.receiveTimeout,
        extra: <String, dynamic>{
          ...requestOptions.extra,
          _retryKey: true,
          _localeKey: normalizedLocale,
        },
      ),
    );
  }

  Future<void> _clearSession() async {
    if (kDebugMode) {
      debugPrint(
        '[Ghiyarak][Auth] Session invalid or refresh failed. Clearing local session.',
      );
    }
    await secureStorageService.clearTokens();
    await localStorageService.clearSessionData();
    await onInvalidToken?.call();
  }
}
