import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../constants/app_colors.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../viewmodels/market/market_cubits.dart';
import '../../../widgets/ui/app_widgets.dart';
import '../../../widgets/ui/payment_widgets.dart';

/// Billetera del cliente (Figma: "Mis métodos de pago").
/// Lo que se guarda aquí es lo que aparece al finalizar la compra.
class SavedPaymentMethodsPage extends StatefulWidget {
  const SavedPaymentMethodsPage({super.key});

  @override
  State<SavedPaymentMethodsPage> createState() =>
      _SavedPaymentMethodsPageState();
}

class _SavedPaymentMethodsPageState extends State<SavedPaymentMethodsPage> {
  final _pager = PageController(viewportFraction: 0.86);
  int _index = 0;

  @override
  void dispose() {
    _pager.dispose();
    super.dispose();
  }

  Future<void> _editNequi(BuildContext context, String current) async {
    final c = TextEditingController(text: current);
    final v = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Número de Nequi'),
        content: TextField(
          controller: c,
          keyboardType: TextInputType.phone,
          decoration: const InputDecoration(prefixText: '+57 '),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(minimumSize: const Size(0, 44)),
            onPressed: () => Navigator.pop(ctx, c.text.trim()),
            child: const Text('Guardar'),
          ),
        ],
      ),
    );
    if (v != null && v.isNotEmpty && context.mounted) {
      context.read<WalletCubit>().setNequi(v);
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    return BlocBuilder<WalletCubit, WalletState>(
      builder: (context, w) {
        final cards = w.cards;
        if (_index >= cards.length && cards.isNotEmpty) {
          _index = cards.length - 1;
        }
        final current = cards.isEmpty ? null : cards[_index];
        return Scaffold(
          appBar: AppBar(
            actions: [
              TextButton.icon(
                onPressed: () => showAddCardSheet(context),
                icon: const Icon(Icons.add_circle_outline_rounded),
                label: const Text('Agregar'),
              ),
            ],
          ),
          body: ListView(
            padding: const EdgeInsets.only(bottom: 32),
            children: [
              const PageTitle(title: 'Mis métodos de pago'),
              if (cards.isEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppTheme.pagePadding,
                  ),
                  child: SurfaceCard(
                    onTap: () => showAddCardSheet(context),
                    child: const Column(
                      children: [
                        Icon(
                          Icons.add_card_rounded,
                          size: 40,
                          color: AppColors.primary,
                        ),
                        SizedBox(height: 8),
                        Text('Agrega una tarjeta para pagar más rápido'),
                      ],
                    ),
                  ),
                )
              else ...[
                SizedBox(
                  height: 200,
                  child: PageView.builder(
                    controller: _pager,
                    itemCount: cards.length,
                    onPageChanged: (i) => setState(() => _index = i),
                    itemBuilder: (_, i) => Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 8,
                      ),
                      child: LayoutBuilder(
                        builder: (_, c) => Center(
                          child: CreditCardView.fromCard(
                            cards[i],
                            width: c.maxWidth < c.maxHeight / 0.6
                                ? c.maxWidth
                                : c.maxHeight / 0.6,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(
                    cards.length,
                    (i) => AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      margin: const EdgeInsets.symmetric(horizontal: 3),
                      width: i == _index ? 18 : 6,
                      height: 6,
                      decoration: BoxDecoration(
                        color: i == _index
                            ? AppColors.primary
                            : AppColors.border,
                        borderRadius: BorderRadius.circular(999),
                      ),
                    ),
                  ),
                ),
                if (current != null)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(
                      AppTheme.pagePadding,
                      12,
                      AppTheme.pagePadding,
                      0,
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: current.isDefault
                              ? const StatusChip(
                                  label: 'Predeterminada para pagar',
                                  color: AppColors.success,
                                )
                              : OutlinedButton.icon(
                                  onPressed: () => context
                                      .read<WalletCubit>()
                                      .setDefault(current.id),
                                  icon: const Icon(
                                    Icons.check_rounded,
                                    size: 18,
                                  ),
                                  label: const Text('Usar por defecto'),
                                ),
                        ),
                        const SizedBox(width: 10),
                        TextButton.icon(
                          style: TextButton.styleFrom(
                            foregroundColor: AppColors.danger,
                          ),
                          onPressed: () async {
                            final ok = await showDialog<bool>(
                              context: context,
                              builder: (ctx) => AlertDialog(
                                title: Text(
                                  '¿Eliminar ${current.brand} •••• ${current.last4}?',
                                ),
                                content: const Text(
                                  'Podrás volver a agregarla cuando quieras.',
                                ),
                                actions: [
                                  TextButton(
                                    onPressed: () => Navigator.pop(ctx, false),
                                    child: const Text('Conservar'),
                                  ),
                                  FilledButton(
                                    style: FilledButton.styleFrom(
                                      backgroundColor: AppColors.danger,
                                      minimumSize: const Size(0, 44),
                                    ),
                                    onPressed: () => Navigator.pop(ctx, true),
                                    child: const Text('Eliminar tarjeta'),
                                  ),
                                ],
                              ),
                            );
                            if (ok == true && context.mounted) {
                              context.read<WalletCubit>().remove(current.id);
                            }
                          },
                          icon: const Icon(Icons.delete_outline_rounded),
                          label: const Text('Eliminar'),
                        ),
                      ],
                    ),
                  ),
              ],
              const SizedBox(height: 24),
              const SectionHeader(title: 'Otros medios'),
              const SizedBox(height: 8),
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppTheme.pagePadding,
                ),
                child: SurfaceCard(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Column(
                    children: [
                      MenuTile(
                        icon: Icons.phone_iphone_rounded,
                        color: const Color(0xFFDA0081),
                        title: 'Nequi',
                        subtitle: w.nequiPhone,
                        trailing: const Icon(
                          Icons.edit_outlined,
                          color: AppColors.textMuted,
                        ),
                        onTap: () => _editNequi(context, w.nequiPhone),
                      ),
                      const MenuTile(
                        icon: Icons.payments_rounded,
                        color: AppColors.success,
                        title: 'Efectivo',
                        subtitle: 'Pagas al recibir o al recoger tu pedido',
                        trailing: SizedBox.shrink(),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppTheme.pagePadding,
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.info_outline_rounded,
                      size: 16,
                      color: AppColors.textSecondary,
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        'Al pagar solo verás los medios que acepta cada emprendimiento.',
                        style: t.bodySmall,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
