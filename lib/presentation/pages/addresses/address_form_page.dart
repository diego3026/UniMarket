import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../../../constants/app_colors.dart';
import '../../../core/router/app_routes.dart';
import '../../viewmodels/addresses/addresses_cubit.dart';
import '../../viewmodels/addresses/addresses_state.dart';

/// Crear o editar una dirección, con ubicación opcional en Google Maps.
class AddressFormPage extends StatefulWidget {
  final AddressModel? initial;
  const AddressFormPage({super.key, this.initial});

  @override
  State<AddressFormPage> createState() => _AddressFormPageState();
}

class _AddressFormPageState extends State<AddressFormPage> {
  final _form = GlobalKey<FormState>();
  late final _label = TextEditingController(text: widget.initial?.label);
  late final _address = TextEditingController(text: widget.initial?.address);
  late final _details = TextEditingController(text: widget.initial?.postalCode);
  late final _city = TextEditingController(text: widget.initial?.city ?? 'Santa Marta');
  late LatLng? _point = widget.initial?.latitude == null
      ? null
      : LatLng(widget.initial!.latitude!, widget.initial!.longitude!);
  bool _saving = false;

  @override
  void dispose() {
    for (final c in [_label, _address, _details, _city]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _pick() async {
    final p = await context.push<LatLng>(AppRoutes.mapAddress, extra: _point);
    if (p != null) setState(() => _point = p);
  }

  Future<void> _save() async {
    if (!_form.currentState!.validate()) return;
    setState(() => _saving = true);
    final cubit = context.read<AddressesCubit>();
    final err = widget.initial == null
        ? await cubit.addAddress(
            label: _label.text,
            address: _address.text,
            city: _city.text,
            postalCode: _details.text,
            latitude: _point?.latitude,
            longitude: _point?.longitude,
          )
        : await cubit.updateAddress(
            id: widget.initial!.id,
            label: _label.text,
            address: _address.text,
            city: _city.text,
            postalCode: _details.text,
            latitude: _point?.latitude,
            longitude: _point?.longitude,
          );
    if (!mounted) return;
    setState(() => _saving = false);
    if (err != null) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(err)));
      return;
    }
    context.pop(true);
  }

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    String? req(String? v) => (v == null || v.trim().length < 2) ? 'Campo obligatorio' : null;
    return Scaffold(
      appBar: AppBar(title: Text(widget.initial == null ? 'Nueva dirección' : 'Editar dirección')),
      body: Form(
        key: _form,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            InkWell(
              onTap: _pick,
              borderRadius: BorderRadius.circular(14),
              child: Container(
                height: 160,
                clipBehavior: Clip.antiAlias,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: _point == null ? AppColors.border : AppColors.primary),
                  color: AppColors.lightPanel,
                ),
                child: _point == null
                    ? const Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.add_location_alt_rounded, size: 36, color: AppColors.primary),
                          SizedBox(height: 6),
                          Text('Marcar en el mapa'),
                          Text(
                            'Opcional · ayuda a que te encuentren',
                            style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
                          ),
                        ],
                      )
                    : AbsorbPointer(
                        child: GoogleMap(
                          key: ValueKey(_point),
                          initialCameraPosition: CameraPosition(target: _point!, zoom: 16),
                          markers: {Marker(markerId: const MarkerId('p'), position: _point!)},
                          liteModeEnabled: true,
                          zoomControlsEnabled: false,
                          mapToolbarEnabled: false,
                        ),
                      ),
              ),
            ),
            if (_point != null)
              Row(
                children: [
                  const Icon(Icons.check_circle_rounded, size: 16, color: AppColors.success),
                  const SizedBox(width: 6),
                  Expanded(child: Text('Ubicación marcada', style: t.bodySmall)),
                  TextButton(onPressed: _pick, child: const Text('Cambiar')),
                  TextButton(onPressed: () => setState(() => _point = null), child: const Text('Quitar')),
                ],
              ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _label,
              textCapitalization: TextCapitalization.sentences,
              decoration: const InputDecoration(labelText: 'Nombre', hintText: 'Casa, Apartamento, Trabajo'),
              validator: req,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _address,
              decoration: const InputDecoration(labelText: 'Dirección', hintText: 'Cra 32 #22-08'),
              validator: req,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _details,
              decoration: const InputDecoration(
                labelText: 'Detalles (opcional)',
                hintText: 'Apto 302, torre B, portería',
              ),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _city,
              decoration: const InputDecoration(labelText: 'Ciudad'),
              validator: req,
            ),
            const SizedBox(height: 24),
            FilledButton(
              onPressed: _saving ? null : _save,
              child: Text(_saving ? 'Guardando…' : 'Guardar dirección'),
            ),
          ],
        ),
      ),
    );
  }
}
