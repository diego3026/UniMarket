import 'package:unimarket/constants/app_colors.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:unimarket/core/injection_container.dart';
import 'package:unimarket/presentation/viewmodels/admin/admin_businesses_products_cubit.dart';
import 'package:unimarket/presentation/viewmodels/admin/admin_businesses_products_state.dart';

class ManageBusinessPage extends StatelessWidget {
  const ManageBusinessPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => sl<AdminBusinessesCubit>()..loadBusinesses(),
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Gestionar Emprendimientos'),
          backgroundColor: Colors.white,
          elevation: 0,
          foregroundColor: AppColors.textPrimary,
        ),
        body: BlocConsumer<AdminBusinessesCubit, AdminBusinessesState>(
          listener: (context, state) {
            if (state is AdminBusinessesError) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(state.message),
                  backgroundColor: AppColors.danger,
                ),
              );
            }
          },
          builder: (context, state) {
            if (state is AdminBusinessesLoading) {
              return const Center(child: CircularProgressIndicator());
            }

            if (state is AdminBusinessesLoaded) {
              final businesses = state.businesses;

              if (businesses.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.business_center,
                        size: 64,
                        color: AppColors.border,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'No hay emprendimientos',
                        style: TextStyle(
                          fontSize: 16,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                );
              }

              return ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: businesses.length,
                itemBuilder: (context, index) =>
                    _buildBusinessCard(context, businesses[index]),
              );
            }

            if (state is AdminBusinessesError) {
              return Center(child: Text('Error: ${state.message}'));
            }

            return const SizedBox.shrink();
          },
        ),
      ),
    );
  }

  Widget _buildBusinessCard(BuildContext context, AdminBusinessModel business) {
    Color statusColor = business.status == 'Activo'
        ? AppColors.success
        : AppColors.danger;

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
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      business.name,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    Text(
                      'Propietario: ${business.owner}',
                      style: TextStyle(
                        fontSize: 12,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  business.status,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: statusColor,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildStatBubble(business.rating.toStringAsFixed(1), 'Rating'),
              _buildStatBubble('${business.sales}', 'Reseñas'),
            ],
          ),
          const SizedBox(height: 12),
          Chip(
            label: Text(business.category),
            backgroundColor: AppColors.primary.withValues(alpha: 0.1),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () =>
                      _showBusinessDetailsDialog(context, business),
                  icon: const Icon(Icons.visibility, size: 16),
                  label: const Text('Ver'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.primary,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => _toggleBusinessStatus(context, business),
                  icon: Icon(
                    business.status == 'Activo'
                        ? Icons.block
                        : Icons.check_circle,
                    size: 16,
                  ),
                  label: Text(
                    business.status == 'Activo' ? 'Suspender' : (business.status == 'Pendiente' ? 'Aprobar' : 'Activar'),
                  ),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: business.status == 'Activo'
                        ? AppColors.danger
                        : AppColors.success,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatBubble(String value, String label) {
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: AppColors.primary,
          ),
        ),
        Text(
          label,
          style: TextStyle(fontSize: 10, color: AppColors.textSecondary),
        ),
      ],
    );
  }

  void _showBusinessDetailsDialog(
    BuildContext context,
    AdminBusinessModel business,
  ) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(business.name),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildDetailRow('Propietario:', business.owner),
            _buildDetailRow('Categoría:', business.category),
            _buildDetailRow('Correo:', business.ownerEmail),
            _buildDetailRow('Reseñas:', '${business.sales}'),
            _buildDetailRow('Rating:', '${business.rating.toStringAsFixed(1)} ⭐'),
            if (business.reviewNote.isNotEmpty) _buildDetailRow('Nota:', business.reviewNote),
            _buildDetailRow('Estado:', business.status),
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

  Widget _buildDetailRow(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
        ),
        Text(
          value,
          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 12),
      ],
    );
  }

  void _toggleBusinessStatus(
    BuildContext context,
    AdminBusinessModel business,
  ) {
    if (business.status == 'Activo') {
      context.read<AdminBusinessesCubit>().suspendBusiness(business.id);
    } else {
      context.read<AdminBusinessesCubit>().activateBusiness(business.id);
    }
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          business.status == 'Activo'
              ? 'Emprendimiento suspendido'
              : 'Emprendimiento activado',
        ),
        backgroundColor: AppColors.success,
      ),
    );
  }
}

class BusinessItem {
  final int id;
  final String name;
  final String owner;
  final String category;
  final int products;
  final int sales;
  final double rating;
  final String status;

  BusinessItem({
    required this.id,
    required this.name,
    required this.owner,
    required this.category,
    required this.products,
    required this.sales,
    required this.rating,
    required this.status,
  });
}
