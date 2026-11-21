import 'package:unimarket/constants/app_colors.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:unimarket/core/injection_container.dart';
import 'package:unimarket/core/network/media_uploader.dart';
import 'package:unimarket/presentation/viewmodels/entrepreneur/documents_cubit.dart';
import 'package:unimarket/presentation/viewmodels/entrepreneur/documents_state.dart';
import 'package:unimarket/core/utils/notification_helper.dart';

class DocumentsPage extends StatelessWidget {
  const DocumentsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => sl<DocumentsCubit>()..loadDocuments(),
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Documentos'),
          backgroundColor: Colors.white,
          elevation: 0,
          foregroundColor: AppColors.textPrimary,
        ),
        body: BlocConsumer<DocumentsCubit, DocumentsState>(
          listener: (context, state) {
            if (state is DocumentsError) {
              NotificationHelper.showError(
                context: context,
                message: state.message,
              );
            } else if (state is DocumentUploaded) {
              NotificationHelper.showSuccess(
                context: context,
                message: 'Documento enviado a revisión',
              );
            }
          },
          builder: (context, state) {
            if (state is DocumentsLoading || state is DocumentUploading) {
              return const Center(child: CircularProgressIndicator());
            }

            if (state is DocumentsLoaded) {
              final documents = state.documents;
              final verificationProgress = context
                  .read<DocumentsCubit>()
                  .getVerificationProgress();

              return ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: AppColors.seller.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: AppColors.seller.withValues(alpha: 0.3),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(
                              Icons.shield_outlined,
                              color: AppColors.seller,
                              size: 20,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                'Todos los documentos son verificados de forma segura',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: AppColors.seller,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(4),
                          child: LinearProgressIndicator(
                            value: verificationProgress / 100,
                            minHeight: 6,
                            backgroundColor: AppColors.border,
                            valueColor: AlwaysStoppedAnimation(
                              verificationProgress == 100
                                  ? AppColors.success
                                  : AppColors.seller,
                            ),
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'Verificación: $verificationProgress%',
                          style: TextStyle(
                            fontSize: 11,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                  ...documents.map((doc) => _buildDocumentCard(context, doc)),
                ],
              );
            }

            if (state is DocumentsError) {
              return Center(
                child: TextButton.icon(
                  onPressed: () => context.read<DocumentsCubit>().loadDocuments(),
                  icon: const Icon(Icons.refresh),
                  label: const Text('Reintentar'),
                ),
              );
            }

            return const SizedBox.shrink();
          },
        ),
      ),
    );
  }

  Widget _buildDocumentCard(BuildContext context, DocumentModel document) {
    late Color statusColor;
    late IconData statusIcon;

    if (document.isVerified) {
      statusColor = AppColors.success;
      statusIcon = Icons.verified;
    } else if (document.isRejected) {
      statusColor = AppColors.danger;
      statusIcon = Icons.error;
    } else if (document.isMissing) {
      statusColor = AppColors.textSecondary;
      statusIcon = Icons.upload_file;
    } else {
      statusColor = AppColors.warning;
      statusIcon = Icons.schedule;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  document.name,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Container(
                constraints: const BoxConstraints(maxWidth: 140),
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(statusIcon, size: 12, color: statusColor),
                    const SizedBox(width: 4),
                    Flexible(
                      child: Text(
                        document.status,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: statusColor,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Cargado: ${document.uploadedAt.toString().split(' ')[0]}',
            style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
          ),
          const SizedBox(height: 12),
          if (document.isRejected && document.rejectReason != null)
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppColors.dangerLight,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    'Motivo del rechazo: ${document.rejectReason}',
                    style: TextStyle(fontSize: 11, color: AppColors.danger),
                  ),
                ),
                const SizedBox(height: 10),
              ],
            ),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: document.isMissing ? null : () => _showViewDocumentDialog(context, document),
                  icon: const Icon(Icons.visibility, size: 16),
                  label: const Text('Ver'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.seller,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => _showUploadDocumentDialog(context, document),
                  icon: const Icon(Icons.upload_file, size: 16),
                  label: Text(document.isMissing ? 'Cargar' : 'Reemplazar'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.seller,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _showViewDocumentDialog(BuildContext context, DocumentModel document) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(document.name),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: double.infinity,
              height: 300,
              decoration: BoxDecoration(
                color: AppColors.border,
                borderRadius: BorderRadius.circular(10),
              ),
              child: document.fileUrl != null && !document.fileUrl!.contains('/private/')
                  ? ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: Image.network(
                        document.fileUrl!,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          return const Icon(
                            Icons.image,
                            size: 100,
                            color: AppColors.textSecondary,
                          );
                        },
                      ),
                    )
                  : const Icon(
                      Icons.image,
                      size: 100,
                      color: AppColors.textSecondary,
                    ),
            ),
            const SizedBox(height: 16),
            Text(
              'Estado: ${document.status}',
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
            ),
            if (document.verifiedAt != null)
              Text(
                'Verificado: ${document.verifiedAt.toString().split(' ')[0]}',
                style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
              ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cerrar'),
          ),
        ],
      ),
    );
  }

  void _showUploadDocumentDialog(BuildContext context, DocumentModel document) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text('Cargar ${document.name}'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppColors.surfaceMuted,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: AppColors.border),
              ),
              child: Column(
                children: [
                  Icon(
                    Icons.cloud_upload,
                    size: 40,
                    color: AppColors.textSecondary,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Elige una foto o PDF legible del documento',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: AppColors.textSecondary),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Formatos soportados: PDF, JPG, PNG',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 11, color: AppColors.textMuted),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.seller),
            onPressed: () async {
              final cubit = context.read<DocumentsCubit>();
              Navigator.pop(dialogContext);
              final file = await MediaUploader.pick(document: true);
              if (file == null) return;
              await cubit.uploadDocument(documentName: document.name, file: file);
            },
            child: const Text('Elegir archivo'),
          ),
        ],
      ),
    );
  }
}
