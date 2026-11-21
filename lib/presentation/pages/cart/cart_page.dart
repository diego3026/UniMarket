import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../constants/app_colors.dart';
import '../../../core/router/app_routes.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/formatters.dart';
import '../../models/cart_item.dart';
import '../../viewmodels/cart/cart_cubit.dart';
import '../../viewmodels/market/market_cubits.dart';
import '../../widgets/ui/app_widgets.dart';
import '../../widgets/ui/product_image.dart';

/// Datos que la bolsa le pasa al checkout: el pedido es por emprendimiento.
class CheckoutArgs {
  final String storeId;
  final String storeName;

  const CheckoutArgs({required this.storeId, required this.storeName});
}

/// Bolsa de compras (Figma: "Mi Bolsa"), agrupada por emprendimiento,
/// porque cada tienda prepara y entrega su propio pedido.
class CartPage extends StatelessWidget {
  const CartPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        actions: [
          BlocBuilder<CartCubit, CartState>(
            builder: (context, state) =>
                state is CartLoaded && state.items.isNotEmpty
                ? TextButton(
                    onPressed: () => _confirmClear(context),
                    child: const Text('Vaciar'),
                  )
                : const SizedBox.shrink(),
          ),
        ],
      ),
      body: BlocBuilder<CartCubit, CartState>(
        builder: (context, state) {
          final items = state is CartLoaded ? state.items : <CartItem>[];
          final groups = <String, List<CartItem>>{};
          for (final i in items) {
            groups.putIfAbsent(i.product.storeId, () => []).add(i);
          }
          return ListView(
            padding: const EdgeInsets.only(bottom: 32),
            children: [
              PageTitle(
                title: 'Mi bolsa',
                subtitle: groups.length > 1
                    ? 'Tienes productos de ${groups.length} emprendimientos: cada uno se pide por separado.'
                    : null,
              ),
              if (items.isEmpty)
                EmptyState(
                  icon: Icons.shopping_bag_outlined,
                  title: 'Tu bolsa está vacía',
                  message:
                      'Explora los emprendimientos del campus y agrega lo que te guste.',
                  actionLabel: 'Explorar productos',
                  onAction: () => context.go(AppRoutes.home),
                )
              else
                for (final e in groups.entries)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(
                      AppTheme.pagePadding,
                      0,
                      AppTheme.pagePadding,
                      16,
                    ),
                    child: _StoreGroup(storeId: e.key, items: e.value),
                  ),
            ],
          );
        },
      ),
    );
  }

  Future<void> _confirmClear(BuildContext context) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('¿Vaciar tu bolsa?'),
        content: const Text('Se quitarán todos los productos que agregaste.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Conservar'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.danger,
              minimumSize: const Size(0, 44),
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Vaciar bolsa'),
          ),
        ],
      ),
    );
    if (ok == true && context.mounted) context.read<CartCubit>().clearCart();
  }
}

class _StoreGroup extends StatelessWidget {
  final String storeId;
  final List<CartItem> items;
  const _StoreGroup({required this.storeId, required this.items});

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    final settings = context.watch<StoreSettingsCubit>().of(storeId);
    final storeName = items.first.product.storeName;
    final subtotal = items.fold<double>(0, (s, i) => s + i.totalPrice);
    final missing = settings.minOrder - subtotal;
    final blocked = !settings.isOpen || missing > 0;

    return SurfaceCard(
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          InkWell(
            onTap: () => context.push(AppRoutes.storePath(storeId)),
            child: Row(
              children: [
                const Icon(Icons.storefront_rounded, color: AppColors.primary),
                const SizedBox(width: 8),
                Expanded(child: Text(storeName, style: t.titleMedium)),
                StatusChip(
                  label: settings.isOpen ? 'Abierto' : 'Cerrado',
                  color: settings.isOpen ? AppColors.success : AppColors.danger,
                ),
              ],
            ),
          ),
          const SizedBox(height: 4),
          Text(
            [
              if (settings.allowsDelivery)
                'Domicilio ${settings.deliveryFee == 0 ? 'gratis' : formatCop(settings.deliveryFee)}',
              if (settings.allowsPickup) 'Recoger gratis',
              'Listo en ~${settings.prepMinutes} min',
            ].join(' · '),
            style: t.bodySmall,
          ),
          const Divider(height: 24),
          for (final i in items) _CartLine(item: i),
          const SizedBox(height: 4),
          Row(
            children: [
              Text(
                'Subtotal',
                style: t.bodyMedium?.copyWith(color: AppColors.textSecondary),
              ),
              const Spacer(),
              Text(formatCop(subtotal), style: t.titleMedium),
            ],
          ),
          if (missing > 0) ...[
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppColors.warningLight,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                'Agrega ${formatCop(missing)} más: el pedido mínimo de $storeName es ${formatCop(settings.minOrder)}.',
                style: t.bodySmall?.copyWith(color: AppColors.textPrimary),
              ),
            ),
          ],
          const SizedBox(height: 12),
          FilledButton(
            onPressed: blocked
                ? null
                : () => context.push(
                    AppRoutes.checkout,
                    extra: CheckoutArgs(storeId: storeId, storeName: storeName),
                  ),
            child: Text(
              settings.isOpen ? 'Pedir a $storeName' : 'Cerrado por ahora',
            ),
          ),
        ],
      ),
    );
  }
}

class _CartLine extends StatelessWidget {
  final CartItem item;
  const _CartLine({required this.item});

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    final p = item.product;
    final cart = context.read<CartCubit>();
    return Dismissible(
      key: ValueKey(p.id),
      direction: DismissDirection.endToStart,
      onDismissed: (_) => cart.removeFromCart(p.id),
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 16),
        color: AppColors.dangerLight,
        child: const Icon(
          Icons.delete_outline_rounded,
          color: AppColors.danger,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: Row(
          children: [
            ProductImage(
              imageUrl: p.imageUrl,
              category: p.category,
              width: 64,
              height: 64,
              radius: 12,
              iconSize: 24,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    p.name,
                    style: t.titleSmall,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  Row(
                    children: [
                      Text(
                        formatCop(p.finalPrice),
                        style: t.bodyMedium?.copyWith(
                          color: AppColors.primary,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      if (p.isOnSale) ...[
                        const SizedBox(width: 6),
                        Text(
                          formatCop(p.price),
                          style: t.bodySmall?.copyWith(
                            decoration: TextDecoration.lineThrough,
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
            QuantityStepper(
              value: item.quantity,
              onIncrement: () => cart.updateQuantity(p.id, item.quantity + 1),
              onDecrement: () => cart.updateQuantity(p.id, item.quantity - 1),
            ),
          ],
        ),
      ),
    );
  }
}
