import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

import '../config/api_constants.dart';

/// Error raised for any failed API call. [message] is safe to show to users.
class ApiException implements Exception {
  final String message;
  final int? statusCode;

  const ApiException(this.message, {this.statusCode});

  @override
  String toString() => message;
}

/// Thin wrapper around [http.Client] that owns URL building, JSON encoding,
/// timeouts and error translation for every service.
class ApiClient {
  ApiClient({http.Client? client, String? baseUrl})
    : _client = client ?? http.Client(),
      baseUrl = baseUrl ?? ApiConstants.baseUrl;

  final http.Client _client;
  final String baseUrl;

  static const _timeout = Duration(seconds: 15);
  static const _jsonHeaders = {
    'Content-Type': 'application/json; charset=UTF-8',
  };

  /// Builds a URL for [path]; empty query values are dropped and the rest are
  /// properly percent-encoded.
  Uri uri(String path, [Map<String, String>? query]) {
    final base = Uri.parse('$baseUrl$path');
    final params = {...?query}..removeWhere((_, value) => value.isEmpty);
    return params.isEmpty ? base : base.replace(queryParameters: params);
  }

  Future<dynamic> get(String path, {Map<String, String>? query}) =>
      _send(() => _client.get(uri(path, query)));

  Future<dynamic> post(String path, Object body) => _send(
    () =>
        _client.post(uri(path), headers: _jsonHeaders, body: jsonEncode(body)),
  );

  Future<dynamic> put(String path, Object body) => _send(
    () => _client.put(uri(path), headers: _jsonHeaders, body: jsonEncode(body)),
  );

  Future<dynamic> delete(String path) => _send(() => _client.delete(uri(path)));

  /// Uploads a local file as multipart field [field].
  Future<dynamic> upload(String path, String field, String filePath) =>
      _send(() async {
        final request = http.MultipartRequest('POST', uri(path))
          ..files.add(await http.MultipartFile.fromPath(field, filePath));
        return http.Response.fromStream(await _client.send(request));
      });

  Future<dynamic> _send(Future<http.Response> Function() request) async {
    final http.Response response;
    try {
      response = await request().timeout(_timeout);
    } on TimeoutException {
      throw const ApiException('Server terlalu lama merespons.');
    } catch (_) {
      throw const ApiException(
        'Tidak dapat terhubung ke server. Periksa koneksi Anda.',
      );
    }

    final body = _tryDecode(response.body);
    if (response.statusCode >= 200 && response.statusCode < 300) return body;

    throw ApiException(
      _errorMessage(body) ?? 'Permintaan gagal (${response.statusCode}).',
      statusCode: response.statusCode,
    );
  }

  static dynamic _tryDecode(String body) {
    if (body.isEmpty) return null;
    try {
      return jsonDecode(body);
    } on FormatException {
      return null;
    }
  }

  static String? _errorMessage(dynamic body) {
    if (body is! Map) return null;
    final message = body['message'];
    if (message is String && message.isNotEmpty) return message;
    final errors = body['errors'];
    if (errors is List && errors.isNotEmpty) {
      return errors
          .map((e) => e is Map ? e['msg'] : e)
          .whereType<String>()
          .join(', ');
    }
    return null;
  }
}
