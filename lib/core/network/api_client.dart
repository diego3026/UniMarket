// lib/core/network/api_client.dart
//
// Cliente HTTP de la app:
// - Agrega X-App-Key y el token de sesión a cada petición.
// - Si el token venció, lo renueva una sola vez (aunque fallen varias peticiones a la vez)
//   y repite la petición. Si no se puede renovar, avisa para cerrar la sesión.
// - Convierte cualquier error en ApiException con un mensaje en español listo para mostrar.
import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

import 'api_config.dart';
import 'token_storage.dart';

class ApiException implements Exception {
  final String code;
  final String message;
  final int? status;
  final Object? details;

  const ApiException(this.message, {this.code = 'error', this.status, this.details});

  bool get isNetwork => code == 'network';
  bool get isUnauthorized => status == 401;

  @override
  String toString() => message;
}

class ApiClient {
  final Dio _dio;
  final TokenStorage tokens;

  /// Se llama cuando la sesión ya no se puede renovar (hay que volver al login).
  VoidCallback? onSessionExpired;

  Completer<bool>? _refreshing;

  ApiClient(this.tokens, {Dio? dio})
    : _dio =
          dio ??
          Dio(
            BaseOptions(
              baseUrl: ApiConfig.baseUrl,
              connectTimeout: ApiConfig.connectTimeout,
              receiveTimeout: ApiConfig.receiveTimeout,
              responseType: ResponseType.json,
              headers: {
                'Accept': 'application/json',
                if (ApiConfig.appKey.isNotEmpty) 'X-App-Key': ApiConfig.appKey,
              },
            ),
          ) {
    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          if (options.extra['auth'] != false) {
            final token = await tokens.accessToken;
            if (token != null) options.headers['Authorization'] = 'Bearer $token';
          }
          handler.next(options);
        },
        onError: (error, handler) async {
          final req = error.requestOptions;
          final isAuthCall = req.path.startsWith('/auth/');
          if (error.response?.statusCode == 401 &&
              !isAuthCall &&
              req.extra['retried'] != true &&
              await _refresh()) {
            req.extra['retried'] = true;
            req.headers['Authorization'] = 'Bearer ${await tokens.accessToken}';
            try {
              return handler.resolve(await _dio.fetch(req));
            } on DioException catch (e) {
              return handler.next(e);
            }
          }
          handler.next(error);
        },
      ),
    );
  }

  /// Renueva la sesión con el refresh token. Varias peticiones esperan la misma renovación.
  Future<bool> _refresh() async {
    if (_refreshing != null) return _refreshing!.future;
    final completer = _refreshing = Completer<bool>();
    try {
      final refresh = await tokens.refreshToken;
      if (refresh == null) {
        completer.complete(false);
      } else {
        final r = await _dio.post(
          '/auth/refresh',
          data: {'refreshToken': refresh},
          options: Options(extra: {'auth': false}),
        );
        await tokens.save(r.data['accessToken'], r.data['refreshToken']);
        completer.complete(true);
      }
    } catch (_) {
      await tokens.clear();
      onSessionExpired?.call();
      completer.complete(false);
    } finally {
      _refreshing = null;
    }
    return completer.future;
  }

  Future<dynamic> get(String path, {Map<String, dynamic>? query, Map<String, String>? headers}) =>
      _send(() => _dio.get(path, queryParameters: _clean(query), options: Options(headers: headers)));

  Future<dynamic> post(String path, {Object? data, Map<String, String>? headers, bool auth = true}) =>
      _send(() => _dio.post(path, data: data ?? {}, options: Options(headers: headers, extra: {'auth': auth})));

  Future<dynamic> patch(String path, {Object? data}) => _send(() => _dio.patch(path, data: data ?? {}));

  Future<dynamic> put(String path, {Object? data}) => _send(() => _dio.put(path, data: data ?? {}));

  Future<dynamic> delete(String path) => _send(() => _dio.delete(path));

  /// GET que respeta ETag: si nada cambió devuelve null (304) y no gasta datos.
  final Map<String, String> _etags = {};
  final Map<String, dynamic> _etagBodies = {};

  Future<dynamic> getCached(String path, {Map<String, dynamic>? query}) async {
    final key = '$path?${_clean(query)}';
    final etag = _etags[key];
    try {
      final r = await _dio.get(
        path,
        queryParameters: _clean(query),
        options: Options(
          headers: {if (etag != null) 'If-None-Match': etag},
          validateStatus: (s) => s != null && (s < 300 || s == 304),
        ),
      );
      if (r.statusCode == 304) return _etagBodies[key];
      final newTag = r.headers.value('etag');
      if (newTag != null) {
        _etags[key] = newTag;
        _etagBodies[key] = r.data;
      }
      return r.data;
    } on DioException catch (e) {
      throw _map(e);
    }
  }

  /// Sube un archivo a otra URL (Cloudinary) con campos firmados por el backend.
  Future<Map<String, dynamic>> uploadMultipart(
    String url,
    Map<String, String> fields,
    MultipartFile file,
  ) async {
    try {
      final r = await Dio().post(url, data: FormData.fromMap({...fields, 'file': file}));
      return Map<String, dynamic>.from(r.data as Map);
    } on DioException catch (e) {
      throw ApiException(
        'No se pudo subir la imagen. Revisa tu conexión e intenta de nuevo.',
        code: 'upload_failed',
        status: e.response?.statusCode,
      );
    }
  }

  void clearCache() {
    _etags.clear();
    _etagBodies.clear();
  }

  Future<dynamic> _send(Future<Response> Function() call) async {
    try {
      final r = await call();
      return r.data;
    } on DioException catch (e) {
      throw _map(e);
    }
  }

  static Map<String, dynamic>? _clean(Map<String, dynamic>? q) =>
      q == null ? null : (Map.of(q)..removeWhere((_, v) => v == null || v == ''));

  static ApiException _map(DioException e) {
    final res = e.response;
    if (res == null) {
      final timeout = e.type == DioExceptionType.connectionTimeout ||
          e.type == DioExceptionType.receiveTimeout;
      return ApiException(
        timeout
            ? 'El servidor tardó demasiado en responder. Intenta de nuevo.'
            : 'Sin conexión. Revisa tu internet e intenta de nuevo.',
        code: 'network',
      );
    }
    final body = res.data;
    if (body is Map && body['error'] is Map) {
      final err = body['error'] as Map;
      var message = (err['message'] ?? 'Ocurrió un error').toString();
      final details = err['details'];
      // Errores de validación: muestra el primero, que es el más útil.
      if (err['code'] == 'validation_error' && details is List && details.isNotEmpty) {
        final first = details.first;
        if (first is Map && first['message'] != null) {
          message = _friendlyValidation(first['message'].toString());
        }
      }
      return ApiException(
        message,
        code: (err['code'] ?? 'error').toString(),
        status: res.statusCode,
        details: details,
      );
    }
    return ApiException(
      res.statusCode == 502 || res.statusCode == 503
          ? 'El servicio no está disponible en este momento. Intenta en un minuto.'
          : 'Ocurrió un error inesperado (${res.statusCode}).',
      code: 'http_${res.statusCode}',
      status: res.statusCode,
    );
  }

  static String _friendlyValidation(String m) {
    // Pydantic antepone "Value error, " a los mensajes de los validadores.
    return m.replaceFirst('Value error, ', '');
  }
}
