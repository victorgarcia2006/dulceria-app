import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

/// URL base de la API. Cámbiala según dónde corra la app:
///  - Emulador Android: http://10.0.2.2:3000/api (10.0.2.2 es la PC anfitriona).
///  - Flutter web o simulador iOS: http://localhost:3000/api
///  - Teléfono físico: `http://IP-de-la-computadora:3000/api` (misma red wifi).
const String kApiBaseUrl = 'http://10.0.2.2:3000/api';

/// Tiempo máximo de espera por petición antes de considerarla falla de conexión.
const Duration kApiTimeout = Duration(seconds: 10);

/// Error que responde el servidor (4xx/5xx). [message] ya viene en español.
class ApiException implements Exception {
  ApiException(this.message, {this.statusCode});

  final String message;
  final int? statusCode;

  /// 422: regla de negocio (existencias insuficientes o producto descontinuado).
  bool get esReglaDeNegocio => statusCode == 422;

  @override
  String toString() => 'ApiException($statusCode): $message';
}

/// No se pudo hablar con el servidor (sin red, apagado, tiempo agotado).
class ConnectionException implements Exception {
  ConnectionException([this.message = kMensajeSinConexion]);

  final String message;

  @override
  String toString() => 'ConnectionException: $message';
}

const String kMensajeSinConexion =
    'No pudimos conectar con el servidor. Revisa tu conexión e inténtalo de nuevo.';
const String kMensajeErrorServidor =
    'Algo salió mal en el servidor. Inténtalo de nuevo en un momento.';

/// Cliente HTTP mínimo: GET/POST/PATCH que devuelven JSON ya decodificado.
class ApiClient {
  ApiClient({this._baseUrl = kApiBaseUrl, http.Client? client})
    : _client = client ?? http.Client();

  final String _baseUrl;
  final http.Client _client;

  Future<dynamic> get(String path, {Map<String, String>? query}) =>
      _enviar('GET', path, query: query);

  Future<dynamic> post(String path, {Object? body}) =>
      _enviar('POST', path, body: body);

  Future<dynamic> patch(String path, {Object? body}) =>
      _enviar('PATCH', path, body: body);

  Future<dynamic> _enviar(
    String metodo,
    String path, {
    Map<String, String>? query,
    Object? body,
  }) async {
    final uri = Uri.parse('$_baseUrl$path').replace(queryParameters: query);
    final request = http.Request(metodo, uri)
      ..headers['Accept'] = 'application/json';
    if (body != null) {
      request.headers['Content-Type'] = 'application/json';
      request.body = jsonEncode(body);
    }

    final http.Response response;
    try {
      final streamed = await _client.send(request).timeout(kApiTimeout);
      response = await http.Response.fromStream(streamed).timeout(kApiTimeout);
    } on TimeoutException {
      throw ConnectionException();
    } on http.ClientException {
      // En móvil y web, los fallos de red (SocketException, etc.) llegan aquí.
      throw ConnectionException();
    }

    final decodificado = _decodificar(response);
    if (response.statusCode >= 200 && response.statusCode < 300) {
      return decodificado;
    }
    if (response.statusCode >= 400 && response.statusCode < 500) {
      throw ApiException(
        _mensajeDe(decodificado) ?? kMensajeErrorServidor,
        statusCode: response.statusCode,
      );
    }
    // 5xx u otros: no mostramos texto crudo del servidor.
    throw ApiException(kMensajeErrorServidor, statusCode: response.statusCode);
  }

  dynamic _decodificar(http.Response response) {
    if (response.bodyBytes.isEmpty) return null;
    try {
      return jsonDecode(utf8.decode(response.bodyBytes));
    } on FormatException {
      return null;
    }
  }

  /// El campo `message` puede ser texto o una lista de textos (validación 400).
  String? _mensajeDe(dynamic cuerpo) {
    if (cuerpo is! Map) return null;
    final message = cuerpo['message'];
    if (message is String && message.isNotEmpty) return message;
    if (message is List && message.isNotEmpty) {
      return message.map((m) => m.toString()).join('\n');
    }
    return null;
  }

  void close() => _client.close();
}
