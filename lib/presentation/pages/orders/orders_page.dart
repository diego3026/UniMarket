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
import '../../viewmodels/profile/profile_cubit.dart';
import '../../viewmodels/profile/profile_state.dart';
import '../../widgets/ui/app_widgets.dart';
import '../../widgets/ui/product_image.dart';

/// Pedidos del cliente (Figma: "Mis pedidos").
class OrdersPage extends StatefulWidget {
  final bool deliveredOnly;
  const OrdersPage({super.key, this.deliveredOnly = false});

  @override
  State<OrdersPage> createState() => _OrdersPageState();
}

class _OrdersPageState extends State<OrdersPage> {
  static const _tabs = ['En curso', 'Entregados', 'Cancelados'];
  late String _tab = widget.deliveredOnly ? 'Entregados' : 'En curso';

  bool _match(MarketOrder o) => switch (_tab) {
    'Entregados' => o.status == OrderStatus.delivered,
    'Cancelados' => o.status == OrderStatus.cancelled,
    _ => o.status.isActive,
  };

  @override
  Widget build(BuildContext context) {
    final profile = context.watch<ProfileCubit>().state;
    final name = profile is ProfileLoaded ? profile.user.name : '';
    final all = context.watch<MarketOrdersCubit>().forCustomer(name);
    final orders = all.where(_match).toList();
    final active = all.where((o) => o.status.isActive).length;

    return Scaffold(
      appBar: context.canPop() ? AppBar() : null,
      body: SafeArea(
        bottom: false,
        child: ListView(
          padding: const EdgeInsets.only(bottom: 24),
          children: [
            PageTitle(
              title: 'Mis pedidos',
              subtitle: active > 0 ? '$active en curso' : null,
            ),
            ChoiceChipsRow(
              options: _tabs,
              selected: _tab,
              onSelected: (t) => setState(() => _tab = t),
            ),
            const SizedBox(height: 16),
            if (orders.isEmpty)
              EmptyState(
                icon: Icons.receipt_long_outlined,
                title: 'Nada por aquí',
                message: _tab == 'En curso'
                    ? 'Cuando hagas un pedido podrás seguirlo desde aquí.'
                    : 'No tienes pedidos en esta sección.',
                actionLabel: _tab == 'En curso' ? 'Hacer un pedido' : null,
                onAction: () => context.go(AppRoutes.home),
              )
            else
              for (final o in orders)
                Padding(
                  padding: const EdgeInsets.fromLTRB(
                    AppTheme.pagePadding,
                    0,
                    AppTheme.pagePadding,
                    12,
                  ),
                  child: _OrderCard(order: o),
                ),
          ],
        ),
      ),
    );
  }
}

class _OrderCard extends StatelessWidget {
  final MarketOrder order;
  const _OrderCard({required this.order});

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    final o = order;
    final steps = o.flow;
    final progress = o.status == OrderStatus.cancelled
        ? 0.0
        : (steps.indexOf(o.status) + 1) / steps.length;

    return SurfaceCard(
      onTap: () => context.push(AppRoutes.orderTrackingPath(o.id)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              ClipOval(
                child: ProductImage(
                  imageUrl: '',
                  category: o.category,
                  width: 52,
                  height: 52,
                  radius: 0,
                  iconSize: 22,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(o.storeName, style: t.titleMedium),
                    Text(
                      '#${o.id} · ${DateFormat("d MMM, h:mm a", 'es_CO').format(o.createdAt)}',
                      style: t.bodySmall,
                    ),
                  ],
                ),
              ),
              StatusChip.forOrder(o.status.label),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Icon(
                o.mode == FulfillmentMode.pickup
                    ? Icons.storefront_rounded
                    : Icons.delivery_dining_rounded,
                size: 16,
                color: AppColors.textSecondary,
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  '${o.mode.label} · ${o.itemCount} ${o.itemCount == 1 ? 'producto' : 'productos'}',
                  style: t.bodySmall,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                formatCop(o.total),
                style: t.titleMedium?.copyWith(color: AppColors.primary),
              ),
            ],
          ),
          if (o.status.isActive) ...[
            const SizedBox(height: 12),
            ClipRRect(
              borderRadius: BorderRadius.circular(999),
              child: LinearProgressIndicator(
                value: progress,
                minHeight: 6,
                backgroundColor: AppColors.surfaceMuted,
              ),
            ),
            const SizedBox(height: 10),
            Wrap(
              alignment: WrapAlignment.spaceBetween,
              crossAxisAlignment: WrapCrossAlignment.center,
              spacing: 8,
              runSpacing: 8,
              children: [
                if (o.mode == FulfillmentMode.pickup)
                  Text(
                    'Código: ${o.pickupCode}',
                    style: t.titleSmall?.copyWith(color: AppColors.primary),
                  ),
                FilledButton.tonalIcon(
                  style: FilledButton.styleFrom(minimumSize: const Size(0, 40)),
                  onPressed: () =>
                      context.push(AppRoutes.orderTrackingPath(o.id)),
                  icon: const Icon(Icons.track_changes_rounded, size: 18),
                  label: const Text('Seguir pedido'),
                ),
              ],
            ),
          ],
          if (o.status == OrderStatus.delivered) ...[
            const SizedBox(height: 10),
            Row(
              children: [
                if (o.rating != null)
                  ...List.generate(
                    5,
                    (i) => Icon(
                      i < o.rating!
                          ? Icons.star_rounded
                          : Icons.star_outline_rounded,
                      size: 18,
                      color: AppColors.accent,
                    ),
                  )
                else
                  OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      minimumSize: const Size(0, 40),
                    ),
                    onPressed: () =>
                        context.push(AppRoutes.orderReviewPath(o.id)),
                    icon: const Icon(Icons.star_outline_rounded, size: 18),
                    label: const Text('Calificar'),
                  ),
                const Spacer(),
                TextButton(
                  onPressed: () => context.push(AppRoutes.storePath(o.storeId)),
                  child: const Text('Volver a pedir'),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}
