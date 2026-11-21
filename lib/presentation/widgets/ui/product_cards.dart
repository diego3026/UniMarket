import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../constants/app_colors.dart';
import '../../../core/router/app_routes.dart';
import '../../../core/utils/formatters.dart';
import '../../../domain/entities/product_entity.dart';
import '../../../domain/entities/store_entity.dart';
import '../../viewmodels/cart/cart_cubit.dart';
import '../../viewmodels/favorites/favorites_cubit.dart';
import '../../viewmodels/market/market_cubits.dart';
import 'app_widgets.dart';
import 'product_image.dart';

/// Precio con descuento tachado si aplica.
class PriceTag extends StatelessWidget {
  final ProductEntity product;
  final double fontSize;

  const PriceTag({super.key, required this.product, this.fontSize = 16});

  @override
  Widget build(BuildContext context) {
    final c = Theme.of(context).colorScheme.primary;
    return Wrap(
      crossAxisAlignment: WrapCrossAlignment.center,
      spacing: 6,
      children: [
        Text(
          formatCop(product.finalPrice),
          style: TextStyle(
            fontSize: fontSize,
            fontWeight: FontWeight.w800,
            color: c,
          ),
        ),
        if (product.isOnSale)
          Text(
            formatCop(product.price),
            style: TextStyle(
              fontSize: fontSize * 0.75,
              color: AppColors.textMuted,
              decoration: TextDecoration.lineThrough,
            ),
          ),
      ],
    );
  }
}

/// Corazón de favorito conectado a [FavoritesCubit].
class FavoriteButton extends StatelessWidget {
  final ProductEntity product;
  final double size;

  const FavoriteButton({super.key, required this.product, this.size = 36});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<FavoritesCubit, FavoritesState>(
      builder: (context, _) {
        final fav = context.read<FavoritesCubit>().isFavorite(product.id);
        return CircleIconButton(
          size: size,
          tooltip: fav ? 'Quitar de favoritos' : 'Agregar a favoritos',
          icon: fav ? Icons.favorite_rounded : Icons.favorite_border_rounded,
          color: fav ? AppColors.danger : AppColors.textPrimary,
          onPressed: () =>
              context.read<FavoritesCubit>().toggleFavorite(product),
        );
      },
    );
  }
}

void addToCartWithFeedback(BuildContext context, ProductEntity product) {
  context.read<CartCubit>().addToCart(product);
  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(
      SnackBar(
        content: Text('${product.name} agregado a tu bolsa'),
        action: SnackBarAction(
          label: 'Ver bolsa',
          textColor: AppColors.accent,
          onPressed: () => context.push(AppRoutes.cart),
        ),
      ),
    );
}

/// Tarjeta vertical de producto para grillas.
class ProductTile extends StatelessWidget {
  final ProductEntity product;

  const ProductTile({super.key, required this.product});

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    final c = Theme.of(context).colorScheme.primary;
    return SurfaceCard(
      padding: const EdgeInsets.all(8),
      onTap: () =>
          context.push(AppRoutes.productPath(product.id), extra: product),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Stack(
              children: [
                Positioned.fill(
                  child: ProductImage(
                    imageUrl: product.imageUrl,
                    category: product.category,
                    radius: 12,
                  ),
                ),
                Positioned(
                  top: 6,
                  right: 6,
                  child: FavoriteButton(product: product, size: 32),
                ),
                if (product.isOnSale)
                  Positioned(
                    top: 8,
                    left: 8,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.accent,
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Text(
                        '-${product.discountPercentage.round()}%',
                        style: const TextStyle(
                          fontWeight: FontWeight.w800,
                          fontSize: 11,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  product.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: t.titleSmall,
                ),
                const SizedBox(height: 2),
                Text(
                  product.storeName.isEmpty
                      ? product.category
                      : product.storeName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: t.bodySmall,
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    Expanded(child: PriceTag(product: product, fontSize: 14)),
                    Material(
                      color: c,
                      borderRadius: BorderRadius.circular(10),
                      child: InkWell(
                        borderRadius: BorderRadius.circular(10),
                        onTap: () => addToCartWithFeedback(context, product),
                        child: const Padding(
                          padding: EdgeInsets.all(6),
                          child: Icon(
                            Icons.add_rounded,
                            color: Colors.white,
                            size: 20,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Fila horizontal de producto (listas de menú, búsqueda, favoritos).
class ProductRow extends StatelessWidget {
  final ProductEntity product;
  final Widget? trailing;

  const ProductRow({super.key, required this.product, this.trailing});

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    return SurfaceCard(
      padding: const EdgeInsets.all(10),
      onTap: () =>
          context.push(AppRoutes.productPath(product.id), extra: product),
      child: Row(
        children: [
          ProductImage(
            imageUrl: product.imageUrl,
            category: product.category,
            width: 84,
            height: 84,
            radius: 12,
            iconSize: 28,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  product.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: t.titleSmall,
                ),
                const SizedBox(height: 2),
                Text(
                  product.description,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: t.bodySmall,
                ),
                const SizedBox(height: 6),
                PriceTag(product: product, fontSize: 14),
              ],
            ),
          ),
          trailing ??
              IconButton.filledTonal(
                tooltip: 'Agregar a la bolsa',
                onPressed: () => addToCartWithFeedback(context, product),
                icon: const Icon(Icons.add_shopping_cart_rounded, size: 20),
              ),
        ],
      ),
    );
  }
}

/// Tarjeta de emprendimiento (Figma: "Emprendimientos Populares").
class StoreCard extends StatelessWidget {
  final StoreEntity store;
  final double width;

  const StoreCard({super.key, required this.store, this.width = 240});

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    return SizedBox(
      width: width,
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () => context.push(AppRoutes.storePath(store.id)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Stack(
              children: [
                ProductImage(
                  imageUrl: store.imageUrl,
                  category: store.category,
                  height: 130,
                  width: width,
                ),
                if (!context.watch<StoreSettingsCubit>().of(store.id).isOpen)
                  Positioned.fill(
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.black45,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      alignment: Alignment.center,
                      child: const Text(
                        'Cerrado',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  ),
                Positioned(
                  right: 8,
                  bottom: 8,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: RatingBadge(rating: store.rating),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              store.name,
              style: t.titleMedium,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 2),
            Row(
              children: [
                Text(
                  store.category,
                  style: t.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
                const Text(
                  '  ·  ',
                  style: TextStyle(color: AppColors.textMuted),
                ),
                const Icon(
                  Icons.schedule_rounded,
                  size: 14,
                  color: AppColors.textMuted,
                ),
                const SizedBox(width: 3),
                Text('${store.deliveryMinutes} min', style: t.bodySmall),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// Banner promocional con degradado (Figma: "50-40% OFF").
class PromoBanner extends StatelessWidget {
  final String title;
  final String subtitle;
  final String cta;
  final IconData icon;
  final Gradient gradient;
  final VoidCallback? onTap;

  const PromoBanner({
    super.key,
    required this.title,
    required this.subtitle,
    this.cta = 'Ver ahora',
    this.icon = Icons.shopping_bag_rounded,
    this.gradient = AppColors.bannerGradient,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: gradient,
        borderRadius: BorderRadius.circular(20),
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        children: [
          Positioned(
            right: -20,
            bottom: -30,
            child: Icon(
              icon,
              size: 170,
              color: Colors.white.withValues(alpha: 0.18),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 4),
                Expanded(
                  child: SizedBox(
                    width: 210,
                    child: Text(
                      subtitle,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 13,
                      ),
                    ),
                  ),
                ),
                OutlinedButton.icon(
                  onPressed: onTap,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.white,
                    side: const BorderSide(color: Colors.white),
                    minimumSize: const Size(0, 36),
                    padding: const EdgeInsets.symmetric(horizontal: 14),
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  icon: const Icon(Icons.arrow_forward_rounded, size: 18),
                  label: Text(cta),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
