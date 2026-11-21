import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:unimarket/constants/app_colors.dart';
import 'package:unimarket/core/injection_container.dart';
import 'package:unimarket/core/utils/formatters.dart';
import 'package:unimarket/core/utils/notification_helper.dart';
import 'package:unimarket/presentation/viewmodels/entrepreneur/bank_data_cubit.dart';
import 'package:unimarket/presentation/viewmodels/entrepreneur/bank_data_state.dart';

/// Cuenta donde el emprendedor recibe sus pagos. Los clientes pagan
/// directamente a la tienda (Bre-B, Nequi o efectivo), así que aquí no hay
/// "saldo" que retirar: solo la cuenta registrada y el resumen de ventas.
class BankDataPage extends StatelessWidget {
  const BankDataPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => sl<BankDataCubit>()..loadBankData(),
      child: const _BankDataView(),
    );
  }
}

class _BankDataView extends StatefulWidget {
  const _BankDataView();
  @override
  State<_BankDataView> createState() => _BankDataViewState();
}

class _BankDataViewState extends State<_BankDataView> {
  static const _types = {
    'ahorros': 'Cuenta de ahorros',
    'corriente': 'Cuenta corriente',
    'nequi': 'Nequi',
    'daviplata': 'Daviplata',
  };

  final _formKey = GlobalKey<FormState>();
  final _bank = TextEditingController();
  final _number = TextEditingController();
  final _holder = TextEditingController();
  final _document = TextEditingController();
  String _type = 'ahorros';
  bool _editing = false;
  bool _filled = false;

  @override
  void dispose() {
    for (final c in [_bank, _number, _holder, _document]) {
      c.dispose();
    }
    super.dispose();
  }

  void _save() {
    if (!_formKey.currentState!.validate()) return;
    context.read<BankDataCubit>().updateBankData(
      bankName: _bank.text,
      accountType: _type,
      accountNumber: _number.text,
      holderName: _holder.text,
      holderDocument: _document.text,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Cuenta de pagos'),
        backgroundColor: Colors.white,
        elevation: 0,
        foregroundColor: AppColors.textPrimary,
      ),
      body: BlocConsumer<BankDataCubit, BankDataState>(
        listener: (context, state) {
          if (state is BankDataError) {
            NotificationHelper.showError(context: context, message: state.message);
          } else if (state is BankDataUpdated) {
            NotificationHelper.showSuccess(context: context, message: 'Cuenta guardada');
            setState(() {
              _editing = false;
              _number.clear();
              _document.clear();
            });
          }
        },
        buildWhen: (_, s) => s is BankDataLoaded || s is BankDataLoading || s is BankDataInitial,
        builder: (context, state) {
          if (state is! BankDataLoaded) {
            return const Center(child: CircularProgressIndicator());
          }
          final acc = state.bankData;
          if (acc != null && !_filled) {
            _filled = true;
            _bank.text = acc.bankName;
            _holder.text = acc.holderName;
            _type = _types.containsKey(acc.accountType) ? acc.accountType : 'ahorros';
          }
          final showForm = acc == null || _editing;
          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _summary(state),
                const SizedBox(height: 20),
                if (!showForm) _accountCard(acc),
                if (showForm) _form(context, acc != null),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _summary(BankDataLoaded s) => Container(
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: AppColors.primary.withValues(alpha: 0.08),
      borderRadius: BorderRadius.circular(12),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Ventas de los últimos 30 días', style: TextStyle(color: AppColors.textSecondary)),
        const SizedBox(height: 4),
        Text(
          formatCop(s.totalSales),
          style: const TextStyle(fontSize: 26, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
        ),
        const SizedBox(height: 4),
        Text('${s.deliveredOrders} pedidos entregados', style: const TextStyle(color: AppColors.textSecondary)),
        const SizedBox(height: 8),
        const Text(
          'Tus clientes te pagan directamente por Bre-B, Nequi o en efectivo; no hay saldo retenido en UniMarket.',
          style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
        ),
      ],
    ),
  );

  Widget _accountCard(BankDataModel acc) => Card(
    elevation: 0,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(12),
      side: BorderSide(color: Colors.grey.shade300),
    ),
    child: Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.account_balance_outlined, color: AppColors.primary),
              const SizedBox(width: 8),
              Expanded(
                child: Text(acc.bankName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              ),
              Chip(
                label: Text(acc.isVerified ? 'Verificada' : 'En revisión'),
                backgroundColor: acc.isVerified ? Colors.green.shade50 : Colors.orange.shade50,
                visualDensity: VisualDensity.compact,
              ),
            ],
          ),
          const SizedBox(height: 12),
          _row('Tipo', _types[acc.accountType] ?? acc.accountType),
          _row('Número', acc.accountNumberMasked),
          _row('Titular', acc.holderName),
          const SizedBox(height: 12),
          OutlinedButton.icon(
            onPressed: () => setState(() => _editing = true),
            icon: const Icon(Icons.edit_outlined),
            label: const Text('Cambiar cuenta'),
          ),
        ],
      ),
    ),
  );

  Widget _row(String k, String v) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 4),
    child: Row(
      children: [
        SizedBox(width: 80, child: Text(k, style: const TextStyle(color: AppColors.textSecondary))),
        Expanded(child: Text(v, style: const TextStyle(fontWeight: FontWeight.w500))),
      ],
    ),
  );

  Widget _form(BuildContext context, bool hasAccount) {
    final saving = context.watch<BankDataCubit>().state is BankDataSaving;
    String? req(String? v) => (v == null || v.trim().length < 2) ? 'Campo obligatorio' : null;
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            hasAccount ? 'Actualizar cuenta' : 'Registra dónde recibes tus pagos',
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          DropdownButtonFormField<String>(
            initialValue: _type,
            decoration: const InputDecoration(labelText: 'Tipo de cuenta', border: OutlineInputBorder()),
            items: [for (final e in _types.entries) DropdownMenuItem(value: e.key, child: Text(e.value))],
            onChanged: (v) => setState(() => _type = v ?? 'ahorros'),
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: _bank,
            decoration: const InputDecoration(labelText: 'Banco o billetera', border: OutlineInputBorder()),
            validator: req,
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: _number,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(labelText: 'Número de cuenta o celular', border: OutlineInputBorder()),
            validator: (v) {
              final d = (v ?? '').replaceAll(RegExp(r'\D'), '');
              return d.length < 6 || d.length > 20 ? 'Escribe entre 6 y 20 dígitos' : null;
            },
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: _holder,
            decoration: const InputDecoration(labelText: 'Titular', border: OutlineInputBorder()),
            validator: req,
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: _document,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(labelText: 'Cédula del titular', border: OutlineInputBorder()),
            validator: (v) {
              final d = (v ?? '').replaceAll(RegExp(r'\D'), '');
              return d.length < 5 || d.length > 15 ? 'Cédula no válida' : null;
            },
          ),
          const SizedBox(height: 8),
          const Text(
            'El número se guarda cifrado; solo verás los últimos 4 dígitos.',
            style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
          ),
          const SizedBox(height: 16),
          FilledButton(
            onPressed: saving ? null : _save,
            child: Text(saving ? 'Guardando…' : 'Guardar cuenta'),
          ),
          if (hasAccount)
            TextButton(onPressed: () => setState(() => _editing = false), child: const Text('Cancelar')),
        ],
      ),
    );
  }
}
