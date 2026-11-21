import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../constants/app_colors.dart';
import '../../../core/router/app_routes.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/formatters.dart';
import '../../../domain/entities/product_entity.dart';
import '../../viewmodels/product/product_cubit.dart';
import '../../widgets/ui/app_widgets.dart';
import '../../widgets/ui/product_image.dart';
import 'seller_mock.dart';

/// Menú / catálogo del emprendedor (Figma Emprendedor: "Menu").
class SellerMenuPage extends StatefulWidget {
  const SellerMenuPage({super.key});

  @override
  State<SellerMenuPage> createState() => _SellerMenuPageState();
}

class _SellerMenuPageState extends State<SellerMenuPage> {
  final Set<String> _hidden = {};

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    final store = SellerMock.store;
    return Scaffold(
      floatingActionButton: FloatingActionButton.extended(
        heroTag: null,
        onPressed: () => context.push(AppRoutes.sellerNewProduct),
        icon: const Icon(Icons.add_rounded),
        label: const Text('Nuevo producto'),
      ),
      body: SafeArea(
        bottom: false,
        child: BlocBuilder<ProductCubit, ProductState>(
          builder: (context, state) {
            final products = state is ProductLoaded
                ? state.products.where((p) => p.storeId == store.id).toList()
                : <ProductEntity>[];
            return ListView(
              padding: const EdgeInsets.only(bottom: 100),
              children: [
                PageTitle(
                  title: 'Menú',
                  subtitle: '${products.length} productos publicados',
                ),
                if (products.isEmpty)
                  EmptyState(
                    icon: Icons.restaurant_menu_rounded,
                    title: 'Aún no tienes productos',
                    message:
                        'Publica tu primer producto para empezar a vender.',
                    actionLabel: 'Crear producto',
                    onAction: () => context.push(AppRoutes.sellerNewProduct),
                  )
                else
                  ...products.map((p) {
                    final visible = !_hidden.contains(p.id);
                    return Padding(
                      padding: const EdgeInsets.fromLTRB(
                        AppTheme.pagePadding,
                        0,
                        AppTheme.pagePadding,
                        12,
                      ),
                      child: SurfaceCard(
                        padding: const EdgeInsets.all(10),
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
                                  Text(
                                    p.name,
                                    style: t.titleSmall,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    formatCop(p.finalPrice),
                                    style: t.titleSmall?.copyWith(
                                      color: AppColors.seller,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    visible
                                        ? 'Visible para clientes'
                                        : 'Oculto',
                                    style: t.bodySmall?.copyWith(
                                      color: visible
                                          ? AppColors.success
                                          : AppColors.textMuted,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Switch(
                              value: visible,
                              onChanged: (v) => setState(
                                () => v
                                    ? _hidden.remove(p.id)
                                    : _hidden.add(p.id),
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  }),
              ],
            );
          },
        ),
      ),
    );
  }
}
