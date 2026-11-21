import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../constants/app_colors.dart';
import '../../../core/router/app_routes.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/formatters.dart';
import '../../viewmodels/market/seller_products_cubit.dart';
import '../../viewmodels/product/product_cubit.dart';
import '../../widgets/ui/app_widgets.dart';
import '../../widgets/ui/product_image.dart';

/// Menú / catálogo del emprendedor (Figma Emprendedor: "Menu").
class SellerMenuPage extends StatelessWidget {
  const SellerMenuPage({super.key});

  Future<void> _toggle(BuildContext context, SellerProduct p, bool v) async {
    final err = await context.read<SellerProductsCubit>().setAvailable(p.product.id, v);
    if (!context.mounted) return;
    if (err != null) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(err)));
    } else {
      context.read<ProductCubit>().loadProducts();
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    return Scaffold(
      floatingActionButton: FloatingActionButton.extended(
        heroTag: null,
        onPressed: () => context.push(AppRoutes.sellerNewProduct),
        icon: const Icon(Icons.add_rounded),
        label: const Text('Nuevo producto'),
      ),
      body: SafeArea(
        bottom: false,
        child: BlocBuilder<SellerProductsCubit, SellerProductsState>(
          builder: (context, state) {
            final products = state.items;
            final visibleCount = products.where((p) => p.isAvailable && !p.isHidden).length;
            return RefreshIndicator(
              onRefresh: () => context.read<SellerProductsCubit>().load(),
              child: ListView(
                padding: const EdgeInsets.only(bottom: 100),
                children: [
                  PageTitle(title: 'Menú', subtitle: '$visibleCount productos visibles'),
                  if (state.loading && products.isEmpty)
                    const Padding(padding: EdgeInsets.all(48), child: Center(child: CircularProgressIndicator()))
                  else if (state.error != null && products.isEmpty)
                    EmptyState(
                      icon: Icons.cloud_off_rounded,
                      title: 'No pudimos cargar tu menú',
                      message: state.error!,
                      actionLabel: 'Reintentar',
                      onAction: () => context.read<SellerProductsCubit>().load(),
                    )
                  else if (products.isEmpty)
                    EmptyState(
                      icon: Icons.restaurant_menu_rounded,
                      title: 'Aún no tienes productos',
                      message: 'Publica tu primer producto para empezar a vender.',
                      actionLabel: 'Crear producto',
                      onAction: () => context.push(AppRoutes.sellerNewProduct),
                    )
                  else
                    ...products.map((sp) {
                      final p = sp.product;
                      final visible = sp.isAvailable && !sp.isHidden;
                      return Padding(
                        padding: const EdgeInsets.fromLTRB(AppTheme.pagePadding, 0, AppTheme.pagePadding, 12),
                        child: SurfaceCard(
                          padding: const EdgeInsets.all(10),
                          child: InkWell(
                            onTap: () => context.push(AppRoutes.sellerNewProduct, extra: sp),
                            child: Row(
                              children: [
                                Opacity(
                                  opacity: visible ? 1 : 0.4,
                                  child: ProductImage(
                                    imageUrl: p.imageUrl,
                                    category: p.category,
                                    width: 72,
                                    height: 72,
                                    radius: 12,
                                    iconSize: 26,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(p.name, style: t.titleSmall, maxLines: 1, overflow: TextOverflow.ellipsis),
                                      const SizedBox(height: 2),
                                      Text(
                                        formatCop(p.finalPrice),
                                        style: t.titleSmall?.copyWith(color: AppColors.seller),
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        sp.isHidden
                                            ? 'Oculto por moderación'
                                            : visible
                                            ? 'Visible · ${p.stock} en stock'
                                            : 'Pausado',
                                        style: t.bodySmall?.copyWith(
                                          color: sp.isHidden
                                              ? AppColors.danger
                                              : visible
                                              ? AppColors.success
                                              : AppColors.textMuted,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                Switch(
                                  value: sp.isAvailable,
                                  onChanged: sp.isHidden ? null : (v) => _toggle(context, sp, v),
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    }),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}
