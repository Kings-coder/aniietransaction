// ignore_for_file: library_private_types_in_public_api

import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;

import '../error/exception.dart';

class _ApiResponse<T> {
  final T body;
  final int statusCode;

  _ApiResponse({required this.body, required this.statusCode});
}

class RestApiService {
  static final RestApiService _instance = RestApiService._internal();
  RestApiService._internal();

  factory RestApiService() => _instance;

  http.Client? _client;

  http.Client get _safeClient {
    _client ??= http.Client();
    return _client!;
  }

  void cancelRequest() {
    _client?.close();
    _client = null; // Reset client for future use
  }

  Future<_ApiResponse<T>> _handleResponse<T>(
    Future<http.Response> Function() request,
  ) async {
    try {
      final response = await request();
      final body = jsonDecode(response.body) as T;

      if (response.statusCode != 200 && response.statusCode != 201) {
        String message = (body is Map && body.containsKey('message'))
            ? body['message']
            : 'An Error occurred';

        throw APIException(
          message: message,
          statusCode: response.statusCode,
        );
      }

      return _ApiResponse(body: body, statusCode: response.statusCode);
    } on TimeoutException {
      throw const APIException(
        message: 'Connection Timeout, please retry',
        statusCode: 100,
      );
    } on SocketException {
      throw const APIException(
        message: 'Unstable internet connection',
        statusCode: 100,
      );
    } on APIException {
      rethrow;
    } catch (e) {
      throw APIException(
        message: e.toString(),
        statusCode: 515,
      );
    }
  }

  Future<_ApiResponse<T>> get<T>(
    String url, {
    Map<String, String>? headers,
    int timeoutSeconds = 15,
  }) async {
    return _handleResponse(
      () => _safeClient
          .get(Uri.parse(url), headers: headers)
          .timeout(Duration(seconds: timeoutSeconds)),
    );
  }

  Future<_ApiResponse<T>> post<T>(
    String url, {
    Map<String, String>? headers,
    Map<String, dynamic>? data,
    Encoding? encoding,
    int timeoutSeconds = 15,
  }) async {
    return _handleResponse(
      () => _safeClient
          .post(
            Uri.parse(url),
            headers: headers,
            body: data == null ? null : jsonEncode(data),
            encoding: encoding,
          )
          .timeout(Duration(seconds: timeoutSeconds)),
    );
  }

  Future<_ApiResponse<T>> put<T>(
    String url, {
    Map<String, String>? headers,
    Map<String, dynamic>? data,
    Encoding? encoding,
    int timeoutSeconds = 15,
  }) async {
    return _handleResponse(
      () => _safeClient
          .put(
            Uri.parse(url),
            headers: headers,
            body: data == null ? null : jsonEncode(data),
            encoding: encoding,
          )
          .timeout(Duration(seconds: timeoutSeconds)),
    );
  }

  Future<_ApiResponse<T>> patch<T>(
    String url, {
    Map<String, String>? headers,
    Map<String, dynamic>? data,
    Encoding? encoding,
    int timeoutSeconds = 15,
  }) async {
    return _handleResponse(
      () => _safeClient
          .patch(
            Uri.parse(url),
            headers: headers,
            body: data == null ? null : jsonEncode(data),
            encoding: encoding,
          )
          .timeout(Duration(seconds: timeoutSeconds)),
    );
  }

  Future<_ApiResponse<T>> delete<T>(
    String url, {
    Map<String, String>? headers,
    Map<String, dynamic>? data,
    Encoding? encoding,
    int timeoutSeconds = 15,
  }) async {
    return _handleResponse(
      () => _safeClient
          .delete(
            Uri.parse(url),
            headers: headers,
            body: data == null ? null : jsonEncode(data),
            encoding: encoding,
          )
          .timeout(Duration(seconds: timeoutSeconds)),
    );
  }
}
