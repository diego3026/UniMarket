import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../constants/app_colors.dart';
import '../../../core/router/app_routes.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/formatters.dart';
import '../../../domain/entities/product_entity.dart';
import '../../viewmodels/cart/cart_cubit.dart';
import '../../viewmodels/market/market_cubits.dart';
import '../../viewmodels/product/product_cubit.dart';
import '../../widgets/ui/app_widgets.dart';
import '../../widgets/ui/product_cards.dart';
import '../../widgets/ui/product_image.dart';

/// Detalle de producto (Figma: "Producto").
class ProductDetailPage extends StatefulWidget {
  final String productId;
  final ProductEntity? product;

  const ProductDetailPage({super.key, required this.productId, this.product});

  @override
  State<ProductDetailPage> createState() => _ProductDetailPageState();
}

class _ProductDetailPageState extends State<ProductDetailPage> {
  int _qty = 1;

  ProductEntity? _resolve(BuildContext context) {
    if (widget.product != null) return widget.product;
    final s = context.read<ProductCubit>().state;
    if (s is ProductLoaded) {
      for (final p in s.products) {
        if (p.id == widget.productId) return p;
      }
    }
    return null;
  }

  void _add(ProductEntity p) {
    final cart = context.read<CartCubit>();
    for (var i = 0; i < _qty; i++) {
      cart.addToCart(p);
    }
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text('Agregaste $_qty × ${p.name} a tu bolsa'),
          action: SnackBarAction(
            label: 'Ver bolsa',
            textColor: AppColors.accent,
            onPressed: () => context.push(AppRoutes.cart),
          ),
        ),
      );
  }

  @override
  Widget build(BuildContext context) {
    // Escucha el catálogo por si se abre la ruta directamente (enlace).
    final catalog = context.watch<ProductCubit>().state;
    final p = _resolve(context);
    final t = Theme.of(context).textTheme;
    if (p == null && (catalog is ProductLoading || catalog is ProductInitial)) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    if (p == null) {
      return Scaffold(
        appBar: AppBar(),
        body: const EmptyState(
          icon: Icons.inventory_2_outlined,
          title: 'Producto no disponible',
          message: 'Es posible que el emprendedor lo haya retirado.',
        ),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.surface,
      body: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: Stack(
              children: [
                ProductImage(
                  imageUrl: p.imageUrl,
                  category: p.category,
                  height: 340,
                  width: double.infinity,
                  radius: 0,
                  iconSize: 80,
                ),
                Positioned.fill(
                  child: SafeArea(
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          CircleIconButton(
                            icon: Icons.arrow_back_ios_new_rounded,
                            tooltip: 'Volver',
                            onPressed: () => context.pop(),
                          ),
                          const Spacer(),
                          FavoriteButton(product: p, size: 44),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(
                AppTheme.pagePadding,
                20,
                AppTheme.pagePadding,
                24,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(child: Text(p.name, style: t.headlineSmall)),
                      const SizedBox(width: 8),
                      RatingBadge(rating: p.rating),
                    ],
                  ),
                  const SizedBox(height: 6),
                  if (p.storeName.isNotEmpty)
                    InkWell(
                      onTap: () => context.push(AppRoutes.storePath(p.storeId)),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.storefront_rounded,
                            size: 18,
                            color: AppColors.primary,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            p.storeName,
                            style: t.titleSmall?.copyWith(
                              color: AppColors.primary,
                            ),
                          ),
                          const Icon(
                            Icons.chevron_right_rounded,
                            color: AppColors.primary,
                          ),
                        ],
                      ),
                    ),
                  const SizedBox(height: 16),
                  Text(
                    p.description,
                    style: t.bodyLarge?.copyWith(
                      color: AppColors.textSecondary,
                      height: 1.5,
                    ),
                  ),
                  const SizedBox(height: 20),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      StatusChip(label: p.category, color: AppColors.primary),
                      StatusChip(
                        label: p.hasStock ? 'Disponible' : 'Agotado',
                        color: p.hasStock
                            ? AppColors.success
                            : AppColors.danger,
                      ),
                      if (p.isOnSale)
                        StatusChip(
                          label:
                              context
                                  .read<PromotionsCubit>()
                                  .bestFor(p.storeId, p.id, p.price)
                                  ?.title ??
                              'En promoción',
                          color: AppColors.seller,
                        ),
                      if (p.isOnSale)
                        StatusChip(
                          label: 'Ahorras ${formatCop(p.price - p.finalPrice)}',
                          color: AppColors.warning,
                        ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  Row(
                    children: [
                      Text('Cantidad', style: t.titleMedium),
                      const Spacer(),
                      QuantityStepper(
                        value: _qty,
                        onIncrement: () => setState(() => _qty++),
                        onDecrement: () =>
                            setState(() => _qty = _qty > 1 ? _qty - 1 : 1),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: BottomActionBar(
        child: Row(
          children: [
            Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Precio', style: t.bodySmall),
                Text(
                  formatCop(p.finalPrice * _qty),
                  style: t.titleLarge?.copyWith(
                    color: AppColors.primary,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
            const SizedBox(width: 16),
            Expanded(
              child: FilledButton.icon(
                onPressed: p.hasStock ? () => _add(p) : null,
                icon: const Icon(Icons.shopping_bag_outlined),
                label: const Text('Agregar a la bolsa'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
