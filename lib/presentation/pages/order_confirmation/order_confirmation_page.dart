import 'package:unimarket/presentation/viewmodels/catalog/catalog_cubit.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../constants/app_colors.dart';
import '../../../core/router/app_routes.dart';
import '../../../core/utils/formatters.dart';
import '../../../domain/entities/market_entities.dart';
import '../../viewmodels/market/market_cubits.dart';

/// Pedido realizado (Figma: "Exitoso pedido").
class OrderConfirmationPage extends StatelessWidget {
  final String orderId;
  const OrderConfirmationPage({super.key, required this.orderId});

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    final o = context.watch<MarketOrdersCubit>().byId(orderId);
    if (o == null) return const Scaffold(body: SizedBox());
    final s = context.watch<StoreSettingsCubit>().of(o.storeId);
    final pickup = o.mode == FulfillmentMode.pickup;

    return Scaffold(
      backgroundColor: AppColors.surface,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              const Spacer(),
              TweenAnimationBuilder<double>(
                tween: Tween(begin: 0.4, end: 1),
                duration: const Duration(milliseconds: 600),
                curve: Curves.elasticOut,
                builder: (_, v, child) =>
                    Transform.scale(scale: v, child: child),
                child: Container(
                  width: 110,
                  height: 110,
                  decoration: const BoxDecoration(
                    color: AppColors.successLight,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.check_circle_rounded,
                    size: 72,
                    color: AppColors.success,
                  ),
                ),
              ),
              const SizedBox(height: 24),
              Text(
                '¡Pedido enviado!',
                style: t.headlineMedium,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                pickup
                    ? '${o.storeName} lo tendrá listo en ~${s.prepMinutes} min en ${Catalog.place(s.pickupPlaceId).name}.'
                    : '${o.storeName} confirmará tu pedido y te lo llevará a ${Catalog.place(o.placeId).name}.',
                style: t.bodyLarge?.copyWith(color: AppColors.textSecondary),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.background,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  children: [
                    _row(t, 'Pedido', '#${o.id}'),
                    if (pickup) _row(t, 'Código para recoger', o.pickupCode),
                    _row(t, 'Pago', o.paymentLabel),
                    _row(t, 'Total', formatCop(o.total)),
                  ],
                ),
              ),
              const Spacer(),
              FilledButton.icon(
                onPressed: () =>
                    context.pushReplacement(AppRoutes.orderTrackingPath(o.id)),
                icon: const Icon(Icons.track_changes_rounded),
                label: const Text('Seguir mi pedido'),
              ),
              const SizedBox(height: 8),
              TextButton(
                onPressed: () => context.go(AppRoutes.home),
                child: const Text('Volver al inicio'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _row(TextTheme t, String a, String b) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 4),
    child: Row(
      children: [
        Text(a, style: t.bodyMedium?.copyWith(color: AppColors.textSecondary)),
        const Spacer(),
        Text(b, style: t.titleSmall),
      ],
    ),
  );
}
