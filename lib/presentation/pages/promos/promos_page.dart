import 'package:unimarket/presentation/viewmodels/catalog/catalog_cubit.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../constants/app_colors.dart';
import '../../../core/router/app_routes.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/formatters.dart';
import '../../../domain/entities/market_entities.dart';
import '../../../domain/entities/product_entity.dart';
import '../../viewmodels/market/market_cubits.dart';
import '../../viewmodels/product/product_cubit.dart';
import '../../widgets/ui/app_widgets.dart';
import '../../widgets/ui/product_cards.dart';

/// Promociones activas (Figma: "Promos").
class PromosPage extends StatefulWidget {
  const PromosPage({super.key});

  @override
  State<PromosPage> createState() => _PromosPageState();
}

class _PromosPageState extends State<PromosPage> {
  String _filter = 'Todas';

  @override
  Widget build(BuildContext context) {
    context.watch<CatalogCubit>(); // se reconstruye cuando llegan los datos de la API
    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: BlocBuilder<ProductCubit, ProductState>(
          builder: (context, state) {
            final all = state is ProductLoaded
                ? state.products.where((p) => p.isOnSale).toList()
                : <ProductEntity>[];
            all.sort(
              (a, b) => b.discountPercentage.compareTo(a.discountPercentage),
            );
            final categories = {
              'Todas',
              ...all.map((p) => p.category),
            }.toList();
            final items = all
                .where((p) => _filter == 'Todas' || p.category == _filter)
                .toList();

            return CustomScrollView(
              slivers: [
                const SliverToBoxAdapter(
                  child: PageTitle(
                    title: 'Promos',
                    subtitle: 'Descuentos de emprendedores del campus',
                  ),
                ),
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppTheme.pagePadding,
                    ),
                    child: SizedBox(
                      height: 160,
                      child: PromoBanner(
                        title: all.isEmpty
                            ? 'Promos del campus'
                            : 'Hasta ${all.first.discountPercentage.round()} % OFF',
                        subtitle: all.isEmpty
                            ? 'Pronto habrá nuevas ofertas'
                            : '${all.first.name} en ${all.first.storeName}',
                        icon: Icons.local_offer_rounded,
                        cta: 'Ver la mejor',
                        onTap: all.isEmpty
                            ? null
                            : () => context.push(
                                AppRoutes.productPath(all.first.id),
                                extra: all.first,
                              ),
                      ),
                    ),
                  ),
                ),
                const SliverToBoxAdapter(child: SizedBox(height: 20)),
                const SliverToBoxAdapter(child: _CouponsStrip()),
                SliverToBoxAdapter(
                  child: ChoiceChipsRow(
                    options: categories,
                    selected: _filter,
                    onSelected: (c) => setState(() => _filter = c),
                    color: AppColors.primary,
                  ),
                ),
                const SliverToBoxAdapter(child: SizedBox(height: 16)),
                if (state is ProductLoading)
                  const SliverToBoxAdapter(
                    child: Padding(
                      padding: EdgeInsets.all(40),
                      child: Center(child: CircularProgressIndicator()),
                    ),
                  )
                else if (items.isEmpty)
                  const SliverToBoxAdapter(
                    child: EmptyState(
                      icon: Icons.local_offer_outlined,
                      title: 'Sin promociones por ahora',
                      message:
                          'Vuelve pronto: los emprendedores publican ofertas cada semana.',
                    ),
                  )
                else
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(
                      AppTheme.pagePadding,
                      0,
                      AppTheme.pagePadding,
                      24,
                    ),
                    sliver: SliverGrid(
                      gridDelegate:
                          const SliverGridDelegateWithMaxCrossAxisExtent(
                            maxCrossAxisExtent: 220,
                            mainAxisExtent: 250,
                            crossAxisSpacing: 12,
                            mainAxisSpacing: 12,
                          ),
                      delegate: SliverChildBuilderDelegate(
                        (_, i) => ProductTile(product: items[i]),
                        childCount: items.length,
                      ),
                    ),
                  ),
              ],
            );
          },
        ),
      ),
    );
  }
}

/// Cupones activos de todos los emprendimientos.
class _CouponsStrip extends StatelessWidget {
  const _CouponsStrip();

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    final coupons = context
        .watch<PromotionsCubit>()
        .state
        .where((p) => p.kind == PromotionKind.coupon && p.isRunning)
        .toList();
    if (coupons.isEmpty) return const SizedBox.shrink();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SectionHeader(title: 'Cupones para usar al pagar'),
        const SizedBox(height: 8),
        SizedBox(
          // Crece con el tamaño de letra del sistema para no recortar.
          height: MediaQuery.textScalerOf(context).scale(112),
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(
              horizontal: AppTheme.pagePadding,
            ),
            itemCount: coupons.length,
            separatorBuilder: (_, _) => const SizedBox(width: 12),
            itemBuilder: (context, i) {
              final c = coupons[i];
              final store = Catalog.storeById(c.storeId);
              return SizedBox(
                width: 250,
                child: SurfaceCard(
                  padding: const EdgeInsets.all(12),
                  onTap: () {
                    Clipboard.setData(ClipboardData(text: c.code));
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Código ${c.code} copiado'),
                        action: SnackBarAction(
                          label: 'Ir a la tienda',
                          textColor: AppColors.accent,
                          onPressed: () =>
                              context.push(AppRoutes.storePath(c.storeId)),
                        ),
                      ),
                    );
                  },
                  child: Row(
                    children: [
                      Container(
                        width: 54,
                        height: double.infinity,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: AppColors.successLight,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          c.valueLabel.replaceAll(' ', ''),
                          textAlign: TextAlign.center,
                          style: t.labelLarge?.copyWith(
                            color: AppColors.success,
                            fontSize: 12,
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              c.code,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: t.titleMedium?.copyWith(letterSpacing: 1),
                            ),
                            Text(
                              store?.name ?? '',
                              style: t.bodySmall,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            if (c.minPurchase > 0)
                              Text(
                                'Mínimo ${formatCop(c.minPurchase)}',
                                style: t.bodySmall,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                          ],
                        ),
                      ),
                      const Icon(
                        Icons.copy_rounded,
                        size: 18,
                        color: AppColors.textMuted,
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 20),
      ],
    );
  }
}
