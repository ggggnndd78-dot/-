import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ghiyarak/core/config/app_config.dart';
import 'package:ghiyarak/core/network/api_exception.dart';
import 'package:ghiyarak/core/network/auth_interceptor.dart';
import 'package:ghiyarak/core/network/auth_session_events.dart';
import 'package:ghiyarak/core/storage/local_storage_service.dart';
import 'package:ghiyarak/core/storage/secure_storage_service.dart';

final apiClientProvider = Provider<ApiClient>((ref) {
  final secureStorage = ref.watch(secureStorageServiceProvider);
  final localStorage = ref.watch(localStorageServiceProvider);
  return ApiClient(
    secureStorage,
    localStorage,
    onInvalidToken: () async {
      ref.read(authSessionInvalidationProvider.notifier).state++;
    },
  );
});

class ApiClient {
  final Dio dio;

  ApiClient(
    SecureStorageService secureStorage,
    LocalStorageService localStorage, {
    Future<void> Function()? onInvalidToken,
  }) : dio = Dio(
          BaseOptions(
            baseUrl: AppConfig.baseUrl,
            connectTimeout: const Duration(seconds: 20),
            receiveTimeout: const Duration(seconds: 20),
            sendTimeout: const Duration(seconds: 20),
            headers: {
              'Accept': 'application/json',
              'Content-Type': 'application/json',
              'X-Locale': AppConfig.locale.languageCode,
              'Accept-Language': AppConfig.locale.languageCode,
            },
          ),
        ) {
    if (kDebugMode) {
      debugPrint('[Ghiyarak][API] baseUrl=${AppConfig.baseUrl}');
    }
    dio.interceptors.add(AuthInterceptor(secureStorage, localStorage,
        onInvalidToken: onInvalidToken));
  }

  Future<Response<dynamic>> get(
    String path, {
    Map<String, dynamic>? queryParameters,
  }) async {
    try {
      return await dio.get(path, queryParameters: queryParameters);
    } on DioException catch (e) {
      throw _toApiException(e);
    }
  }

  Future<Response<dynamic>> post(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
  }) async {
    try {
      return await dio.post(path, data: data, queryParameters: queryParameters);
    } on DioException catch (e) {
      throw _toApiException(e);
    }
  }

  Future<Response<dynamic>> put(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
  }) async {
    try {
      return await dio.put(path, data: data, queryParameters: queryParameters);
    } on DioException catch (e) {
      throw _toApiException(e);
    }
  }

  Future<Response<dynamic>> patch(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
  }) async {
    try {
      return await dio.patch(path,
          data: data, queryParameters: queryParameters);
    } on DioException catch (e) {
      throw _toApiException(e);
    }
  }

  Future<Response<dynamic>> delete(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
  }) async {
    try {
      return await dio.delete(path,
          data: data, queryParameters: queryParameters);
    } on DioException catch (e) {
      throw _toApiException(e);
    }
  }

  Future<Response<dynamic>> uploadMultipart(
    String path, {
    required FormData data,
    Map<String, dynamic>? queryParameters,
  }) async {
    try {
      return await dio.post(
        path,
        data: data,
        queryParameters: queryParameters,
        options: Options(contentType: 'multipart/form-data'),
      );
    } on DioException catch (e) {
      throw _toApiException(e);
    }
  }

  ApiException _toApiException(DioException e) {
    final responseData = e.response?.data;
    final responseMessage = responseData is Map<String, dynamic>
        ? responseData['message']?.toString()
        : null;
    if (kDebugMode) {
      debugPrint(
          '[Ghiyarak][API][ERROR] ${e.requestOptions.method} ${e.requestOptions.uri} status=${e.response?.statusCode} message=${responseMessage ?? e.message}');
    }
    return ApiException(
      message: responseMessage ?? e.message ?? 'common.error.unexpected',
      statusCode: e.response?.statusCode,
    );
  }
}
