import 'dart:convert';
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:http_parser/http_parser.dart';
import 'package:mime/mime.dart';
import 'package:path/path.dart' as p;
import 'auth_service.dart';
import '../config.dart';

/// Servicio para subir posts con archivo usando Dio (multipart/form-data).
///
/// Uso: `final resp = await UploadService.uploadPost(token, postMap, file);`
class UploadService {
  static final Dio _dio = Dio();
  static bool _initialized = false;

  static void _ensureInitialized() {
    if (_initialized) return;
    _initialized = true;

    // Log interceptor for debugging
    _dio.interceptors.add(LogInterceptor(requestHeader: true, requestBody: true, responseHeader: true, responseBody: true));

    // Request interceptor: inject Authorization header from storage if available
    _dio.interceptors.add(InterceptorsWrapper(
      onRequest: (options, handler) async {
        try {
          final token = await AuthService().getToken();
          if (token != null && token.isNotEmpty) {
            options.headers['Authorization'] = 'Bearer $token';
          }
        } catch (_) {}
        handler.next(options);
      },
      onError: (err, handler) async {
        // If 401, try to reload token once and retry the request
        if (err.response?.statusCode == 401) {
          try {
            final newToken = await AuthService().getToken();
            if (newToken != null && newToken.isNotEmpty) {
              // clone the request with new header
              final opts = Options(method: err.requestOptions.method, headers: Map.from(err.requestOptions.headers));
              opts.headers?['Authorization'] = 'Bearer $newToken';
              try {
                final cloneResp = await _dio.request<dynamic>(
                  err.requestOptions.path,
                  data: err.requestOptions.data,
                  options: opts,
                  queryParameters: err.requestOptions.queryParameters,
                );
                return handler.resolve(cloneResp);
              } catch (_) {}
            }
          } catch (_) {}
        }
        handler.next(err);
      },
    ));
  }

  /// Envía un POST multipart/form-data a la ruta indicada.
  /// - token: opcional JWT (si null se lee desde storage).
  /// - postMap: mapa con los campos del post (se envía como parte 'post' con JSON content-type).
  /// - file: archivo opcional a enviar como parte 'file'.
  static Future<Response> uploadPost(String? token, Map<String, dynamic> postMap, File? file, {String? baseUrl}) async {
    _ensureInitialized();

    // Use provided token or load from storage
    var effectiveToken = token;
    if (effectiveToken == null || effectiveToken.isEmpty) {
      effectiveToken = await AuthService().getToken();
    }

    final formData = FormData();

    // Add 'post' as a JSON part with proper content-type
    final postPart = MultipartFile.fromString(
      jsonEncode(postMap),
      filename: 'post.json',
      contentType: MediaType('application', 'json'),
    );
    formData.files.add(MapEntry('post', postPart));

    if (file != null && await file.exists()) {
      final filename = p.basename(file.path);
      List<int> headerBytes = [];
      try {
        final raf = file.openSync(mode: FileMode.read);
        headerBytes = raf.readSync(256);
        raf.closeSync();
      } catch (_) {}
      final detected = lookupMimeType(file.path, headerBytes: headerBytes) ?? 'application/octet-stream';
      final parts = detected.split('/');
      final contentType = (parts.length == 2) ? MediaType(parts[0], parts[1]) : MediaType('application', 'octet-stream');

      final mp = await MultipartFile.fromFile(
        file.path,
        filename: filename,
        contentType: contentType,
      );
      formData.files.add(MapEntry('file', mp));
    }

    try {
      final effectiveBase = baseUrl ?? AppConfig.apiBase;
      final resp = await _dio.post('$effectiveBase/api/v1/posts', data: formData, options: Options(headers: effectiveToken != null ? {'Authorization': 'Bearer $effectiveToken'} : null, validateStatus: (_) => true));
      return resp;
    } on DioException catch (e) {
      final status = e.response?.statusCode;
      if (status == 413) throw Exception('Archivo demasiado grande (HTTP 413).');
      if (status != null && status >= 400 && status < 600) throw Exception('HTTP $status: ${e.response?.statusMessage ?? e.message}');
      throw Exception('Error de red: ${e.message}');
    }
  }
}
