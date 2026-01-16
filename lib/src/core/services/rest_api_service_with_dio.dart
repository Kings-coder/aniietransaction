// ignore_for_file: library_private_types_in_public_api

import 'dart:async';
import 'dart:convert';

import 'package:dio/dio.dart';

import '../error/exception.dart';

class _ApiResponse<T> {
  final T body;
  final int statusCode;
  _ApiResponse({required this.body, required this.statusCode});
}

class RestApiService {
  final Dio _dio;
  static final RestApiService _instance = RestApiService._initialize(Dio());

  RestApiService._initialize(this._dio) {
    _dio.options.connectTimeout = const Duration(seconds: 15);
    _dio.options.receiveTimeout = const Duration(seconds: 15);
  }

  factory RestApiService() => _instance;

  void cancelRequests() {
    _dio.close();
  }

  Future<_ApiResponse<T>> _handleResponse<T>(
    Future<Response> Function() request,
  ) async {
    try {
      final response = await request();
      final body = response.data as T;

      if (response.statusCode != 200 && response.statusCode != 201) {
        String message = 'An Error Occurred';
        if (body is Map<String, dynamic> && body.containsKey('message')) {
          message = body['message'];
        }
        throw APIException(
          message: message,
          statusCode: response.statusCode ?? 500,
        );
      }
      return _ApiResponse(body: body, statusCode: response.statusCode!);
    } on DioException catch (e) {
      throw APIException(
        message: e.message ?? 'Unstable internet connection',
        statusCode: e.response?.statusCode ?? 100,
      );
    } catch (e) {
      throw APIException(message: e.toString(), statusCode: 500);
    }
  }

  Future<_ApiResponse<T>> get<T>(
    String url, {
    Map<String, dynamic>? headers,
  }) async {
    return _handleResponse(
        () => _dio.get(url, options: Options(headers: headers)));
  }

  Future<_ApiResponse<T>> post<T>(
    String url, {
    Map<String, dynamic>? headers,
    Map<String, dynamic>? data,
  }) async {
    return _handleResponse(() => _dio.post(url,
        data: jsonEncode(data), options: Options(headers: headers)));
  }

  Future<_ApiResponse<T>> put<T>(
    String url, {
    Map<String, dynamic>? headers,
    Map<String, dynamic>? data,
  }) async {
    return _handleResponse(() => _dio.put(url,
        data: jsonEncode(data), options: Options(headers: headers)));
  }

  Future<_ApiResponse<T>> delete<T>(
    String url, {
    Map<String, dynamic>? headers,
  }) async {
    return _handleResponse(
        () => _dio.delete(url, options: Options(headers: headers)));
  }

  Future<_ApiResponse<T>> patch<T>(
    String url, {
    Map<String, dynamic>? headers,
    Map<String, dynamic>? data,
  }) async {
    return _handleResponse(() => _dio.patch(url,
        data: jsonEncode(data), options: Options(headers: headers)));
  }
}
