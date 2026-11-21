import 'dart:async';

import 'package:flutter/services.dart';
import 'package:unimarket/presentation/viewmodels/catalog/catalog_cubit.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../constants/app_colors.dart';
import '../../../core/router/app_routes.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/formatters.dart';
import '../../../domain/entities/market_entities.dart';
import '../../viewmodels/market/market_cubits.dart';
import '../../widgets/ui/app_widgets.dart';
import '../../../core/utils/directions.dart';
import '../../widgets/ui/uni_map.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart' show LatLng, BitmapDescriptor;
import '../../widgets/ui/product_image.dart';

/// Seguimiento de un pedido (domicilio o para recoger).
///
/// Lo más importante arriba: estado y tiempo estimado; luego el mapa con la
/// tienda, el destino y el repartidor; la línea de tiempo; y al final el
/// detalle y las acciones (cancelar, confirmar entrega, calificar).
class OrderTrackingPage extends StatefulWidget {
  final String orderId;
  const OrderTrackingPage({super.key, required this.orderId});

  @override
  State<OrderTrackingPage> createState() => _OrderTrackingPageState();
}

class _OrderTrackingPageState extends State<OrderTrackingPage>
{

  Timer? _poll;
  bool _fetched = false;

  @override
  void initState() {
    super.initState();
    _refresh();
    // Mientras el pedido siga activo, se actualiza cada 10 s.
    _poll = Timer.periodic(const Duration(seconds: 10), (_) {
      final o = context.read<MarketOrdersCubit>().byId(widget.orderId);
      if (o == null || o.status.isActive) _refresh();
    });
  }

  Future<void> _refresh() async {
    await context.read<MarketOrdersCubit>().fetch(widget.orderId);
    if (mounted && !_fetched) setState(() => _fetched = true);
  }

  @override
  void dispose() {
    _poll?.cancel();
    super.dispose();
  }

  void _snack(String m) => ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(m)));

  Future<void> _reportPayment(MarketOrder o) async {
    final c = TextEditingController();
    final ref = await showDialog<String>(
      context: context,
      builder: (d) => AlertDialog(
        title: const Text('¿Ya hiciste la transferencia?'),
        content: TextField(
          controller: c,
          autofocus: true,
          maxLength: 40,
          decoration: const InputDecoration(
            labelText: 'Número de comprobante (opcional)',
            hintText: 'Ej. M123456',
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(d), child: const Text('Todavía no')),
          FilledButton(onPressed: () => Navigator.pop(d, c.text.trim()), child: const Text('Avisar a la tienda')),
        ],
      ),
    );
    if (ref == null || !mounted) return;
    final err = await context.read<MarketOrdersCubit>().reportPayment(o.id, ref);
    if (mounted) _snack(err ?? 'Le avisamos a ${o.storeName}. Confirmará cuando vea el pago.');
  }

  Future<void> _answerCancellation(MarketOrder o, bool received) async {
    final err = await context.read<MarketOrdersCubit>().cancelFeedback(o.id, received);
    if (!mounted) return;
    _snack(err ?? (received ? 'Gracias, lo revisaremos.' : 'Gracias por contarnos.'));
  }

  Widget _cancelQuestion(TextTheme t, MarketOrder o) => Padding(
    padding: const EdgeInsets.only(bottom: 14),
    child: SurfaceCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('¿Recibiste el pedido de todas formas?', style: t.titleSmall),
          const SizedBox(height: 4),
          Text(
            'La tienda lo canceló. Tu respuesta nos ayuda a que las ventas se registren bien.',
            style: t.bodySmall,
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => _answerCancellation(o, false),
                  child: const Text('No lo recibí'),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: FilledButton(
                  onPressed: () => _answerCancellation(o, true),
                  child: const Text('Sí lo recibí'),
                ),
              ),
            ],
          ),
        ],
      ),
    ),
  );

  Widget _payCard(TextTheme t, MarketOrder o) {
    final p = o.payTo;
    final reported = o.paymentStatus == PaymentStatus.reported;
    final failed = o.paymentStatus == PaymentStatus.failed;
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: SurfaceCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  reported ? Icons.hourglass_top_rounded : Icons.bolt_rounded,
                  color: failed ? AppColors.danger : AppColors.primary,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    reported
                        ? 'Pago reportado · esperando confirmación'
                        : failed
                        ? 'La tienda no ha recibido tu pago'
                        : 'Paga por ${o.paymentKind == PaymentKind.nequi ? 'Nequi' : 'Bre-B'}',
                    style: t.titleSmall,
                  ),
                ),
              ],
            ),
            if (p != null && !reported) ...[
              const SizedBox(height: 10),
              Text(
                o.paymentKind == PaymentKind.nequi ? 'Envía a este Nequi' : 'Envía a esta llave',
                style: t.bodySmall,
              ),
              Row(
                children: [
                  Expanded(child: SelectableText(p.key, style: t.titleMedium)),
                  IconButton(
                    tooltip: 'Copiar',
                    icon: const Icon(Icons.copy_rounded, size: 20),
                    onPressed: () {
                      Clipboard.setData(ClipboardData(text: p.key));
                      _snack('Copiado');
                    },
                  ),
                ],
              ),
              if (p.holderName.isNotEmpty) Text('A nombre de ${p.holderName}', style: t.bodySmall),
              const SizedBox(height: 4),
              Text('Valor exacto: ${formatCop(p.amount)}', style: t.bodyMedium?.copyWith(fontWeight: FontWeight.w700)),
              if (p.referenceHint.isNotEmpty) Text(p.referenceHint, style: t.bodySmall),
              const SizedBox(height: 10),
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: () => _reportPayment(o),
                  icon: const Icon(Icons.check_rounded),
                  label: const Text('Ya pagué'),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  (String, String) _headline(MarketOrder o, StoreSettings s) =>
      switch (o.status) {
        OrderStatus.pending => (
          'Esperando confirmación',
          '${o.storeName} revisará tu pedido en un momento',
        ),
        OrderStatus.preparing => (
          'Preparando tu pedido',
          o.mode == FulfillmentMode.pickup
              ? 'Listo para recoger en ~${s.prepMinutes} min'
              : 'Sale hacia ti en ~${s.prepMinutes} min',
        ),
        OrderStatus.ready => (
          '¡Listo para recoger!',
          'Muestra tu código en ${Catalog.place(s.pickupPlaceId).name}',
        ),
        OrderStatus.onTheWay => (
          'Tu pedido va en camino',
          'Llega en ~8 min a ${Catalog.place(o.placeId).name}',
        ),
        OrderStatus.delivered => (
          'Pedido entregado',
          '¡Gracias por apoyar a ${o.storeName}!',
        ),
        OrderStatus.cancelled => (
          o.cancelledBy == 'seller' ? '${o.storeName} canceló el pedido' : 'Pedido cancelado',
          o.paidCancelled
              ? 'La tienda debe devolverte el dinero en máximo 2 días hábiles'
              : (o.cancelReason.isEmpty ? 'No se realizó ningún cobro' : o.cancelReason),
        ),
      };

  Color _statusColor(OrderStatus s) => switch (s) {
    OrderStatus.pending => AppColors.warning,
    OrderStatus.preparing => AppColors.info,
    OrderStatus.ready || OrderStatus.onTheWay => AppColors.primary,
    OrderStatus.delivered => AppColors.success,
    OrderStatus.cancelled => AppColors.danger,
  };

  IconData _statusIcon(OrderStatus s) => switch (s) {
    OrderStatus.pending => Icons.hourglass_top_rounded,
    OrderStatus.preparing => Icons.soup_kitchen_rounded,
    OrderStatus.ready => Icons.shopping_bag_rounded,
    OrderStatus.onTheWay => Icons.delivery_dining_rounded,
    OrderStatus.delivered => Icons.check_circle_rounded,
    OrderStatus.cancelled => Icons.cancel_rounded,
  };

  Future<void> _confirmCancel(MarketOrder o) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('¿Cancelar el pedido?'),
        content: Text(
          '${o.storeName} aún no lo ha aceptado, así que no tiene costo.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Mantener pedido'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.danger,
              minimumSize: const Size(0, 44),
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Cancelar pedido'),
          ),
        ],
      ),
    );
    if (ok != true || !mounted) return;
    final err = await context.read<MarketOrdersCubit>().cancel(o.id, reason: 'Cancelado por el cliente');
    if (mounted) _snack(err ?? 'Pedido cancelado');
  }

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    return BlocBuilder<MarketOrdersCubit, List<MarketOrder>>(
      builder: (context, _) {
        final o = context.read<MarketOrdersCubit>().byId(widget.orderId);
        if (o == null && !_fetched) {
          return const Scaffold(body: Center(child: CircularProgressIndicator()));
        }
        if (o == null) {
          return Scaffold(
            appBar: AppBar(),
            body: const EmptyState(
              icon: Icons.receipt_long_outlined,
              title: 'Pedido no encontrado',
              message: 'Puede que se haya eliminado.',
            ),
          );
        }
        final s = context.watch<StoreSettingsCubit>().of(o.storeId);
        final (title, subtitle) = _headline(o, s);
        final color = _statusColor(o.status);
        final isPickup = o.mode == FulfillmentMode.pickup;
        final storePlace = s.pickupPlaceId;
        final from = Catalog.place(storePlace);
        final to = Catalog.place(o.placeId);

        return Scaffold(
          appBar: AppBar(
            title: Text('Pedido #${o.id}'),
            actions: [
              IconButton(tooltip: 'Actualizar', onPressed: _refresh, icon: const Icon(Icons.refresh_rounded)),
            ],
          ),
          body: ListView(
            padding: const EdgeInsets.fromLTRB(
              AppTheme.pagePadding,
              0,
              AppTheme.pagePadding,
              24,
            ),
            children: [
              // Estado principal
              Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.10),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 52,
                      height: 52,
                      decoration: BoxDecoration(
                        color: color,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(_statusIcon(o.status), color: Colors.white),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(title, style: t.titleLarge),
                          const SizedBox(height: 2),
                          Text(
                            subtitle,
                            style: t.bodyMedium?.copyWith(
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),

              // La tienda canceló: ¿lo recibiste de todas formas?
              if (o.canAnswerCancellation) _cancelQuestion(t, o),
              if (o.customerConfirmation == 'received')
                Padding(
                  padding: const EdgeInsets.only(bottom: 14),
                  child: SurfaceCard(
                    child: Text(
                      'Gracias. Indicaste que sí recibiste el pedido; el equipo de UniMarket lo está revisando.',
                      style: t.bodyMedium,
                    ),
                  ),
                ),

              // Pago por transferencia
              if (o.paymentKind.isTransfer &&
                  o.status.isActive &&
                  o.paymentStatus != PaymentStatus.paid)
                _payCard(t, o),

              // Código de recogida
              if (isPickup && o.status.isActive)
                Padding(
                  padding: const EdgeInsets.only(bottom: 14),
                  child: SurfaceCard(
                    child: Row(
                      children: [
                        const Icon(
                          Icons.qr_code_2_rounded,
                          size: 40,
                          color: AppColors.primary,
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Código para recoger', style: t.bodySmall),
                              Text(
                                o.pickupCode.split('').join(' '),
                                style: t.headlineMedium?.copyWith(
                                  letterSpacing: 4,
                                  color: AppColors.primary,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Text(
                          'Muéstralo al\nemprendedor',
                          textAlign: TextAlign.right,
                          style: t.bodySmall,
                        ),
                      ],
                    ),
                  ),
                ),

              // Mapa
              if (o.status != OrderStatus.cancelled)
                UniMap(
                  height: 230,
                  showGuidePins: false,
                  markers: [
                    if (from.hasLocation)
                      UniMarker(
                        id: 'store',
                        latitude: from.latitude!,
                        longitude: from.longitude!,
                        title: isPickup ? 'Recoge aquí · ${o.storeName}' : o.storeName,
                        snippet: from.name,
                      ),
                    if (!isPickup && to.hasLocation)
                      UniMarker(
                        id: 'dest',
                        latitude: to.latitude!,
                        longitude: to.longitude!,
                        title: 'Entrega · ${to.name}',
                        snippet: o.notes.isEmpty ? null : o.notes,
                        hue: BitmapDescriptor.hueViolet,
                      ),
                  ],
                  route: !isPickup && from.hasLocation && to.hasLocation
                      ? [LatLng(from.latitude!, from.longitude!), LatLng(to.latitude!, to.longitude!)]
                      : const [],
                ),
              if (o.status != OrderStatus.cancelled && isPickup && from.hasLocation)
                Align(
                  alignment: Alignment.centerLeft,
                  child: TextButton.icon(
                    onPressed: () => openDirections(from.latitude!, from.longitude!),
                    icon: const Icon(Icons.directions_walk_rounded),
                    label: Text('Cómo llegar a ${from.name}'),
                  ),
                ),
              if (o.status != OrderStatus.cancelled) const SizedBox(height: 14),

              // Línea de tiempo
              SurfaceCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Estado del pedido', style: t.titleMedium),
                    const SizedBox(height: 12),
                    for (final (i, step)
                        in (o.status == OrderStatus.cancelled
                                ? [OrderStatus.pending, OrderStatus.cancelled]
                                : o.flow)
                            .indexed)
                      _TimelineTile(
                        status: step,
                        isPickup: isPickup,
                        time: o.history[step],
                        done: o.history.containsKey(step),
                        current: o.status == step,
                        last:
                            i ==
                            (o.status == OrderStatus.cancelled
                                ? 1
                                : o.flow.length - 1),
                        color: step == OrderStatus.cancelled
                            ? AppColors.danger
                            : AppColors.primary,
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 14),

              // Tienda
              SurfaceCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        ClipOval(
                          child: ProductImage(
                            imageUrl: '',
                            category: o.category,
                            width: 46,
                            height: 46,
                            radius: 0,
                            iconSize: 20,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(o.storeName, style: t.titleMedium),
                              Text(
                                isPickup
                                    ? '${Catalog.place(storePlace).name} · ${s.pickupNotes}'
                                    : 'Entrega en ${Catalog.place(o.placeId).name}${o.notes.isEmpty ? '' : ' · ${o.notes}'}',
                                style: t.bodySmall,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: () =>
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(
                                      'Llamando a ${o.storeName} · ${s.phone}',
                                    ),
                                  ),
                                ),
                            icon: const Icon(Icons.call_outlined, size: 18),
                            label: const Text('Llamar'),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: () =>
                                context.push(AppRoutes.storePath(o.storeId)),
                            icon: const Icon(
                              Icons.storefront_outlined,
                              size: 18,
                            ),
                            label: const Text('Ver tienda'),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),

              // Detalle
              SurfaceCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Detalle', style: t.titleMedium),
                    const SizedBox(height: 8),
                    for (final l in o.lines)
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 3),
                        child: Row(
                          children: [
                            Text(
                              '${l.quantity}×',
                              style: t.titleSmall?.copyWith(
                                color: AppColors.primary,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(child: Text(l.name)),
                            Text(formatCop(l.total)),
                          ],
                        ),
                      ),
                    const Divider(height: 20),
                    if (o.couponDiscount > 0)
                      _row(
                        t,
                        'Cupón ${o.couponCode}',
                        '-${formatCop(o.couponDiscount)}',
                        AppColors.success,
                      ),
                    _row(
                      t,
                      isPickup ? 'Recoger en tienda' : 'Domicilio',
                      o.deliveryFee == 0 ? 'Gratis' : formatCop(o.deliveryFee),
                      null,
                    ),
                    _row(t, 'Pago', o.paymentLabel, null),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Text('Total', style: t.titleMedium),
                        const Spacer(),
                        Text(
                          formatCop(o.total),
                          style: t.titleLarge?.copyWith(
                            color: AppColors.primary,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              if (o.rating != null) ...[
                const SizedBox(height: 14),
                SurfaceCard(
                  child: Row(
                    children: [
                      ...List.generate(
                        5,
                        (i) => Icon(
                          i < o.rating!
                              ? Icons.star_rounded
                              : Icons.star_outline_rounded,
                          color: AppColors.accent,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          o.review.isEmpty
                              ? 'Calificaste este pedido'
                              : '“${o.review}”',
                          style: t.bodySmall,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
          bottomNavigationBar: _actions(context, o),
        );
      },
    );
  }

  Widget _row(TextTheme t, String a, String b, Color? c) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 3),
    child: Row(
      children: [
        Text(a, style: t.bodyMedium?.copyWith(color: AppColors.textSecondary)),
        const Spacer(),
        Text(
          b,
          style: t.bodyMedium?.copyWith(
            color: c,
            fontWeight: c != null ? FontWeight.w700 : null,
          ),
        ),
      ],
    ),
  );

  Widget? _actions(BuildContext context, MarketOrder o) {
    switch (o.status) {
      case OrderStatus.pending:
        return BottomActionBar(
          child: OutlinedButton(
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.danger,
              side: const BorderSide(color: AppColors.danger),
              minimumSize: const Size.fromHeight(52),
            ),
            onPressed: () => _confirmCancel(o),
            child: const Text('Cancelar pedido'),
          ),
        );
      case OrderStatus.delivered:
        if (o.rating != null) return null;
        return BottomActionBar(
          child: FilledButton.icon(
            onPressed: () => context.push(AppRoutes.orderReviewPath(o.id)),
            icon: const Icon(Icons.star_rounded),
            label: Text('Calificar a ${o.storeName}'),
          ),
        );
      case OrderStatus.preparing:
      case OrderStatus.ready:
      case OrderStatus.onTheWay:
      case OrderStatus.cancelled:
        return null;
    }
  }
}

class _TimelineTile extends StatelessWidget {
  final OrderStatus status;
  final bool isPickup;
  final DateTime? time;
  final bool done;
  final bool current;
  final bool last;
  final Color color;

  const _TimelineTile({
    required this.status,
    required this.isPickup,
    required this.time,
    required this.done,
    required this.current,
    required this.last,
    required this.color,
  });

  String get _title => switch (status) {
    OrderStatus.pending => 'Pedido enviado',
    OrderStatus.preparing => 'Aceptado y en preparación',
    OrderStatus.ready => 'Listo para recoger',
    OrderStatus.onTheWay => 'En camino',
    OrderStatus.delivered => isPickup ? 'Recogido' : 'Entregado',
    OrderStatus.cancelled => 'Cancelado',
  };

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    final c = done ? color : AppColors.border;
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(
            width: 28,
            child: Column(
              children: [
                Container(
                  width: 22,
                  height: 22,
                  decoration: BoxDecoration(
                    color: done ? c : Colors.white,
                    shape: BoxShape.circle,
                    border: Border.all(color: c, width: 2),
                    boxShadow: current
                        ? [
                            BoxShadow(
                              color: c.withValues(alpha: 0.4),
                              blurRadius: 8,
                            ),
                          ]
                        : null,
                  ),
                  child: done
                      ? const Icon(
                          Icons.check_rounded,
                          size: 14,
                          color: Colors.white,
                        )
                      : null,
                ),
                if (!last) Expanded(child: Container(width: 2, color: c)),
              ],
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(bottom: 18),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      _title,
                      style: t.titleSmall?.copyWith(
                        color: done
                            ? AppColors.textPrimary
                            : AppColors.textMuted,
                        fontWeight: current ? FontWeight.w800 : FontWeight.w600,
                      ),
                    ),
                  ),
                  if (time != null)
                    Text(
                      DateFormat('h:mm a', 'es_CO').format(time!),
                      style: t.bodySmall,
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
