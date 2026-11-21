import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../constants/app_colors.dart';
import '../../../core/router/app_routes.dart';
import '../../../core/theme/app_theme.dart';
import '../../../data/datasources/mock/market_mock_data.dart';
import '../../../domain/entities/market_entities.dart';
import '../../viewmodels/market/market_cubits.dart';
import '../../widgets/ui/app_widgets.dart';
import '../../widgets/ui/campus_map.dart';
import 'seller_mock.dart';

/// Configuración de la tienda: dónde recogen los clientes, si hace
/// domicilios, costos, tiempo de preparación y medios de pago.
/// Todo esto es lo que el cliente ve al finalizar su compra.
class StoreSettingsPage extends StatefulWidget {
  const StoreSettingsPage({super.key});

  @override
  State<StoreSettingsPage> createState() => _StoreSettingsPageState();
}

class _StoreSettingsPageState extends State<StoreSettingsPage> {
  late StoreSettings _s = context.read<StoreSettingsCubit>().of(
    SellerMock.store.id,
  );
  late final _notes = TextEditingController(text: _s.pickupNotes);
  late final _fee = TextEditingController(
    text: _s.deliveryFee.round().toString(),
  );
  late final _min = TextEditingController(
    text: _s.minOrder == 0 ? '' : _s.minOrder.round().toString(),
  );
  late final _phone = TextEditingController(text: _s.phone);

  @override
  void dispose() {
    for (final c in [_notes, _fee, _min, _phone]) {
      c.dispose();
    }
    super.dispose();
  }

  void _save() {
    if (!_s.allowsDelivery && !_s.allowsPickup) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Activa al menos domicilio o recoger en tienda'),
        ),
      );
      return;
    }
    if (!_s.acceptsCash && !_s.acceptsNequi && !_s.acceptsCard) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Elige al menos un medio de pago')),
      );
      return;
    }
    context.read<StoreSettingsCubit>().update(
      _s.copyWith(
        pickupNotes: _notes.text.trim(),
        deliveryFee: double.tryParse(_fee.text) ?? 0,
        minOrder: double.tryParse(_min.text) ?? 0,
        phone: _phone.text.trim(),
      ),
    );
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Configuración guardada')));
    context.pop();
  }

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    final place = MarketMockData.place(_s.pickupPlaceId);

    Widget section(String title, String subtitle, List<Widget> children) =>
        Padding(
          padding: const EdgeInsets.only(bottom: 16),
          child: SurfaceCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: t.titleMedium),
                Text(subtitle, style: t.bodySmall),
                const SizedBox(height: 12),
                ...children,
              ],
            ),
          ),
        );

    return Scaffold(
      appBar: AppBar(title: const Text('Configurar tienda')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(
          AppTheme.pagePadding,
          0,
          AppTheme.pagePadding,
          32,
        ),
        children: [
          section(
            'Punto de recogida',
            'Aquí te encuentran los clientes que eligen "Ir a recoger".',
            [
              CampusMap(
                height: 190,
                selectedPlaceId: _s.pickupPlaceId,
                pins: [
                  MapPin(
                    placeId: _s.pickupPlaceId,
                    icon: Icons.storefront_rounded,
                    color: AppColors.seller,
                    label: SellerMock.store.name,
                  ),
                ],
                onPlaceTap: (p) =>
                    setState(() => _s = _s.copyWith(pickupPlaceId: p.id)),
              ),
              const SizedBox(height: 10),
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(
                  Icons.place_rounded,
                  color: AppColors.seller,
                ),
                title: Text(place.name),
                subtitle: Text(place.hint),
                trailing: TextButton(
                  onPressed: () async {
                    final p = await showCampusPlacePicker(
                      context,
                      title: '¿Dónde te recogen?',
                      selectedId: _s.pickupPlaceId,
                    );
                    if (p != null) {
                      setState(() => _s = _s.copyWith(pickupPlaceId: p.id));
                    }
                  },
                  child: const Text('Cambiar'),
                ),
              ),
              TextField(
                controller: _notes,
                maxLines: 2,
                textCapitalization: TextCapitalization.sentences,
                decoration: const InputDecoration(
                  labelText: 'Indicaciones para encontrarte',
                  hintText: 'Ej. Carrito amarillo frente a la cafetería',
                ),
              ),
            ],
          ),
          section(
            'Formas de entrega',
            'Elige cómo reciben tus clientes los pedidos.',
            [
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                secondary: const Icon(Icons.storefront_rounded),
                title: const Text('Recoger en mi punto'),
                subtitle: const Text('Gratis para el cliente'),
                value: _s.allowsPickup,
                onChanged: (v) =>
                    setState(() => _s = _s.copyWith(allowsPickup: v)),
              ),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                secondary: const Icon(Icons.delivery_dining_rounded),
                title: const Text('Domicilio dentro del campus'),
                value: _s.allowsDelivery,
                onChanged: (v) =>
                    setState(() => _s = _s.copyWith(allowsDelivery: v)),
              ),
              if (_s.allowsDelivery)
                Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _fee,
                          keyboardType: TextInputType.number,
                          inputFormatters: [
                            FilteringTextInputFormatter.digitsOnly,
                          ],
                          decoration: const InputDecoration(
                            labelText: 'Costo del domicilio',
                            prefixText: '\$ ',
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: TextField(
                          controller: _min,
                          keyboardType: TextInputType.number,
                          inputFormatters: [
                            FilteringTextInputFormatter.digitsOnly,
                          ],
                          decoration: const InputDecoration(
                            labelText: 'Pedido mínimo',
                            prefixText: '\$ ',
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              const SizedBox(height: 12),
              Row(
                children: [
                  const Icon(
                    Icons.timer_outlined,
                    color: AppColors.textSecondary,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text('Tiempo de preparación', style: t.bodyMedium),
                  ),
                  QuantityStepper(
                    value: _s.prepMinutes,
                    onIncrement: () => setState(
                      () => _s = _s.copyWith(prepMinutes: _s.prepMinutes + 5),
                    ),
                    onDecrement: () => setState(
                      () => _s = _s.copyWith(
                        prepMinutes: (_s.prepMinutes - 5).clamp(5, 120),
                      ),
                    ),
                  ),
                  const SizedBox(width: 6),
                  const Text('min'),
                ],
              ),
            ],
          ),
          section(
            'Medios de pago que recibes',
            'El cliente solo verá estos al pagar.',
            [
              CheckboxListTile(
                contentPadding: EdgeInsets.zero,
                secondary: const Icon(
                  Icons.payments_rounded,
                  color: AppColors.success,
                ),
                title: const Text('Efectivo'),
                value: _s.acceptsCash,
                onChanged: (v) =>
                    setState(() => _s = _s.copyWith(acceptsCash: v)),
              ),
              CheckboxListTile(
                contentPadding: EdgeInsets.zero,
                secondary: const Icon(
                  Icons.phone_iphone_rounded,
                  color: Color(0xFFDA0081),
                ),
                title: const Text('Nequi'),
                value: _s.acceptsNequi,
                onChanged: (v) =>
                    setState(() => _s = _s.copyWith(acceptsNequi: v)),
              ),
              CheckboxListTile(
                contentPadding: EdgeInsets.zero,
                secondary: const Icon(
                  Icons.credit_card_rounded,
                  color: AppColors.info,
                ),
                title: const Text('Tarjeta débito o crédito'),
                value: _s.acceptsCard,
                onChanged: (v) =>
                    setState(() => _s = _s.copyWith(acceptsCard: v)),
              ),
            ],
          ),
          section(
            'Contacto',
            'Para que el cliente te llame si necesita algo.',
            [
              TextField(
                controller: _phone,
                keyboardType: TextInputType.phone,
                decoration: const InputDecoration(
                  labelText: 'Celular',
                  prefixText: '+57 ',
                ),
              ),
            ],
          ),
          SurfaceCard(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Column(
              children: [
                MenuTile(
                  icon: Icons.schedule_rounded,
                  title: 'Horario de atención',
                  onTap: () => context.push(AppRoutes.sellerSchedule),
                ),
                MenuTile(
                  icon: Icons.local_offer_outlined,
                  title: 'Promociones y cupones',
                  onTap: () => context.go(AppRoutes.sellerPromos),
                ),
                MenuTile(
                  icon: Icons.account_balance_outlined,
                  title: 'Datos bancarios',
                  onTap: () => context.push(AppRoutes.sellerBank),
                ),
              ],
            ),
          ),
        ],
      ),
      bottomNavigationBar: BottomActionBar(
        child: FilledButton(
          onPressed: _save,
          child: const Text('Guardar cambios'),
        ),
      ),
    );
  }
}
