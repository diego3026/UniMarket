import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart' show LatLng;

import '../../../../constants/app_colors.dart';
import '../../../../core/injection_container.dart';
import '../../../../domain/entities/market_entities.dart';
import '../../../viewmodels/admin/admin_places_cubit.dart';
import '../../../widgets/ui/uni_map.dart';
import '../../addresses/location_picker_page.dart';

/// Admin: pines del mapa para guiar a clientes y emprendedores.
/// Mantén presionado el mapa para crear un pin en ese punto.
class MapPinsPage extends StatelessWidget {
  const MapPinsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => AdminPlacesCubit(sl())..load(),
      child: const _MapPinsView(),
    );
  }
}

class _MapPinsView extends StatefulWidget {
  const _MapPinsView();
  @override
  State<_MapPinsView> createState() => _MapPinsViewState();
}

class _MapPinsViewState extends State<_MapPinsView> {
  String? _selected;

  Future<void> _edit(CampusPlace? place, {LatLng? at}) async {
    final cubit = context.read<AdminPlacesCubit>();
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => BlocProvider.value(
          value: cubit,
          child: PinFormPage(initial: place, at: at),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    return Scaffold(
      appBar: AppBar(title: const Text('Pines del mapa')),
      floatingActionButton: FloatingActionButton.extended(
        heroTag: null,
        onPressed: () => _edit(null),
        icon: const Icon(Icons.add_location_alt_rounded),
        label: const Text('Nuevo pin'),
      ),
      body: BlocBuilder<AdminPlacesCubit, AdminPlacesState>(
        builder: (context, state) {
          final active = state.places.where((p) => p.isActive).toList();
          final inactive = state.places.where((p) => !p.isActive).toList();
          return RefreshIndicator(
            onRefresh: () => context.read<AdminPlacesCubit>().load(),
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 100),
              children: [
                UniMap(
                  height: 300,
                  places: active,
                  selectedPlaceId: _selected,
                  onPlaceTap: (p) => setState(() => _selected = p.id),
                  onLongPress: (at) => _edit(null, at: at),
                ),
                const SizedBox(height: 6),
                Text(
                  'Mantén presionado el mapa para crear un pin ahí. Toca un pin para resaltarlo.',
                  style: t.bodySmall,
                ),
                if (state.error != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 12),
                    child: Text(
                      state.error!,
                      style: const TextStyle(color: AppColors.danger),
                    ),
                  ),
                if (state.loading && state.places.isEmpty)
                  const Padding(
                    padding: EdgeInsets.all(32),
                    child: Center(child: CircularProgressIndicator()),
                  ),
                const SizedBox(height: 12),
                for (final p in [...active, ...inactive])
                  Card(
                    elevation: 0,
                    color: p.id == _selected
                        ? AppColors.lightPanel
                        : Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                      side: const BorderSide(color: AppColors.border),
                    ),
                    child: ListTile(
                      onTap: () => _edit(p),
                      leading: Icon(
                        p.isDeliveryPoint
                            ? Icons.local_shipping_outlined
                            : Icons.place_outlined,
                        color: !p.isActive
                            ? AppColors.textMuted
                            : p.isDeliveryPoint
                            ? AppColors.success
                            : AppColors.primary,
                      ),
                      title: Text(
                        p.name,
                        style: TextStyle(
                          color: p.isActive ? null : AppColors.textMuted,
                        ),
                      ),
                      subtitle: Text(
                        [
                          p.kind.label,
                          if (p.isDeliveryPoint) 'punto de entrega',
                          if (!p.hasLocation) 'sin ubicación',
                          if (!p.isActive) 'desactivado',
                        ].join(' · '),
                      ),
                      trailing: const Icon(Icons.chevron_right_rounded),
                    ),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }
}

/// Crear o editar un pin.
class PinFormPage extends StatefulWidget {
  final CampusPlace? initial;
  final LatLng? at;
  const PinFormPage({super.key, this.initial, this.at});

  @override
  State<PinFormPage> createState() => _PinFormPageState();
}

class _PinFormPageState extends State<PinFormPage> {
  final _form = GlobalKey<FormState>();
  late final _name = TextEditingController(text: widget.initial?.name);
  late final _hint = TextEditingController(text: widget.initial?.hint);
  late final _description = TextEditingController(
    text: widget.initial?.description,
  );
  late PlaceKind _kind = widget.initial?.kind ?? PlaceKind.building;
  late bool _delivery = widget.initial?.isDeliveryPoint ?? false;
  late bool _active = widget.initial?.isActive ?? true;
  late LatLng? _point =
      widget.at ??
      (widget.initial?.hasLocation == true
          ? LatLng(widget.initial!.latitude!, widget.initial!.longitude!)
          : null);
  bool _saving = false;

  @override
  void dispose() {
    for (final c in [_name, _hint, _description]) {
      c.dispose();
    }
    super.dispose();
  }

  void _snack(String m) =>
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(m)));

  Future<void> _pick() async {
    final p = await Navigator.of(context).push<LatLng>(
      MaterialPageRoute(
        builder: (_) => LocationPickerPage(initial: _point ?? UniMap.campus),
      ),
    );
    if (p != null) setState(() => _point = p);
  }

  Future<void> _save() async {
    if (!_form.currentState!.validate()) return;
    if (_point == null) return _snack('Marca la ubicación del pin en el mapa');
    setState(() => _saving = true);
    final err = await context.read<AdminPlacesCubit>().save(
      CampusPlace(
        widget.initial?.id ?? '',
        _name.text,
        _hint.text,
        description: _description.text,
        kind: _kind,
        isDeliveryPoint: _delivery,
        latitude: _point!.latitude,
        longitude: _point!.longitude,
        isActive: _active,
      ),
    );
    if (!mounted) return;
    setState(() => _saving = false);
    if (err != null) return _snack(err);
    _snack(widget.initial == null ? 'Pin creado' : 'Pin actualizado');
    Navigator.pop(context);
  }

  Future<void> _remove() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (c) => AlertDialog(
        title: const Text('Quitar pin'),
        content: Text(
          '"${widget.initial!.name}" dejará de verse en el mapa. Los pedidos antiguos lo conservan.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(c, false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: AppColors.danger),
            onPressed: () => Navigator.pop(c, true),
            child: const Text('Quitar pin'),
          ),
        ],
      ),
    );
    if (ok != true || !mounted) return;
    setState(() => _saving = true);
    final err = await context.read<AdminPlacesCubit>().remove(
      widget.initial!.id,
    );
    if (!mounted) return;
    setState(() => _saving = false);
    if (err != null) return _snack(err);
    _snack('Pin quitado');
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    String? req(String? v) =>
        (v == null || v.trim().length < 2) ? 'Escribe el nombre' : null;
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.initial == null ? 'Nuevo pin' : 'Editar pin'),
        actions: [
          if (widget.initial != null && widget.initial!.isActive)
            IconButton(
              tooltip: 'Quitar pin',
              onPressed: _saving ? null : _remove,
              icon: const Icon(
                Icons.delete_outline_rounded,
                color: AppColors.danger,
              ),
            ),
        ],
      ),
      body: Form(
        key: _form,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            if (_point != null)
              UniMap(
                height: 180,
                showGuidePins: false,
                markers: [
                  UniMarker(
                    id: 'pin',
                    latitude: _point!.latitude,
                    longitude: _point!.longitude,
                    title: _name.text.isEmpty ? 'Nuevo pin' : _name.text,
                    hue: UniMap.hueFor(_kind),
                  ),
                ],
              ),
            OutlinedButton.icon(
              onPressed: _pick,
              icon: const Icon(Icons.edit_location_alt_outlined),
              label: Text(
                _point == null ? 'Marcar en el mapa' : 'Cambiar ubicación',
              ),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _name,
              textCapitalization: TextCapitalization.sentences,
              decoration: const InputDecoration(
                labelText: 'Nombre',
                hintText: 'Bloque 8, Entrada principal…',
              ),
              validator: req,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _hint,
              decoration: const InputDecoration(
                labelText: 'Referencia corta',
                hintText: 'Junto a la cafetería',
              ),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _description,
              maxLines: 3,
              maxLength: 500,
              decoration: const InputDecoration(
                labelText: 'Descripción (opcional)',
              ),
            ),
            DropdownButtonFormField<PlaceKind>(
              initialValue: _kind,
              decoration: const InputDecoration(labelText: 'Tipo'),
              items: [
                for (final k in PlaceKind.values)
                  DropdownMenuItem(value: k, child: Text(k.label)),
              ],
              onChanged: (v) => setState(() => _kind = v ?? PlaceKind.building),
            ),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Punto de entrega y recogida'),
              subtitle: const Text(
                'Los clientes pueden pedir que les entreguen aquí y las tiendas usarlo para recoger',
              ),
              value: _delivery,
              onChanged: (v) => setState(() => _delivery = v),
            ),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Visible en el mapa'),
              value: _active,
              onChanged: (v) => setState(() => _active = v),
            ),
            const SizedBox(height: 16),
            FilledButton(
              onPressed: _saving ? null : _save,
              child: Text(_saving ? 'Guardando…' : 'Guardar pin'),
            ),
          ],
        ),
      ),
    );
  }
}
