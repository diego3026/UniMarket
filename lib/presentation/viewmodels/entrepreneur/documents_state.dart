import 'package:equatable/equatable.dart';

/// Estados para el manejo de documentos
abstract class DocumentsState extends Equatable {
  const DocumentsState();

  @override
  List<Object?> get props => [];
}

class DocumentsInitial extends DocumentsState {
  const DocumentsInitial();
}

class DocumentsLoading extends DocumentsState {
  const DocumentsLoading();
}

class DocumentsLoaded extends DocumentsState {
  final List<DocumentModel> documents;

  const DocumentsLoaded(this.documents);

  @override
  List<Object?> get props => [documents];
}

class DocumentUploading extends DocumentsState {
  final String documentName;
  final double progress;

  const DocumentUploading({required this.documentName, required this.progress});

  @override
  List<Object?> get props => [documentName, progress];
}

class DocumentUploaded extends DocumentsState {
  final DocumentModel document;

  const DocumentUploaded(this.document);

  @override
  List<Object?> get props => [document];
}

class DocumentsError extends DocumentsState {
  final String message;

  const DocumentsError(this.message);

  @override
  List<Object?> get props => [message];
}

/// Modelo de documento
class DocumentModel extends Equatable {
  final String id; // vacío si aún no se ha cargado
  final String name;
  final String status; // 'Verificado' | 'Pendiente de revisión' | 'Rechazado' | 'Sin cargar'
  final String? fileUrl;
  final String? rejectReason;
  final DateTime uploadedAt;
  final DateTime? verifiedAt;

  const DocumentModel({
    required this.id,
    required this.name,
    required this.status,
    this.fileUrl,
    this.rejectReason,
    required this.uploadedAt,
    this.verifiedAt,
  });

  factory DocumentModel.missing(String name) =>
      DocumentModel(id: '', name: name, status: 'Sin cargar', uploadedAt: DateTime.now());

  factory DocumentModel.fromJson(Map<String, dynamic> j) {
    final st = (j['status'] ?? 'pending').toString();
    final note = (j['reviewNote'] ?? '').toString();
    return DocumentModel(
      id: j['id'].toString(),
      name: (j['name'] ?? '').toString(),
      status: switch (st) {
        'approved' => 'Verificado',
        'rejected' => 'Rechazado',
        _ => 'Pendiente de revisión',
      },
      fileUrl: j['fileUrl']?.toString(),
      rejectReason: note.isEmpty ? null : note,
      uploadedAt: DateTime.tryParse((j['createdAt'] ?? '').toString())?.toLocal() ?? DateTime.now(),
    );
  }

  bool get isVerified => status == 'Verificado';
  bool get isPending => status == 'Pendiente de revisión';
  bool get isRejected => status == 'Rechazado';
  bool get isMissing => id.isEmpty;

  @override
  List<Object?> get props => [id, name, status, fileUrl, rejectReason, uploadedAt, verifiedAt];
}
