import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:go_router/go_router.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../../../constants/app_colors.dart';

/// Elegir un punto en Google Maps: se mueve el mapa y el pin queda fijo en el
/// centro. Devuelve el [LatLng] elegido (o null si se cancela).
class LocationPickerPage extends StatefulWidget {
  final LatLng? initial;
  const LocationPickerPage({super.key, this.initial});

  /// Universidad del Magdalena, Santa Marta.
  static const campus = LatLng(11.2247, -74.1869);

  @override
  State<LocationPickerPage> createState() => _LocationPickerPageState();
}

class _LocationPickerPageState extends State<LocationPickerPage> {
  GoogleMapController? _map;
  late LatLng _target = widget.initial ?? LocationPickerPage.campus;
  bool _moving = false;
  bool _locating = false;

  @override
  void initState() {
    super.initState();
    // Sin un punto previo, se intenta empezar en la ubicación actual.
    if (widget.initial == null) _goToMe(silent: true);
  }

  void _snack(String m) => ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(m)));

  Future<void> _goToMe({bool silent = false}) async {
    setState(() => _locating = true);
    try {
      if (!await Geolocator.isLocationServiceEnabled()) {
        if (!silent) _snack('Activa la ubicación del celular');
        return;
      }
      var p = await Geolocator.checkPermission();
      if (p == LocationPermission.denied) p = await Geolocator.requestPermission();
      if (p == LocationPermission.denied || p == LocationPermission.deniedForever) {
        if (!silent) {
          _snack(p == LocationPermission.deniedForever
              ? 'Permite la ubicación para UniMarket en los ajustes del celular'
              : 'Sin permiso de ubicación: mueve el mapa hasta tu punto');
        }
        return;
      }
      final pos = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
        timeLimit: const Duration(seconds: 10),
      );
      final me = LatLng(pos.latitude, pos.longitude);
      if (!mounted) return;
      setState(() => _target = me);
      await _map?.animateCamera(CameraUpdate.newLatLngZoom(me, 17));
    } catch (_) {
      if (!silent && mounted) _snack('No pudimos obtener tu ubicación. Mueve el mapa hasta tu punto.');
    } finally {
      if (mounted) setState(() => _locating = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    return Scaffold(
      appBar: AppBar(title: const Text('Marca tu ubicación')),
      body: Stack(
        alignment: Alignment.center,
        children: [
          GoogleMap(
            initialCameraPosition: CameraPosition(target: _target, zoom: 17),
            onMapCreated: (c) => _map = c,
            onCameraMoveStarted: () => setState(() => _moving = true),
            onCameraMove: (p) => _target = p.target,
            onCameraIdle: () => setState(() => _moving = false),
            myLocationEnabled: true,
            myLocationButtonEnabled: false,
            zoomControlsEnabled: false,
            mapToolbarEnabled: false,
          ),
          // Pin fijo en el centro: la punta queda sobre el punto elegido.
          IgnorePointer(
            child: Padding(
              padding: const EdgeInsets.only(bottom: 44),
              child: AnimatedScale(
                scale: _moving ? 1.15 : 1,
                duration: const Duration(milliseconds: 150),
                child: const Icon(Icons.location_on_rounded, size: 48, color: AppColors.primary),
              ),
            ),
          ),
          Positioned(
            right: 16,
            bottom: 150,
            child: FloatingActionButton.small(
              heroTag: null,
              tooltip: 'Ir a mi ubicación',
              onPressed: _locating ? null : _goToMe,
              backgroundColor: Colors.white,
              child: _locating
                  ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
                  : const Icon(Icons.my_location_rounded, color: AppColors.primary),
            ),
          ),
          Positioned(
            left: 16,
            right: 16,
            bottom: 24,
            child: Material(
              elevation: 4,
              borderRadius: BorderRadius.circular(16),
              color: Colors.white,
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text('Mueve el mapa hasta dejar el pin en tu punto de entrega', style: t.bodyMedium),
                    const SizedBox(height: 10),
                    FilledButton(
                      onPressed: _moving ? null : () => context.pop(_target),
                      child: const Text('Usar esta ubicación'),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
