import 'dart:io';

import 'package:dio/dio.dart';
import 'package:injectable/injectable.dart';
import 'package:sookshicha_dhukkikenda/core/constants/app_constants.dart';
import 'package:sookshicha_dhukkikenda/core/error/exceptions.dart';
import 'package:sookshicha_dhukkikenda/core/network/network_info.dart';
import 'package:sookshicha_dhukkikenda/core/utils/logger.dart';

/// HTTP client wrapper using Dio
@lazySingleton
class ApiClient {
  ApiClient(this._networkInfo) {
    _dio = Dio(_baseOptions);
    _setupInterceptors();
  }

  final NetworkInfo _networkInfo;
  late final Dio _dio;

  static final BaseOptions _baseOptions = BaseOptions(
    baseUrl: AppConstants.baseUrl,
    connectTimeout: AppConstants.connectionTimeout,
    receiveTimeout: AppConstants.receiveTimeout,
    headers: {
      HttpHeaders.contentTypeHeader: 'application/json',
      HttpHeaders.acceptHeader: 'application/json',
    },
  );

  void _setupInterceptors() {
    _dio.interceptors.addAll([
      _LoggingInterceptor(),
      _ErrorInterceptor(_networkInfo),
    ]);
  }

  /// Set authorization header
  void setAuthToken(String token) {
    _dio.options.headers[HttpHeaders.authorizationHeader] = 'Bearer $token';
  }

  /// Remove authorization header
  void clearAuthToken() {
    _dio.options.headers.remove(HttpHeaders.authorizationHeader);
  }

  /// Add custom header
  void addHeader(String key, String value) {
    _dio.options.headers[key] = value;
  }

  /// GET request
  Future<Response<T>> get<T>(
    String path, {
    Map<String, dynamic>? queryParameters,
    Options? options,
    CancelToken? cancelToken,
  }) async {
    return _dio.get<T>(
      path,
      queryParameters: queryParameters,
      options: options,
      cancelToken: cancelToken,
    );
  }

  /// POST request
  Future<Response<T>> post<T>(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
    CancelToken? cancelToken,
  }) async {
    return _dio.post<T>(
      path,
      data: data,
      queryParameters: queryParameters,
      options: options,
      cancelToken: cancelToken,
    );
  }

  /// PUT request
  Future<Response<T>> put<T>(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
    CancelToken? cancelToken,
  }) async {
    return _dio.put<T>(
      path,
      data: data,
      queryParameters: queryParameters,
      options: options,
      cancelToken: cancelToken,
    );
  }

  /// PATCH request
  Future<Response<T>> patch<T>(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
    CancelToken? cancelToken,
  }) async {
    return _dio.patch<T>(
      path,
      data: data,
      queryParameters: queryParameters,
      options: options,
      cancelToken: cancelToken,
    );
  }

  /// DELETE request
  Future<Response<T>> delete<T>(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
    CancelToken? cancelToken,
  }) async {
    return _dio.delete<T>(
      path,
      data: data,
      queryParameters: queryParameters,
      options: options,
      cancelToken: cancelToken,
    );
  }

  /// Upload file
  Future<Response<T>> uploadFile<T>(
    String path, {
    required String filePath,
    required String fieldName,
    Map<String, dynamic>? additionalData,
    ProgressCallback? onSendProgress,
    CancelToken? cancelToken,
  }) async {
    final formData = FormData.fromMap({
      fieldName: await MultipartFile.fromFile(filePath),
      if (additionalData != null) ...additionalData,
    });

    return _dio.post<T>(
      path,
      data: formData,
      onSendProgress: onSendProgress,
      cancelToken: cancelToken,
    );
  }

  /// Download file
  Future<Response> downloadFile(
    String url,
    String savePath, {
    ProgressCallback? onReceiveProgress,
    CancelToken? cancelToken,
  }) async {
    return _dio.download(
      url,
      savePath,
      onReceiveProgress: onReceiveProgress,
      cancelToken: cancelToken,
    );
  }
}

/// Logging interceptor for debugging
class _LoggingInterceptor extends Interceptor {
  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    AppLogger.d('🌐 REQUEST[${options.method}] => ${options.uri}');
    AppLogger.d('Headers: ${options.headers}');
    if (options.data != null) {
      AppLogger.d('Body: ${options.data}');
    }
    handler.next(options);
  }

  @override
  void onResponse(Response response, ResponseInterceptorHandler handler) {
    AppLogger.d(
      '✅ RESPONSE[${response.statusCode}] => ${response.requestOptions.uri}',
    );
    handler.next(response);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    AppLogger.e(
      '❌ ERROR[${err.response?.statusCode}] => ${err.requestOptions.uri}',
    );
    AppLogger.e('Error: ${err.message}');
    handler.next(err);
  }
}

/// Error handling interceptor
class _ErrorInterceptor extends Interceptor {
  _ErrorInterceptor(this._networkInfo);

  final NetworkInfo _networkInfo;

  @override
  Future<void> onError(
    DioException err,
    ErrorInterceptorHandler handler,
  ) async {
    // Check for network connectivity first
    if (!await _networkInfo.isConnected) {
      handler.reject(
        DioException(
          requestOptions: err.requestOptions,
          error: const NetworkException(message: 'No internet connection'),
          type: DioExceptionType.connectionError,
        ),
      );
      return;
    }

    switch (err.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        handler.reject(
          DioException(
            requestOptions: err.requestOptions,
            error: const NetworkException(message: 'Connection timeout'),
            type: err.type,
          ),
        );
      case DioExceptionType.badResponse:
        final statusCode = err.response?.statusCode;
        final message = _getErrorMessage(err.response);
        handler.reject(
          DioException(
            requestOptions: err.requestOptions,
            error: ServerException(message: message, statusCode: statusCode),
            type: err.type,
          ),
        );
      case DioExceptionType.cancel:
        handler.reject(err);
      default:
        handler.reject(
          DioException(
            requestOptions: err.requestOptions,
            error: const ServerException(
              message: 'An unexpected error occurred',
            ),
            type: err.type,
          ),
        );
    }
  }

  String _getErrorMessage(Response? response) {
    if (response == null) return 'Server error';

    try {
      final data = response.data;
      if (data is Map) {
        return data['message'] as String? ??
            data['error'] as String? ??
            'Server error';
      }
    } catch (_) {}

    switch (response.statusCode) {
      case 400:
        return 'Bad request';
      case 401:
        return 'Unauthorized';
      case 403:
        return 'Forbidden';
      case 404:
        return 'Not found';
      case 500:
        return 'Internal server error';
      default:
        return 'Server error';
    }
  }
}
