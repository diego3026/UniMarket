import 'package:unimarket/core/utils/formatters.dart';
import 'package:unimarket/constants/app_colors.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:unimarket/core/injection_container.dart';
import 'package:unimarket/presentation/viewmodels/entrepreneur/bank_data_cubit.dart';
import 'package:unimarket/presentation/viewmodels/entrepreneur/bank_data_state.dart';
import 'package:unimarket/core/utils/notification_helper.dart';

class BankDataPage extends StatefulWidget {
  const BankDataPage({super.key});

  @override
  State<BankDataPage> createState() => _BankDataPageState();
}

class _BankDataPageState extends State<BankDataPage> {
  bool _isEditing = false;
  late TextEditingController bankNameController;
  late TextEditingController accountNumberController;
  late TextEditingController accountHolderController;
  late TextEditingController accountTypeController;

  @override
  void initState() {
    super.initState();
    bankNameController = TextEditingController();
    accountNumberController = TextEditingController();
    accountHolderController = TextEditingController();
    accountTypeController = TextEditingController();
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => sl<BankDataCubit>()..loadBankData(),
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Datos Bancarios'),
          backgroundColor: Colors.white,
          elevation: 0,
          foregroundColor: AppColors.textPrimary,
          actions: [
            TextButton(
              onPressed: () {
                setState(() {
                  _isEditing = !_isEditing;
                });
                if (!_isEditing) {
                  context.read<BankDataCubit>().updateBankData(
                    bankName: bankNameController.text,
                    accountNumber: accountNumberController.text,
                    accountHolderName: accountHolderController.text,
                    accountType: accountTypeController.text,
                  );
                }
              },
              child: Text(_isEditing ? 'Guardar' : 'Editar'),
            ),
          ],
        ),
        body: BlocConsumer<BankDataCubit, BankDataState>(
          listener: (context, state) {
            if (state is BankDataError) {
              NotificationHelper.showError(
                context: context,
                message: state.message,
              );
            } else if (state is BankDataUpdated) {
              NotificationHelper.showSuccess(
                context: context,
                message: 'Dados bancarios guardados',
              );
              setState(() => _isEditing = false);
            } else if (state is WithdrawalSuccess) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    'Retiro de ${formatCop(state.amount)} solicitado exitosamente',
                  ),
                  backgroundColor: AppColors.success,
                ),
              );
            }
          },
          builder: (context, state) {
            if (state is BankDataLoading) {
              return const Center(child: CircularProgressIndicator());
            }

            if (state is BankDataLoaded) {
              final bankData = state.bankData;

              // Initialize controllers with loaded data
              if (bankNameController.text.isEmpty) {
                bankNameController.text = bankData.bankName;
                accountNumberController.text = bankData.accountNumber;
                accountHolderController.text = bankData.accountHolderName;
                accountTypeController.text = bankData.accountType;
              }

              return SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Información Bancaria',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 16),
                    _buildBankField('Banco', bankNameController),
                    const SizedBox(height: 12),
                    _buildBankField(
                      'Número de Cuenta',
                      accountNumberController,
                    ),
                    const SizedBox(height: 12),
                    _buildBankField(
                      'Titular de Cuenta',
                      accountHolderController,
                    ),
                    const SizedBox(height: 12),
                    _buildBankField('Tipo de Cuenta', accountTypeController),
                    const SizedBox(height: 24),
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppColors.sellerLight,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: AppColors.seller.withValues(alpha: 0.4),
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Saldo Disponible',
                            style: TextStyle(
                              fontSize: 13,
                              color: AppColors.textSecondary,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            formatCop(bankData.availableBalance),
                            style: const TextStyle(
                              fontSize: 28,
                              fontWeight: FontWeight.bold,
                              color: AppColors.seller,
                            ),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            'Ganancias Totales: ${formatCop(bankData.totalEarnings)}',
                            style: TextStyle(
                              fontSize: 12,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: AppColors.warningLight,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: AppColors.warning.withValues(alpha: 0.4),
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.info_outline,
                            color: AppColors.warning,
                            size: 20,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              'Los pagos se depositarán en esta cuenta bancaria',
                              style: TextStyle(
                                fontSize: 12,
                                color: AppColors.warning,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                    SizedBox(
                      width: double.infinity,
                      child: state is WithdrawalProcessing
                          ? ElevatedButton(
                              onPressed: null,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.textSecondary,
                              ),
                              child: const SizedBox(
                                height: 48,
                                child: Center(
                                  child: CircularProgressIndicator(),
                                ),
                              ),
                            )
                          : ElevatedButton(
                              onPressed: () => _showWithdrawalDialog(context),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.seller,
                                foregroundColor: Colors.white,
                                minimumSize: const Size(double.infinity, 48),
                              ),
                              child: const Text('Realizar Retiro'),
                            ),
                    ),
                  ],
                ),
              );
            }

            if (state is BankDataError) {
              return Center(child: Text('Error: ${state.message}'));
            }

            return const SizedBox.shrink();
          },
        ),
      ),
    );
  }

  Widget _buildBankField(String label, TextEditingController controller) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: AppColors.textSecondary,
          ),
        ),
        const SizedBox(height: 6),
        TextField(
          controller: controller,
          enabled: _isEditing,
          decoration: InputDecoration(
            hintText: label,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide(color: AppColors.border),
            ),
            disabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide(color: AppColors.border),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: AppColors.seller, width: 2),
            ),
            filled: true,
            fillColor: _isEditing ? Colors.white : AppColors.surfaceMuted,
          ),
        ),
      ],
    );
  }

  void _showWithdrawalDialog(BuildContext context) {
    final amountController = TextEditingController();
    final bankDataState =
        (context.read<BankDataCubit>().state as BankDataLoaded);

    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Realizar Retiro'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.sellerLight,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Saldo disponible',
                      style: TextStyle(
                        fontSize: 12,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    Text(
                      formatCop(bankDataState.bankData.availableBalance),
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: AppColors.seller,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: amountController,
                decoration: const InputDecoration(
                  labelText: 'Monto a retirar',
                  prefixText: '\$ ',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.number,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.success),
            onPressed: () {
              final amount = double.tryParse(amountController.text) ?? 0;
              context.read<BankDataCubit>().requestWithdrawal(amount);
              Navigator.pop(dialogContext);
            },
            child: const Text('Confirmar'),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    bankNameController.dispose();
    accountNumberController.dispose();
    accountHolderController.dispose();
    accountTypeController.dispose();
    super.dispose();
  }
}
