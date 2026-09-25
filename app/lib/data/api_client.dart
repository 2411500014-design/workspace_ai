import 'dart:typed_data';

import 'package:dio/dio.dart';

/// An error from the Purnara API. [code] is stable and translated in the app;
/// the backend never sends user-facing sentences.
class ApiException implements Exception {
  const ApiException(this.code, {this.status, this.detail});

  final String code;
  final int? status;
  final Map<String, dynamic>? detail;

  bool get isNetwork => code == 'network_error';

  @override
  String toString() => 'ApiException($code, status: $status)';
}

class ApiClient {
  ApiClient(this.baseUrl)
    : _dio = Dio(
        BaseOptions(
          baseUrl: '$baseUrl/v1',
          connectTimeout: const Duration(seconds: 10),
          // AI calls (brief, plan, chat) can take up to a minute.
          receiveTimeout: const Duration(seconds: 120),
          sendTimeout: const Duration(seconds: 120),
          headers: {'Accept': 'application/json'},
        ),
      );

  final String baseUrl;
  final Dio _dio;

  /// Set when Supabase sign-in is enabled; unused in local mode.
  String? accessToken;

  Future<T> _send<T>(Future<Response<dynamic>> Function(Options options) call) async {
    final options = Options(headers: {if (accessToken != null) 'Authorization': 'Bearer $accessToken'});
    try {
      final response = await call(options);
      return response.data as T;
    } on DioException catch (e) {
      throw _toApiException(e);
    }
  }

  static ApiException _toApiException(DioException e) {
    final data = e.response?.data;
    if (data is Map && data['error'] is Map) {
      final error = data['error'] as Map;
      final detail = error['detail'];
      return ApiException(
        error['code'] as String? ?? 'unknown',
        status: e.response?.statusCode,
        detail: detail is Map ? Map<String, dynamic>.from(detail) : null,
      );
    }
    switch (e.type) {
      case DioExceptionType.connectionError:
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.receiveTimeout:
      case DioExceptionType.sendTimeout:
        return const ApiException('network_error');
      default:
        return ApiException(e.response?.statusCode == 404 ? 'not_found' : 'unknown', status: e.response?.statusCode);
    }
  }

  Future<T> get<T>(String path, {Map<String, dynamic>? query}) => _send((o) => _dio.get<dynamic>(path, queryParameters: query, options: o));

  Future<T> post<T>(String path, {Object? data}) => _send((o) => _dio.post<dynamic>(path, data: data ?? const {}, options: o));

  Future<T> put<T>(String path, {Object? data}) => _send((o) => _dio.put<dynamic>(path, data: data, options: o));

  Future<T> patch<T>(String path, {Object? data}) => _send((o) => _dio.patch<dynamic>(path, data: data, options: o));

  Future<void> delete(String path) => _send<dynamic>((o) => _dio.delete<dynamic>(path, options: o));

  Future<T> upload<T>(String path, {required String fileName, required Uint8List bytes}) {
    final form = FormData.fromMap({'file': MultipartFile.fromBytes(bytes, filename: fileName)});
    return _send((o) => _dio.post<dynamic>(path, data: form, options: o));
  }
}
