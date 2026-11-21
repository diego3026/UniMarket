import 'package:unimarket/presentation/viewmodels/catalog/catalog_cubit.dart';
import 'package:flutter/material.dart';

import '../../../constants/app_colors.dart';
import '../../../domain/entities/market_entities.dart';

/// Pin sobre el mapa del campus.
class MapPin {
  final String placeId;
  final IconData icon;
  final Color color;
  final String? label;
  const MapPin({
    required this.placeId,
    required this.icon,
    required this.color,
    this.label,
  });
}

/// Mapa ilustrado del campus de la Universidad del Magdalena.
///
/// No depende de Google Maps: dibuja edificios, caminos y zonas verdes, y
/// encima los pines (tienda, destino, repartidor). Sirve para:
/// - mostrar dónde recoger un pedido,
/// - seguir un domicilio (ruta + posición del repartidor),
/// - elegir un punto de entrega o de recogida ([onPlaceTap]).
class CampusMap extends StatelessWidget {
  final List<MapPin> pins;

  /// Ruta (origen → destino) y progreso 0..1 del repartidor.
  final String? routeFrom;
  final String? routeTo;
  final double? courierProgress;
  final String? selectedPlaceId;
  final ValueChanged<CampusPlace>? onPlaceTap;
  final double height;
  final double radius;

  const CampusMap({
    super.key,
    this.pins = const [],
    this.routeFrom,
    this.routeTo,
    this.courierProgress,
    this.selectedPlaceId,
    this.onPlaceTap,
    this.height = 220,
    this.radius = 20,
  });

  static List<Offset> routePoints(String from, String to) {
    final a = Catalog.place(from).position;
    final b = Catalog.place(to).position;
    final plaza = Catalog.place('plaza').position;
    // Los caminos del campus pasan por la plazoleta central.
    if (from == 'plaza' || to == 'plaza') return [a, b];
    return [a, Offset(a.dx, plaza.dy), Offset(b.dx, plaza.dy), b];
  }

  static Offset pointAt(List<Offset> pts, double t) {
    if (pts.length < 2) return pts.first;
    var total = 0.0;
    for (var i = 0; i < pts.length - 1; i++) {
      total += (pts[i + 1] - pts[i]).distance;
    }
    var target = total * t.clamp(0, 1);
    for (var i = 0; i < pts.length - 1; i++) {
      final seg = (pts[i + 1] - pts[i]).distance;
      if (target <= seg) {
        return Offset.lerp(pts[i], pts[i + 1], seg == 0 ? 0 : target / seg)!;
      }
      target -= seg;
    }
    return pts.last;
  }

  @override
  Widget build(BuildContext context) {
    final accent = Theme.of(context).colorScheme.primary;
    return ClipRRect(
      borderRadius: BorderRadius.circular(radius),
      child: SizedBox(
        height: height,
        child: LayoutBuilder(
          builder: (context, c) {
            final size = Size(c.maxWidth, c.maxHeight);
            Offset px(Offset rel) =>
                Offset(rel.dx * size.width, rel.dy * size.height);
            final route = routeFrom != null && routeTo != null
                ? routePoints(routeFrom!, routeTo!)
                : null;
            return Stack(
              children: [
                Positioned.fill(
                  child: CustomPaint(
                    painter: _CampusPainter(
                      route: route,
                      routeColor: accent,
                      selected: selectedPlaceId,
                    ),
                  ),
                ),
                // Lugares tocables (modo selector)
                if (onPlaceTap != null)
                  for (final p in Catalog.places)
                    Positioned(
                      left: px(p.position).dx - 44,
                      top: px(p.position).dy - 22,
                      width: 88,
                      height: 44,
                      child: Tooltip(
                        message: p.name,
                        child: InkWell(
                          borderRadius: BorderRadius.circular(12),
                          onTap: () => onPlaceTap!(p),
                        ),
                      ),
                    ),
                for (final pin in pins)
                  _positionedPin(
                    px(Catalog.place(pin.placeId).position),
                    pin,
                  ),
                if (route != null && courierProgress != null)
                  _courier(px(pointAt(route, courierProgress!)), accent),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _positionedPin(Offset at, MapPin pin) {
    return Positioned(
      left: at.dx - 60,
      top: at.dy - 52,
      width: 120,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (pin.label != null)
            Container(
              margin: const EdgeInsets.only(bottom: 3),
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
                boxShadow: const [
                  BoxShadow(color: Color(0x22000000), blurRadius: 6),
                ],
              ),
              child: Text(
                pin.label!,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: pin.color,
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white, width: 3),
              boxShadow: [
                BoxShadow(
                  color: pin.color.withValues(alpha: 0.4),
                  blurRadius: 10,
                ),
              ],
            ),
            child: Icon(pin.icon, size: 16, color: Colors.white),
          ),
        ],
      ),
    );
  }

  Widget _courier(Offset at, Color color) => Positioned(
    left: at.dx - 20,
    top: at.dy - 20,
    child: Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        color: Colors.white,
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(color: color.withValues(alpha: 0.35), blurRadius: 14),
        ],
      ),
      child: Icon(Icons.delivery_dining_rounded, color: color, size: 24),
    ),
  );
}

class _CampusPainter extends CustomPainter {
  final List<Offset>? route;
  final Color routeColor;
  final String? selected;

  _CampusPainter({this.route, required this.routeColor, this.selected});

  @override
  void paint(Canvas canvas, Size size) {
    Offset px(Offset r) => Offset(r.dx * size.width, r.dy * size.height);

    // Fondo y zonas verdes
    canvas.drawRect(
      Offset.zero & size,
      Paint()..color = const Color(0xFFF2F0EA),
    );
    final green = Paint()..color = const Color(0xFFDDEFD9);
    for (final r in const [
      Rect.fromLTWH(0.02, 0.32, 0.26, 0.10),
      Rect.fromLTWH(0.55, 0.52, 0.22, 0.10),
      Rect.fromLTWH(0.24, 0.86, 0.40, 0.12),
      Rect.fromLTWH(0.88, 0.04, 0.10, 0.28),
    ]) {
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(
            r.left * size.width,
            r.top * size.height,
            r.width * size.width,
            r.height * size.height,
          ),
          const Radius.circular(14),
        ),
        green,
      );
    }

    // Caminos
    final road = Paint()
      ..color = Colors.white
      ..strokeWidth = 12
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;
    final plaza = px(Catalog.place('plaza').position);
    canvas.drawLine(Offset(0, plaza.dy), Offset(size.width, plaza.dy), road);
    canvas.drawLine(Offset(plaza.dx, 0), Offset(plaza.dx, size.height), road);
    for (final p in Catalog.places) {
      final o = px(p.position);
      canvas.drawLine(o, Offset(o.dx, plaza.dy), road..strokeWidth = 7);
    }
    canvas.drawCircle(plaza, 22, Paint()..color = Colors.white);

    // Edificios
    final building = Paint()..color = const Color(0xFFE3DEEF);
    final buildingSel = Paint()..color = routeColor.withValues(alpha: 0.25);
    for (final p in Catalog.places) {
      if (p.id == 'plaza') continue;
      final o = px(p.position);
      final rect = RRect.fromRectAndRadius(
        Rect.fromCenter(center: o.translate(0, 14), width: 58, height: 22),
        const Radius.circular(6),
      );
      canvas.drawRRect(rect, p.id == selected ? buildingSel : building);
      final tp = TextPainter(
        text: TextSpan(
          text: p.name
              .replaceAll('Portería principal', 'Portería')
              .replaceAll('Plazoleta central', 'Plazoleta'),
          style: TextStyle(
            fontSize: 8.5,
            fontWeight: FontWeight.w700,
            color: p.id == selected ? routeColor : AppColors.textSecondary,
          ),
        ),
        textDirection: TextDirection.ltr,
        maxLines: 1,
        ellipsis: '…',
      )..layout(maxWidth: 56);
      tp.paint(canvas, o.translate(-tp.width / 2, 14 - tp.height / 2));
    }

    // Ruta del pedido
    if (route != null && route!.length > 1) {
      final path = Path()..moveTo(px(route!.first).dx, px(route!.first).dy);
      for (final p in route!.skip(1)) {
        path.lineTo(px(p).dx, px(p).dy);
      }
      canvas.drawPath(
        path,
        Paint()
          ..color = routeColor.withValues(alpha: 0.18)
          ..strokeWidth = 10
          ..style = PaintingStyle.stroke
          ..strokeCap = StrokeCap.round
          ..strokeJoin = StrokeJoin.round,
      );
      final dashed = Paint()
        ..color = routeColor
        ..strokeWidth = 4
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round;
      for (final metric in path.computeMetrics()) {
        var d = 0.0;
        while (d < metric.length) {
          final seg = metric.extractPath(d, (d + 10).clamp(0, metric.length));
          canvas.drawPath(seg, dashed);
          d += 16;
        }
      }
    }
  }

  @override
  bool shouldRepaint(covariant _CampusPainter old) =>
      old.route != route ||
      old.selected != selected ||
      old.routeColor != routeColor;
}

/// Hoja inferior para elegir un punto del campus (entrega o recogida).
Future<CampusPlace?> showCampusPlacePicker(
  BuildContext context, {
  required String title,
  String? selectedId,
}) {
  return showModalBottomSheet<CampusPlace>(
    context: context,
    isScrollControlled: true,
    builder: (ctx) {
      String? sel = selectedId;
      return StatefulBuilder(
        builder: (ctx, setState) => SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: Theme.of(ctx).textTheme.titleLarge),
                const SizedBox(height: 4),
                Text(
                  'Toca un lugar en el mapa o elígelo de la lista.',
                  style: Theme.of(ctx).textTheme.bodySmall,
                ),
                const SizedBox(height: 12),
                CampusMap(
                  height: 210,
                  selectedPlaceId: sel,
                  pins: [
                    if (sel != null)
                      MapPin(
                        placeId: sel!,
                        icon: Icons.place_rounded,
                        color: Theme.of(ctx).colorScheme.primary,
                      ),
                  ],
                  onPlaceTap: (p) => setState(() => sel = p.id),
                ),
                const SizedBox(height: 8),
                ConstrainedBox(
                  constraints: BoxConstraints(
                    maxHeight: MediaQuery.of(ctx).size.height * 0.3,
                  ),
                  child: ListView(
                    shrinkWrap: true,
                    children: [
                      for (final p in Catalog.places)
                        ListTile(
                          onTap: () => setState(() => sel = p.id),
                          leading: Icon(
                            sel == p.id
                                ? Icons.radio_button_checked_rounded
                                : Icons.radio_button_off_rounded,
                            color: sel == p.id
                                ? Theme.of(ctx).colorScheme.primary
                                : AppColors.textMuted,
                          ),
                          title: Text(p.name),
                          subtitle: Text(p.hint),
                          contentPadding: EdgeInsets.zero,
                          dense: true,
                        ),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
                FilledButton(
                  onPressed: sel == null
                      ? null
                      : () => Navigator.pop(ctx, Catalog.place(sel!)),
                  child: const Text('Confirmar ubicación'),
                ),
              ],
            ),
          ),
        ),
      );
    },
  );
}
