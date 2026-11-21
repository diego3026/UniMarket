import 'package:file_picker/file_picker.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/network/api_client.dart';
import '../../../core/network/media_uploader.dart';
import 'documents_state.dart';

/// Documentos de verificación del emprendedor (GET/POST /seller/documents).
/// Los archivos se suben como privados a Cloudinary; solo el admin los ve.
class DocumentsCubit extends Cubit<DocumentsState> {
  final ApiClient _api;
  final MediaUploader _uploader;
  DocumentsCubit(this._api) : _uploader = MediaUploader(_api), super(const DocumentsInitial());

  static const required = ['Cédula de ciudadanía', 'Carné estudiantil', 'Certificado bancario'];

  List<DocumentModel> _documents = [];

  Future<void> loadDocuments() async {
    if (_documents.isEmpty) emit(const DocumentsLoading());
    try {
      final r = await _api.get('/seller/documents') as List;
      final all = [for (final d in r) DocumentModel.fromJson(d as Map<String, dynamic>)]
        ..sort((a, b) => b.uploadedAt.compareTo(a.uploadedAt));
      final latest = <String, DocumentModel>{};
      for (final d in all) {
        latest.putIfAbsent(d.name, () => d);
      }
      _documents = [
        for (final n in required) latest[n] ?? DocumentModel.missing(n),
        for (final d in latest.values) if (!required.contains(d.name)) d,
      ];
      emit(DocumentsLoaded(_documents));
    } on ApiException catch (e) {
      emit(DocumentsError(e.message));
    }
  }

  Future<void> uploadDocument({required String documentName, required PlatformFile file}) async {
    emit(DocumentUploading(documentName: documentName, progress: 0));
    try {
      final url = await _uploader.upload(file, 'document');
      final r = await _api.post('/seller/documents', data: {'name': documentName, 'fileUrl': url});
      emit(DocumentUploaded(DocumentModel.fromJson(r as Map<String, dynamic>)));
    } on ApiException catch (e) {
      emit(DocumentsError(e.message));
    }
    await loadDocuments();
  }

  bool allDocumentsVerified() => _documents.isNotEmpty && _documents.every((d) => d.isVerified);

  int getVerificationProgress() {
    if (_documents.isEmpty) return 0;
    return (_documents.where((d) => d.isVerified).length * 100) ~/ _documents.length;
  }
}
