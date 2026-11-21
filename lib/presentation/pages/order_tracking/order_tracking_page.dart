import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../constants/app_colors.dart';
import '../../../core/router/app_routes.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/formatters.dart';
import '../../../data/datasources/mock/market_mock_data.dart';
import '../../../domain/entities/market_entities.dart';
import '../../viewmodels/market/market_cubits.dart';
import '../../widgets/ui/app_widgets.dart';
import '../../widgets/ui/campus_map.dart';
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
    with SingleTickerProviderStateMixin {
  /// Ubicación aproximada del cliente (en la app real vendría del GPS).
  static const _myPlace = 'b8';

  late final AnimationController _courier = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 9),
  )..repeat();

  @override
  void dispose() {
    _courier.dispose();
    super.dispose();
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
          'Muestra tu código en ${MarketMockData.place(s.pickupPlaceId).name}',
        ),
        OrderStatus.onTheWay => (
          'Tu pedido va en camino',
          'Llega en ~8 min a ${MarketMockData.place(o.placeId).name}',
        ),
        OrderStatus.delivered => (
          'Pedido entregado',
          '¡Gracias por apoyar a ${o.storeName}!',
        ),
        OrderStatus.cancelled => (
          'Pedido cancelado',
          'No se realizó ningún cobro',
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
    if (ok == true && mounted) context.read<MarketOrdersCubit>().cancel(o.id);
  }

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    return BlocBuilder<MarketOrdersCubit, List<MarketOrder>>(
      builder: (context, _) {
        final o = context.read<MarketOrdersCubit>().byId(widget.orderId);
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
        final showMe = _myPlace != storePlace;

        return Scaffold(
          appBar: AppBar(
            title: Text('Pedido #${o.id}'),
            actions: [
              if (o.next != null)
                PopupMenuButton<String>(
                  tooltip: 'Más opciones',
                  onSelected: (_) =>
                      context.read<MarketOrdersCubit>().advance(o.id),
                  itemBuilder: (_) => const [
                    PopupMenuItem(
                      value: 'demo',
                      child: Text('Simular siguiente estado (demo)'),
                    ),
                  ],
                ),
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
                AnimatedBuilder(
                  animation: _courier,
                  builder: (context, _) => CampusMap(
                    height: 230,
                    // Recoger: ruta desde donde estás hasta la tienda.
                    routeFrom: isPickup
                        ? (showMe ? _myPlace : null)
                        : storePlace,
                    routeTo: isPickup
                        ? (showMe ? storePlace : null)
                        : o.placeId,
                    courierProgress: o.status == OrderStatus.onTheWay
                        ? 0.15 + 0.7 * _courier.value
                        : null,
                    selectedPlaceId: isPickup ? storePlace : o.placeId,
                    pins: [
                      MapPin(
                        placeId: storePlace,
                        icon: Icons.storefront_rounded,
                        color: AppColors.seller,
                        label: o.storeName,
                      ),
                      if (!isPickup)
                        MapPin(
                          placeId: o.placeId,
                          icon: Icons.home_rounded,
                          color: AppColors.primary,
                          label: 'Entrega',
                        ),
                      if (isPickup && showMe)
                        MapPin(
                          placeId: _myPlace,
                          icon: Icons.person_rounded,
                          color: AppColors.info,
                          label: 'Tú',
                        ),
                    ],
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
                                    ? '${MarketMockData.place(storePlace).name} · ${s.pickupNotes}'
                                    : 'Entrega en ${MarketMockData.place(o.placeId).name}${o.notes.isEmpty ? '' : ' · ${o.notes}'}',
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
    final cubit = context.read<MarketOrdersCubit>();
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
      case OrderStatus.ready:
      case OrderStatus.onTheWay:
        return BottomActionBar(
          child: FilledButton.icon(
            onPressed: () => cubit.advance(o.id),
            icon: const Icon(Icons.check_rounded),
            label: Text(
              o.status == OrderStatus.ready
                  ? 'Ya recogí mi pedido'
                  : 'Ya recibí mi pedido',
            ),
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
