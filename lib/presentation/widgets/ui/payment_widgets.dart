import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../constants/app_colors.dart';
import '../../../domain/entities/market_entities.dart';
import '../../viewmodels/market/market_cubits.dart';

/// Tarjeta de crédito/débito dibujada (Figma: "Mis métodos de pago").
class CreditCardView extends StatelessWidget {
  final String brand;
  final String number;
  final String holder;
  final String expiry;
  final bool isDefault;
  final double width;

  const CreditCardView({
    super.key,
    required this.brand,
    required this.number,
    required this.holder,
    required this.expiry,
    this.isDefault = false,
    this.width = 300,
  });

  factory CreditCardView.fromCard(PaymentCard c, {double width = 300}) =>
      CreditCardView(
        brand: c.brand,
        number: '•••• •••• •••• ${c.last4}',
        holder: c.holder,
        expiry: c.expiry,
        isDefault: c.isDefault,
        width: width,
      );

  static List<Color> gradientFor(String brand) => switch (brand) {
    'Visa' => const [Color(0xFF8E1F6B), Color(0xFFE0245E)],
    'Mastercard' => const [Color(0xFF1C1B22), Color(0xFF4320A2)],
    'Amex' => const [Color(0xFF0F766E), Color(0xFF14B8A6)],
    _ => const [Color(0xFF4320A2), Color(0xFF7C5CFA)],
  };

  @override
  Widget build(BuildContext context) {
    // La tarjeta es un gráfico de proporción fija: no escala con el texto.
    return MediaQuery.withNoTextScaling(child: _card());
  }

  Widget _card() {
    return Container(
      width: width,
      height: width * 0.6,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: gradientFor(brand),
        ),
        boxShadow: [
          BoxShadow(
            color: gradientFor(brand).last.withValues(alpha: 0.35),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Stack(
        children: [
          Positioned(
            right: -40,
            top: -50,
            child: Container(
              width: 160,
              height: 160,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withValues(alpha: 0.08),
              ),
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      isDefault ? 'Predeterminada' : 'Tarjeta',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  Text(
                    brand.toUpperCase(),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.w900,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ],
              ),
              const Spacer(),
              FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerLeft,
                child: Text(
                  number.isEmpty ? '•••• •••• •••• ••••' : number,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 19,
                    letterSpacing: 2,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      holder.isEmpty ? 'NOMBRE EN LA TARJETA' : holder,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  Text(
                    expiry.isEmpty ? 'MM/AA' : expiry,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Hoja para agregar una tarjeta con vista previa en vivo.
Future<void> showAddCardSheet(BuildContext context) {
  return showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    builder: (ctx) => const _AddCardSheet(),
  );
}

class _AddCardSheet extends StatefulWidget {
  const _AddCardSheet();

  @override
  State<_AddCardSheet> createState() => _AddCardSheetState();
}

class _AddCardSheetState extends State<_AddCardSheet> {
  final _form = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _number = TextEditingController();
  final _exp = TextEditingController();
  final _cvv = TextEditingController();

  @override
  void dispose() {
    for (final c in [_name, _number, _exp, _cvv]) {
      c.dispose();
    }
    super.dispose();
  }

  String get _brand {
    final d = _number.text.replaceAll(' ', '');
    if (d.startsWith('4')) return 'Visa';
    if (d.startsWith('5')) return 'Mastercard';
    if (d.startsWith('3')) return 'Amex';
    return 'Tarjeta';
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(
        20,
        0,
        20,
        MediaQuery.of(context).viewInsets.bottom + 20,
      ),
      child: Form(
        key: _form,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Agregar tarjeta',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 14),
              Center(
                child: CreditCardView(
                  brand: _brand,
                  number: _number.text,
                  holder: _name.text.toUpperCase(),
                  expiry: _exp.text,
                  width: 280,
                ),
              ),
              const SizedBox(height: 18),
              TextFormField(
                controller: _name,
                textCapitalization: TextCapitalization.characters,
                decoration: const InputDecoration(
                  labelText: 'Nombre en la tarjeta',
                ),
                onChanged: (_) => setState(() {}),
                validator: (v) => (v ?? '').trim().length < 3
                    ? 'Escribe el nombre como aparece en la tarjeta'
                    : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _number,
                keyboardType: TextInputType.number,
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                  _CardNumberFormatter(),
                ],
                decoration: const InputDecoration(
                  labelText: 'Número de tarjeta',
                  prefixIcon: Icon(Icons.credit_card_rounded),
                ),
                onChanged: (_) => setState(() {}),
                validator: (v) => (v ?? '').replaceAll(' ', '').length < 15
                    ? 'Revisa el número de la tarjeta'
                    : null,
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _exp,
                      keyboardType: TextInputType.number,
                      inputFormatters: [
                        FilteringTextInputFormatter.digitsOnly,
                        _ExpiryFormatter(),
                      ],
                      decoration: const InputDecoration(
                        labelText: 'Vence (MM/AA)',
                      ),
                      onChanged: (_) => setState(() {}),
                      validator: (v) =>
                          RegExp(r'^(0[1-9]|1[0-2])/\d{2}$').hasMatch(v ?? '')
                          ? null
                          : 'MM/AA',
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextFormField(
                      controller: _cvv,
                      keyboardType: TextInputType.number,
                      obscureText: true,
                      inputFormatters: [
                        FilteringTextInputFormatter.digitsOnly,
                        LengthLimitingTextInputFormatter(4),
                      ],
                      decoration: const InputDecoration(
                        labelText: 'Código de seguridad',
                      ),
                      validator: (v) =>
                          (v ?? '').length < 3 ? '3 o 4 dígitos' : null,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              const Row(
                children: [
                  Icon(
                    Icons.lock_outline_rounded,
                    size: 16,
                    color: AppColors.success,
                  ),
                  SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      'Solo guardamos los últimos 4 dígitos. El código de seguridad nunca se almacena.',
                      style: TextStyle(
                        fontSize: 12,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              FilledButton(
                onPressed: () {
                  if (!_form.currentState!.validate()) return;
                  context.read<WalletCubit>().addCard(
                    number: _number.text,
                    holder: _name.text,
                    expiry: _exp.text,
                  );
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Tarjeta agregada')),
                  );
                },
                child: const Text('Guardar tarjeta'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CardNumberFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final d = newValue.text.replaceAll(' ', '');
    final capped = d.length > 16 ? d.substring(0, 16) : d;
    final b = StringBuffer();
    for (var i = 0; i < capped.length; i++) {
      if (i > 0 && i % 4 == 0) b.write(' ');
      b.write(capped[i]);
    }
    final t = b.toString();
    return TextEditingValue(
      text: t,
      selection: TextSelection.collapsed(offset: t.length),
    );
  }
}

class _ExpiryFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final d = newValue.text.replaceAll('/', '');
    final capped = d.length > 4 ? d.substring(0, 4) : d;
    final t = capped.length > 2
        ? '${capped.substring(0, 2)}/${capped.substring(2)}'
        : capped;
    return TextEditingValue(
      text: t,
      selection: TextSelection.collapsed(offset: t.length),
    );
  }
}

/// Hoja para elegir cómo pagar, solo con los medios que acepta la tienda.
Future<PaymentChoice?> showPaymentPicker(
  BuildContext context, {
  required StoreSettings settings,
  required FulfillmentMode mode,
  PaymentChoice? current,
}) {
  return showModalBottomSheet<PaymentChoice>(
    context: context,
    isScrollControlled: true,
    builder: (ctx) => BlocBuilder<WalletCubit, WalletState>(
      builder: (ctx, wallet) {
        final t = Theme.of(ctx).textTheme;
        final accent = Theme.of(ctx).colorScheme.primary;
        Widget option({
          required IconData icon,
          required Color color,
          required String title,
          required String subtitle,
          required PaymentChoice choice,
          bool enabled = true,
        }) {
          final sel = current == choice;
          return Opacity(
            opacity: enabled ? 1 : 0.45,
            child: Container(
              margin: const EdgeInsets.only(bottom: 10),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: sel ? accent : AppColors.border,
                  width: sel ? 1.6 : 1,
                ),
                color: sel ? accent.withValues(alpha: 0.05) : AppColors.surface,
              ),
              child: ListTile(
                enabled: enabled,
                onTap: () => Navigator.pop(ctx, choice),
                leading: Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(icon, color: color),
                ),
                title: Text(title),
                subtitle: Text(subtitle),
                trailing: sel
                    ? Icon(Icons.check_circle_rounded, color: accent)
                    : null,
              ),
            ),
          );
        }

        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text('¿Cómo quieres pagar?', style: t.titleLarge),
                const SizedBox(height: 4),
                Text(
                  'Solo se muestran los medios que acepta este emprendimiento.',
                  style: t.bodySmall,
                ),
                const SizedBox(height: 16),
                option(
                  icon: Icons.payments_rounded,
                  color: AppColors.success,
                  title: mode == FulfillmentMode.pickup
                      ? 'Efectivo al recoger'
                      : 'Efectivo contra entrega',
                  subtitle: settings.acceptsCash
                      ? 'Pagas cuando recibes tu pedido'
                      : 'No disponible en esta tienda',
                  choice: const PaymentChoice.cash(),
                  enabled: settings.acceptsCash,
                ),
                option(
                  icon: Icons.phone_iphone_rounded,
                  color: const Color(0xFFDA0081),
                  title: 'Nequi',
                  subtitle: settings.acceptsNequi
                      ? 'Te llega una notificación al ${wallet.nequiPhone}'
                      : 'No disponible en esta tienda',
                  choice: const PaymentChoice.nequi(),
                  enabled: settings.acceptsNequi,
                ),
                for (final c in wallet.cards)
                  option(
                    icon: Icons.credit_card_rounded,
                    color: CreditCardView.gradientFor(c.brand).last,
                    title: '${c.brand} •••• ${c.last4}',
                    subtitle: settings.acceptsCard
                        ? 'Vence ${c.expiry}${c.isDefault ? ' · Predeterminada' : ''}'
                        : 'Esta tienda no recibe tarjeta',
                    choice: PaymentChoice.card(c),
                    enabled: settings.acceptsCard,
                  ),
                if (settings.acceptsCard)
                  TextButton.icon(
                    onPressed: () => showAddCardSheet(ctx),
                    icon: const Icon(Icons.add_card_rounded),
                    label: const Text('Agregar tarjeta'),
                  ),
              ],
            ),
          ),
        );
      },
    ),
  );
}
