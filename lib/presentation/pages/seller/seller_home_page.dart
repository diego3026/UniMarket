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
import 'seller_mock.dart';

/// Inicio del emprendedor (Figma Emprendedor: "Principal Tienda").
/// Las órdenes son las mismas que el cliente sigue en "Mis pedidos".
class SellerHomePage extends StatefulWidget {
  const SellerHomePage({super.key});

  @override
  State<SellerHomePage> createState() => _SellerHomePageState();
}

class _SellerHomePageState extends State<SellerHomePage> {
  static const _tabs = [
    'Por aceptar',
    'En preparación',
    'Listas / en camino',
    'Entregadas',
  ];
  String _tab = 'Por aceptar';

  bool _match(MarketOrder o) => switch (_tab) {
    'Por aceptar' => o.status == OrderStatus.pending,
    'En preparación' => o.status == OrderStatus.preparing,
    'Listas / en camino' =>
      o.status == OrderStatus.ready || o.status == OrderStatus.onTheWay,
    _ => o.status == OrderStatus.delivered || o.status == OrderStatus.cancelled,
  };

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    final store = SellerMock.store;
    final settings = context.watch<StoreSettingsCubit>().of(store.id);
    final all = context.watch<MarketOrdersCubit>().forStore(store.id);
    final orders = all.where(_match).toList();
    final pending = all.where((o) => o.status == OrderStatus.pending).length;
    final today = all
        .where((o) => o.status == OrderStatus.delivered)
        .fold<double>(0, (s, o) => s + o.total);

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: Container(
              decoration: const BoxDecoration(
                gradient: AppColors.sellerGradient,
                borderRadius: BorderRadius.vertical(
                  bottom: Radius.circular(28),
                ),
              ),
              child: SafeArea(
                bottom: false,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(
                    AppTheme.pagePadding,
                    16,
                    AppTheme.pagePadding,
                    22,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Bienvenido a',
                                  style: t.bodyMedium?.copyWith(
                                    color: Colors.white70,
                                  ),
                                ),
                                Text(
                                  store.name,
                                  style: t.headlineSmall?.copyWith(
                                    color: Colors.white,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          CircleIconButton(
                            icon: Icons.tune_rounded,
                            tooltip: 'Configurar tienda',
                            onPressed: () =>
                                context.push(AppRoutes.sellerSettings),
                          ),
                          const SizedBox(width: 8),
                          CircleIconButton(
                            icon: Icons.notifications_none_rounded,
                            tooltip: 'Notificaciones',
                            onPressed: () =>
                                context.push(AppRoutes.notifications),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: AppColors.textPrimary,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Column(
                          children: [
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 10,
                                    vertical: 4,
                                  ),
                                  decoration: BoxDecoration(
                                    color: AppColors.info,
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: const Text(
                                    'Horario',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    settings.isOpen
                                        ? 'Abierto ahora'
                                        : 'Cerrado',
                                    textAlign: TextAlign.end,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 6),
                                Switch(
                                  value: settings.isOpen,
                                  activeTrackColor: AppColors.success,
                                  onChanged: (v) => context
                                      .read<StoreSettingsCubit>()
                                      .update(settings.copyWith(isOpen: v)),
                                ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                const Icon(
                                  Icons.place_outlined,
                                  size: 16,
                                  color: Colors.white70,
                                ),
                                const SizedBox(width: 4),
                                Expanded(
                                  child: Text(
                                    'Recogen en ${MarketMockData.place(settings.pickupPlaceId).name} · ${store.schedule}',
                                    style: const TextStyle(
                                      color: Colors.white70,
                                      fontSize: 12,
                                    ),
                                    maxLines: 2,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            Row(
                              children: [
                                Expanded(
                                  child: FilledButton.icon(
                                    style: FilledButton.styleFrom(
                                      backgroundColor: AppColors.seller,
                                      minimumSize: const Size.fromHeight(44),
                                    ),
                                    onPressed: () =>
                                        context.push(AppRoutes.sellerSchedule),
                                    icon: const Icon(
                                      Icons.edit_calendar_rounded,
                                      size: 18,
                                    ),
                                    label: const Text('Horario'),
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: OutlinedButton.icon(
                                    style: OutlinedButton.styleFrom(
                                      foregroundColor: Colors.white,
                                      side: const BorderSide(
                                        color: Colors.white38,
                                      ),
                                      minimumSize: const Size.fromHeight(44),
                                    ),
                                    onPressed: () =>
                                        context.go(AppRoutes.sellerPromos),
                                    icon: const Icon(
                                      Icons.local_offer_outlined,
                                      size: 18,
                                    ),
                                    label: const Text('Promos'),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(
                AppTheme.pagePadding,
                16,
                AppTheme.pagePadding,
                0,
              ),
              child: Row(
                children: [
                  _Kpi(
                    label: 'Por aceptar',
                    value: '$pending',
                    color: AppColors.warning,
                  ),
                  const SizedBox(width: 10),
                  _Kpi(
                    label: 'Activas',
                    value: '${all.where((o) => o.status.isActive).length}',
                    color: AppColors.info,
                  ),
                  const SizedBox(width: 10),
                  _Kpi(
                    label: 'Vendido',
                    value: formatCop(today),
                    color: AppColors.success,
                  ),
                ],
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(
                AppTheme.pagePadding,
                20,
                AppTheme.pagePadding,
                12,
              ),
              child: Text('Órdenes', style: t.headlineSmall),
            ),
          ),
          SliverToBoxAdapter(
            child: ChoiceChipsRow(
              options: _tabs,
              selected: _tab,
              color: AppColors.seller,
              onSelected: (v) => setState(() => _tab = v),
            ),
          ),
          const SliverToBoxAdapter(child: SizedBox(height: 16)),
          if (orders.isEmpty)
            const SliverToBoxAdapter(
              child: EmptyState(
                icon: Icons.inbox_outlined,
                title: 'Sin órdenes aquí',
                message:
                    'Cuando lleguen pedidos nuevos aparecerán en esta lista.',
              ),
            )
          else
            SliverList.separated(
              itemCount: orders.length,
              separatorBuilder: (_, _) => const SizedBox(height: 12),
              itemBuilder: (_, i) => Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppTheme.pagePadding,
                ),
                child: _SellerOrderCard(order: orders[i]),
              ),
            ),
          const SliverToBoxAdapter(child: SizedBox(height: 24)),
        ],
      ),
    );
  }
}

class _Kpi extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  const _Kpi({required this.label, required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    return Expanded(
      child: SurfaceCard(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            FittedBox(
              child: Text(value, style: t.titleLarge?.copyWith(color: color)),
            ),
            Text(
              label,
              style: t.bodySmall,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}

class _SellerOrderCard extends StatelessWidget {
  final MarketOrder order;
  const _SellerOrderCard({required this.order});

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    final o = order;
    final cubit = context.read<MarketOrdersCubit>();
    final pickup = o.mode == FulfillmentMode.pickup;
    final action = switch (o.status) {
      OrderStatus.pending => 'Aceptar',
      OrderStatus.preparing => pickup ? 'Marcar listo' : 'Enviar pedido',
      OrderStatus.ready => 'Entregado (código ${o.pickupCode})',
      OrderStatus.onTheWay => 'Marcar entregado',
      _ => null,
    };

    return SurfaceCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Flexible(
                child: Text(
                  'Orden #${o.id}',
                  style: t.titleMedium,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 8),
              StatusChip(
                label: o.mode.label,
                color: pickup ? AppColors.info : AppColors.seller,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  DateFormat('h:mm a', 'es_CO').format(o.createdAt),
                  style: t.bodySmall,
                  textAlign: TextAlign.end,
                  maxLines: 1,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            '${o.customerName} · ${pickup ? 'Recoge en tu punto' : 'Entregar en ${MarketMockData.place(o.placeId).name}${o.notes.isEmpty ? '' : ' (${o.notes})'}'}',
            style: t.bodySmall,
          ),
          const SizedBox(height: 8),
          for (final l in o.lines)
            Text('${l.quantity} × ${l.name}', style: t.bodyMedium),
          if (o.couponCode.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text(
                'Cupón ${o.couponCode} (-${formatCop(o.couponDiscount)})',
                style: t.bodySmall?.copyWith(color: AppColors.success),
              ),
            ),
          const SizedBox(height: 10),
          Wrap(
            alignment: WrapAlignment.spaceBetween,
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: 8,
            runSpacing: 8,
            children: [
              Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(formatCop(o.total), style: t.titleLarge),
                  Text(o.paymentLabel, style: t.bodySmall),
                ],
              ),
              Wrap(
                spacing: 4,
                runSpacing: 4,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  if (o.status == OrderStatus.pending)
                    TextButton(
                      style: TextButton.styleFrom(
                        foregroundColor: AppColors.danger,
                      ),
                      onPressed: () => cubit.cancel(o.id),
                      child: const Text('Rechazar'),
                    ),
                  if (action != null)
                    FilledButton(
                      style: FilledButton.styleFrom(
                        backgroundColor: AppColors.seller,
                        minimumSize: const Size(0, 42),
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                      ),
                      onPressed: () {
                        cubit.advance(o.id);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              'Orden #${o.id}: ${cubit.byId(o.id)!.status.label.toLowerCase()}. El cliente ya lo ve.',
                            ),
                          ),
                        );
                      },
                      child: Text(action),
                    )
                  else
                    StatusChip.forOrder(o.status.label),
                ],
              ),
            ],
          ),
          if (o.rating != null) ...[
            const Divider(height: 20),
            Row(
              children: [
                ...List.generate(
                  5,
                  (i) => Icon(
                    i < o.rating!
                        ? Icons.star_rounded
                        : Icons.star_outline_rounded,
                    size: 16,
                    color: AppColors.accent,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    o.review.isEmpty
                        ? o.reviewTags.join(', ')
                        : '“${o.review}”',
                    style: t.bodySmall,
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}
