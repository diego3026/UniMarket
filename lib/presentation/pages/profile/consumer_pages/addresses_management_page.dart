import 'package:unimarket/constants/app_colors.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:unimarket/presentation/pages/addresses/address_form_page.dart';
import 'package:unimarket/core/injection_container.dart';
import 'package:unimarket/presentation/viewmodels/addresses/addresses_cubit.dart';
import 'package:unimarket/presentation/viewmodels/addresses/addresses_state.dart';
import 'package:unimarket/core/utils/notification_helper.dart';

class AddressesManagementPage extends StatelessWidget {
  const AddressesManagementPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => sl<AddressesCubit>()..loadAddresses(),
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Mis Direcciones'),
          backgroundColor: Colors.white,
          elevation: 0,
          foregroundColor: AppColors.textPrimary,
        ),
        body: BlocConsumer<AddressesCubit, AddressesState>(
          listener: (context, state) {
            if (state is AddressError) {
              NotificationHelper.showError(
                context: context,
                message: state.message,
              );
            } else if (state is AddressAdded ||
                state is AddressUpdated ||
                state is AddressDeleted) {
              NotificationHelper.showSuccess(
                context: context,
                message: state is AddressAdded
                    ? 'Dirección agregada'
                    : state is AddressUpdated
                    ? 'Dirección actualizada'
                    : 'Dirección eliminada',
              );
              // Reload addresses after any action
              context.read<AddressesCubit>().loadAddresses();
            }
          },
          builder: (context, state) {
            if (state is AddressesLoading) {
              return const Center(child: CircularProgressIndicator());
            }

            if (state is AddressesLoaded) {
              final addresses = state.addresses;

              if (addresses.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.location_off,
                        size: 64,
                        color: AppColors.border,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'No hay direcciones registradas',
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
                itemCount: addresses.length,
                itemBuilder: (context, index) =>
                    _buildAddressCard(context, addresses[index]),
              );
            }

            if (state is AddressError) {
              return Center(child: Text('Error: ${state.message}'));
            }

            return const SizedBox.shrink();
          },
        ),
        floatingActionButton: FloatingActionButton(
          backgroundColor: AppColors.primary,
          onPressed: () => _openForm(context),
          child: const Icon(Icons.add),
        ),
      ),
    );
  }

  Widget _buildAddressCard(BuildContext context, AddressModel address) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: address.isDefault ? AppColors.primary : AppColors.border,
          width: address.isDefault ? 2 : 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                address.label,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
              if (address.isDefault)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Text(
                    'Por defecto',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: AppColors.primary,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            address.address,
            style: TextStyle(fontSize: 14, color: AppColors.textSecondary),
          ),
          Text(
            [if ((address.postalCode ?? '').isNotEmpty) address.postalCode!, address.city].join(' · '),
            style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
          ),
          if (address.latitude != null)
            const Padding(
              padding: EdgeInsets.only(top: 4),
              child: Row(
                children: [
                  Icon(Icons.location_on_rounded, size: 14, color: AppColors.success),
                  SizedBox(width: 4),
                  Text('Ubicación en el mapa', style: TextStyle(fontSize: 12, color: AppColors.success)),
                ],
              ),
            ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              OutlinedButton.icon(
                onPressed: () => _openForm(context, address),
                icon: const Icon(Icons.edit_outlined, size: 18),
                label: const Text('Editar'),
              ),
              OutlinedButton.icon(
                onPressed: () => _confirmDeleteAddress(context, address.id),
                icon: const Icon(Icons.delete_outline_rounded, size: 18),
                label: const Text('Eliminar'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.danger,
                  side: const BorderSide(color: AppColors.danger),
                ),
              ),
              if (!address.isDefault)
                TextButton.icon(
                  onPressed: () => context
                      .read<AddressesCubit>()
                      .setDefaultAddress(address.id),
                  icon: const Icon(Icons.check_rounded, size: 18),
                  label: const Text('Usar por defecto'),
                ),
            ],
          ),
        ],
      ),
    );
  }

  void _openForm(BuildContext context, [AddressModel? address]) {
    final cubit = context.read<AddressesCubit>();
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => BlocProvider.value(value: cubit, child: AddressFormPage(initial: address)),
      ),
    );
  }

  void _confirmDeleteAddress(BuildContext context, String id) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Eliminar Dirección'),
        content: const Text(
          '¿Estás seguro de que quieres eliminar esta dirección?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.danger),
            onPressed: () {
              context.read<AddressesCubit>().deleteAddress(id);
              Navigator.pop(dialogContext);
            },
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );
  }
}
