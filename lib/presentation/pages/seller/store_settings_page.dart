import 'package:unimarket/presentation/viewmodels/catalog/catalog_cubit.dart';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart' show LatLng;
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../constants/app_colors.dart';
import '../../../core/router/app_routes.dart';
import '../../../core/theme/app_theme.dart';
import '../../../domain/entities/market_entities.dart';
import '../../viewmodels/market/market_cubits.dart';
import '../../widgets/ui/app_widgets.dart';
import '../../widgets/ui/place_picker_sheet.dart';
import '../../widgets/ui/uni_map.dart';
import '../addresses/location_picker_page.dart';

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
    Catalog.myStoreOrEmpty.id,
  );
  late final _notes = TextEditingController(text: _s.pickupNotes);
  late final _fee = TextEditingController(
    text: _s.deliveryFee.round().toString(),
  );
  late final _min = TextEditingController(
    text: _s.minOrder == 0 ? '' : _s.minOrder.round().toString(),
  );
  late final _phone = TextEditingController(text: _s.phone);
  late final _nequi = TextEditingController(text: _s.nequiPhone);
  late final _breb = TextEditingController(text: _s.brebKey);
  bool _saving = false;
  late bool _hasLocal = _s.hasLocation;
  late final _address = TextEditingController(text: _s.address);

  Future<void> _pickLocal() async {
    final p = await Navigator.of(context).push<LatLng>(
      MaterialPageRoute(
        builder: (_) => LocationPickerPage(
          initial: _s.hasLocation ? LatLng(_s.latitude!, _s.longitude!) : null,
        ),
      ),
    );
    if (p == null || !mounted) return;
    setState(() {
      _hasLocal = true;
      _s = _s.copyWith(latitude: p.latitude, longitude: p.longitude);
    });
  }

  static final _brebRe = RegExp(r'^(@[A-Za-z0-9._-]{3,40}|3\d{9}|[^@\s]+@[^@\s]+\.[a-z]{2,}|\d{5,15})$');

  @override
  void dispose() {
    for (final c in [_notes, _fee, _min, _phone, _nequi, _breb, _address]) {
      c.dispose();
    }
    super.dispose();
  }

  void _snack(String m) => ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(m)));

  Future<void> _save() async {
    if (!_s.allowsDelivery && !_s.allowsPickup) {
      return _snack('Activa al menos domicilio o recoger en tienda');
    }
    if (!_s.acceptsCash && !_s.acceptsNequi && !_s.acceptsBreb) {
      return _snack('Elige al menos un medio de pago');
    }
    final nequi = _nequi.text.replaceAll(RegExp(r'\D'), '');
    final breb = _breb.text.trim();
    if (_s.acceptsNequi && !RegExp(r'^3\d{9}$').hasMatch(nequi)) {
      return _snack('Escribe el celular de Nequi (10 dígitos, empieza por 3)');
    }
    if (_s.acceptsBreb && !_brebRe.hasMatch(breb)) {
      return _snack('Escribe tu llave Bre-B: @alias, celular, correo o documento');
    }
    setState(() => _saving = true);
    final err = await context.read<StoreSettingsCubit>().update(
      _s.copyWith(
        pickupNotes: _notes.text.trim(),
        deliveryFee: double.tryParse(_fee.text) ?? 0,
        minOrder: double.tryParse(_min.text) ?? 0,
        phone: _phone.text.trim(),
        nequiPhone: nequi,
        brebKey: breb,
        acceptsCard: false,
        address: _hasLocal ? _address.text.trim() : '',
        clearLocation: !_hasLocal,
      ),
    );
    if (!mounted) return;
    setState(() => _saving = false);
    if (err != null) return _snack(err);
    _snack('Configuración guardada');
    context.pop();
  }

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    final place = Catalog.place(_s.pickupPlaceId);

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
              UniMap(
                height: 190,
                deliveryOnly: true,
                selectedPlaceId: _s.pickupPlaceId,
                onPlaceTap: (p) => setState(() => _s = _s.copyWith(pickupPlaceId: p.id)),
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
            'Local físico',
            'Si tienes un local fuera del campus, márcalo para que los clientes lo encuentren en el mapa.',
            [
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Tengo un local físico'),
                value: _hasLocal,
                onChanged: (v) async {
                  if (v && !_s.hasLocation) {
                    await _pickLocal();
                  } else {
                    setState(() {
                      _hasLocal = v;
                      if (!v) _s = _s.copyWith(clearLocation: true);
                    });
                  }
                },
              ),
              if (_hasLocal && _s.hasLocation) ...[
                UniMap(
                  height: 170,
                  showGuidePins: false,
                  markers: [
                    UniMarker(
                      id: 'local',
                      latitude: _s.latitude!,
                      longitude: _s.longitude!,
                      title: Catalog.myStoreOrEmpty.name,
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: _address,
                  decoration: const InputDecoration(
                    labelText: 'Dirección del local',
                    hintText: 'Ej. Calle 29 #5-10, local 3',
                  ),
                ),
                TextButton.icon(
                  onPressed: _pickLocal,
                  icon: const Icon(Icons.edit_location_alt_outlined),
                  label: const Text('Cambiar ubicación'),
                ),
              ],
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
                secondary: const Icon(Icons.bolt_rounded, color: AppColors.primary),
                title: const Text('Transferencia Bre-B'),
                subtitle: const Text('Desde cualquier banco, sin costo'),
                value: _s.acceptsBreb,
                onChanged: (v) => setState(() => _s = _s.copyWith(acceptsBreb: v)),
              ),
              if (_s.acceptsBreb)
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: TextField(
                    controller: _breb,
                    decoration: const InputDecoration(
                      labelText: 'Tu llave Bre-B',
                      hintText: '@mitienda, celular, correo o cédula',
                    ),
                  ),
                ),
              CheckboxListTile(
                contentPadding: EdgeInsets.zero,
                secondary: const Icon(Icons.phone_iphone_rounded, color: Color(0xFFDA0081)),
                title: const Text('Nequi'),
                value: _s.acceptsNequi,
                onChanged: (v) => setState(() => _s = _s.copyWith(acceptsNequi: v)),
              ),
              if (_s.acceptsNequi)
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: TextField(
                    controller: _nequi,
                    keyboardType: TextInputType.phone,
                    decoration: const InputDecoration(labelText: 'Celular de Nequi', prefixText: '+57 '),
                  ),
                ),
              const Padding(
                padding: EdgeInsets.only(top: 4),
                child: Text(
                  'El pago con tarjeta llegará pronto.',
                  style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
                ),
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
                  title: 'Cuenta de pagos',
                  onTap: () => context.push(AppRoutes.sellerBank),
                ),
              ],
            ),
          ),
        ],
      ),
      bottomNavigationBar: BottomActionBar(
        child: FilledButton(
          onPressed: _saving ? null : _save,
          child: Text(_saving ? 'Guardando…' : 'Guardar cambios'),
        ),
      ),
    );
  }
}
