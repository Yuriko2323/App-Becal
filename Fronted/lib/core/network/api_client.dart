import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';
import 'package:http/http.dart' as http;
import '../../config/api_config.dart';
import 'api_exception.dart';

/// Cliente HTTP común para URL, timeout, JSON y subida multipart.
class ApiClient {
  ApiClient._();
  static final http.Client _http = http.Client();
  static const Duration _timeout = Duration(seconds: 15);
  static const Duration _uploadTimeout = Duration(seconds: 45);

  static Uri _uri(String path, [Map<String, String>? query]) {
    final normalized = path.startsWith('/') ? path : '/$path';
    return Uri.parse('${ApiConfig.baseUrl}$normalized').replace(queryParameters: query);
  }

  static Map<String, String> get _jsonHeaders => const {
    'Accept': 'application/json',
    'Content-Type': 'application/json; charset=utf-8',
  };

  static Future<dynamic> get(String path, {Map<String, String>? query}) =>
      _send(() => _http.get(_uri(path, query), headers: _jsonHeaders));

  static Future<dynamic> post(String path, {Object? body}) =>
      _send(() => _http.post(_uri(path), headers: _jsonHeaders, body: jsonEncode(body ?? <String, dynamic>{})));

  static Future<dynamic> put(String path, {Object? body}) =>
      _send(() => _http.put(_uri(path), headers: _jsonHeaders, body: jsonEncode(body ?? <String, dynamic>{})));

  static Future<dynamic> patch(String path, {Object? body}) =>
      _send(() => _http.patch(_uri(path), headers: _jsonHeaders, body: jsonEncode(body ?? <String, dynamic>{})));

  static Future<dynamic> delete(String path) =>
      _send(() => _http.delete(_uri(path), headers: _jsonHeaders));

  /// Envía bytes de una imagen como multipart/form-data, sin Base64 en JSON.
  static Future<dynamic> uploadFile(
    String path, {
    required Uint8List bytes,
    required String filename,
    String fieldName = 'archivo',
  }) async {
    late http.Response response;
    try {
      final request = http.MultipartRequest('POST', _uri(path));
      request.headers['Accept'] = 'application/json';
      request.files.add(http.MultipartFile.fromBytes(fieldName, bytes, filename: filename));
      final streamed = await request.send().timeout(_uploadTimeout);
      response = await http.Response.fromStream(streamed).timeout(_timeout);
    } on TimeoutException {
      throw const ApiException('La subida tardó demasiado. Intenta con una imagen más pequeña.');
    } on Exception catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException('No se pudo subir el archivo. Verifica la conexión con la API.');
    }
    return _parseResponse(response);
  }

  static Future<dynamic> _send(Future<http.Response> Function() request) async {
    late http.Response response;
    try {
      response = await request().timeout(_timeout);
    } on TimeoutException {
      throw const ApiException('El servidor tardó demasiado en responder.');
    } on Exception catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException('No se pudo conectar con la API. Verifica la URL, que FastAPI esté activo y la red.');
    }
    return _parseResponse(response);
  }

  static dynamic _parseResponse(http.Response response) {
    dynamic data;
    if (response.body.trim().isNotEmpty) {
      try { data = jsonDecode(utf8.decode(response.bodyBytes)); }
      catch (_) { data = response.body; }
    }
    if (response.statusCode < 200 || response.statusCode >= 300) {
      final detail = data is Map ? (data['detail'] ?? data['message']) : null;
      final message = detail is String ? detail : 'Error HTTP ${response.statusCode}';
      throw ApiException(message, statusCode: response.statusCode, details: data);
    }
    return data;
  }
}
