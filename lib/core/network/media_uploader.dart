import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:file_picker/file_picker.dart';

import 'api_client.dart';

/// Sube imágenes/documentos directo a Cloudinary con una firma del backend
/// (POST /uploads/sign). Devuelve la `secure_url` que luego se envía a la API.
class MediaUploader {
  final ApiClient _api;
  MediaUploader(this._api);

  static const imageExt = ['jpg', 'jpeg', 'png', 'webp'];
  static const docExt = ['pdf', 'jpg', 'jpeg', 'png'];

  /// Abre el selector de archivos. Devuelve null si el usuario cancela.
  static Future<PlatformFile?> pick({bool document = false}) async {
    return FilePicker.pickFile(
      type: FileType.custom,
      allowedExtensions: document ? docExt : imageExt,
      compressionQuality: document ? 0 : 80,
    );
  }

  /// [purpose]: product | store | avatar | document
  Future<String> upload(PlatformFile file, String purpose) async {
    final Uint8List bytes;
    try {
      bytes = await file.readAsBytes();
    } catch (_) {
      throw ApiException('No se pudo leer el archivo', code: 'read_failed');
    }
    final sign = await _api.post('/uploads/sign', data: {'purpose': purpose}) as Map<String, dynamic>;
    final max = (sign['maxBytes'] as num?)?.toInt() ?? 5 * 1024 * 1024;
    if (bytes.length > max) {
      throw ApiException('El archivo pesa más de ${max ~/ (1024 * 1024)} MB', code: 'file_too_large');
    }
    final fields = Map<String, String>.from(
      (sign['fields'] as Map).map((k, v) => MapEntry(k.toString(), v.toString())),
    );
    final r = await _api.uploadMultipart(
      sign['uploadUrl'] as String,
      fields,
      MultipartFile.fromBytes(bytes, filename: file.name),
    );
    final url = r['secure_url'] as String?;
    if (url == null) throw ApiException('No se pudo subir el archivo', code: 'upload_failed');
    return url;
  }
}
