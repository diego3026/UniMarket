import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../../../constants/app_colors.dart';
import '../../../domain/entities/market_entities.dart';
import '../../viewmodels/catalog/catalog_cubit.dart';

/// Marcador propio de una pantalla (tienda, destino del pedido…).
class UniMarker {
  final String id;
  final double latitude;
  final double longitude;
  final String title;
  final String? snippet;
  final double hue;
  final VoidCallback? onTap;

  const UniMarker({
    required this.id,
    required this.latitude,
    required this.longitude,
    required this.title,
    this.snippet,
    this.hue = BitmapDescriptor.hueOrange,
    this.onTap,
  });

  LatLng get latLng => LatLng(latitude, longitude);
}

/// Mapa de Google con los pines del campus que configura el administrador.
///
/// - [markers]: marcadores de la pantalla (tienda, destino…).
/// - [showGuidePins]: muestra todos los pines activos; con [deliveryOnly] solo
///   los puntos de entrega.
/// - [selectedPlaceId] resalta un pin y [onPlaceTap] permite elegirlo.
/// - [route]: dibuja una línea entre puntos (p. ej. tienda → destino).
class UniMap extends StatefulWidget {
  final List<UniMarker> markers;
  final bool showGuidePins;
  final bool deliveryOnly;
  final String? selectedPlaceId;
  final ValueChanged<CampusPlace>? onPlaceTap;
  final List<LatLng> route;
  final double height;
  final double zoom;
  final void Function(LatLng)? onLongPress;
  final List<CampusPlace>? places;

  const UniMap({
    super.key,
    this.markers = const [],
    this.showGuidePins = true,
    this.deliveryOnly = false,
    this.selectedPlaceId,
    this.onPlaceTap,
    this.route = const [],
    this.height = 220,
    this.zoom = 16.5,
    this.onLongPress,
    this.places,
  });

  /// Universidad del Magdalena, Santa Marta.
  static const campus = LatLng(11.2247, -74.1869);

  /// En las pruebas automáticas no hay Google Maps: se dibuja un recuadro.
  static bool usePlaceholder = false;

  /// Color del pin según su tipo.
  static double hueFor(PlaceKind k) => switch (k) {
    PlaceKind.delivery => BitmapDescriptor.hueGreen,
    PlaceKind.building => BitmapDescriptor.hueAzure,
    PlaceKind.entrance => BitmapDescriptor.hueYellow,
    PlaceKind.food => BitmapDescriptor.hueRose,
    PlaceKind.parking => BitmapDescriptor.hueBlue,
    PlaceKind.service => BitmapDescriptor.hueCyan,
    PlaceKind.sports => BitmapDescriptor.hueMagenta,
    PlaceKind.other => BitmapDescriptor.hueViolet,
  };

  @override
  State<UniMap> createState() => _UniMapState();
}

class _UniMapState extends State<UniMap> {
  GoogleMapController? _controller;

  List<CampusPlace> _places(BuildContext context) {
    if (!widget.showGuidePins) return const [];
    final all = widget.places ?? context.watch<CatalogCubit>().state.places;
    return all
        .where(
          (p) =>
              p.hasLocation &&
              (!widget.deliveryOnly ||
                  p.isDeliveryPoint ||
                  p.id == widget.selectedPlaceId),
        )
        .toList();
  }

  /// Puntos que la cámara debe mostrar: marcadores propios y pin elegido.
  List<LatLng> _focus(List<CampusPlace> places) {
    final pts = [for (final m in widget.markers) m.latLng, ...widget.route];
    for (final p in places) {
      if (p.id == widget.selectedPlaceId)
        pts.add(LatLng(p.latitude!, p.longitude!));
    }
    return pts;
  }

  Future<void> _fit(List<LatLng> pts) async {
    final c = _controller;
    if (c == null || pts.length < 2) return;
    var s = pts.first.latitude, n = s, w = pts.first.longitude, e = w;
    for (final p in pts) {
      if (p.latitude < s) s = p.latitude;
      if (p.latitude > n) n = p.latitude;
      if (p.longitude < w) w = p.longitude;
      if (p.longitude > e) e = p.longitude;
    }
    if (n - s < 0.0005 && e - w < 0.0005) return;
    await c.animateCamera(
      CameraUpdate.newLatLngBounds(
        LatLngBounds(southwest: LatLng(s, w), northeast: LatLng(n, e)),
        56,
      ),
    );
  }

  @override
  void didUpdateWidget(UniMap old) {
    super.didUpdateWidget(old);
    if (old.selectedPlaceId != widget.selectedPlaceId ||
        old.markers.length != widget.markers.length) {
      final focus = _focus(_places(context));
      if (focus.length >= 2) {
        _fit(focus);
      } else if (focus.length == 1) {
        _controller?.animateCamera(CameraUpdate.newLatLng(focus.first));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final places = _places(context);
    final focus = _focus(places);

    if (UniMap.usePlaceholder) {
      return Container(
        height: widget.height,
        decoration: BoxDecoration(
          color: AppColors.lightPanel,
          borderRadius: BorderRadius.circular(16),
        ),
        alignment: Alignment.center,
        child: Text('Mapa · ${places.length + widget.markers.length} puntos'),
      );
    }

    final markers = <Marker>{
      for (final p in places)
        Marker(
          markerId: MarkerId('place-${p.id}'),
          position: LatLng(p.latitude!, p.longitude!),
          icon: BitmapDescriptor.defaultMarkerWithHue(
            p.id == widget.selectedPlaceId
                ? BitmapDescriptor.hueGreen
                : UniMap.hueFor(p.kind),
          ),
          alpha:
              widget.selectedPlaceId == null || p.id == widget.selectedPlaceId
              ? 1
              : 0.65,
          zIndexInt: p.id == widget.selectedPlaceId ? 2 : 0,
          infoWindow: InfoWindow(
            title: p.name,
            snippet: [
              if (p.hint.isNotEmpty) p.hint,
              if (p.isDeliveryPoint) 'Punto de entrega',
            ].join(' · '),
          ),
          onTap:
              widget.onPlaceTap == null ||
                  (widget.deliveryOnly && !p.isDeliveryPoint)
              ? null
              : () => widget.onPlaceTap!(p),
        ),
      for (final m in widget.markers)
        Marker(
          markerId: MarkerId('m-${m.id}'),
          position: m.latLng,
          icon: BitmapDescriptor.defaultMarkerWithHue(m.hue),
          zIndexInt: 3,
          infoWindow: InfoWindow(
            title: m.title,
            snippet: m.snippet,
            onTap: m.onTap,
          ),
        ),
    };

    return SizedBox(
      height: widget.height,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: GoogleMap(
          initialCameraPosition: CameraPosition(
            target: focus.isNotEmpty ? focus.first : UniMap.campus,
            zoom: widget.zoom,
          ),
          markers: markers,
          polylines: widget.route.length < 2
              ? const {}
              : {
                  Polyline(
                    polylineId: const PolylineId('route'),
                    points: widget.route,
                    color: AppColors.primary,
                    width: 4,
                    patterns: [PatternItem.dash(18), PatternItem.gap(10)],
                  ),
                },
          onMapCreated: (c) {
            _controller = c;
            Future.delayed(
              const Duration(milliseconds: 300),
              () => _fit(focus),
            );
          },
          onLongPress: widget.onLongPress,
          myLocationEnabled: false,
          myLocationButtonEnabled: false,
          mapToolbarEnabled: false,
          zoomControlsEnabled: false,
          // Dentro de listas desplazables el mapa debe recibir los gestos.
          gestureRecognizers: {
            Factory<OneSequenceGestureRecognizer>(
              () => EagerGestureRecognizer(),
            ),
          },
        ),
      ),
    );
  }
}
