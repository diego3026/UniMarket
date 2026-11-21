import 'package:unimarket/presentation/viewmodels/catalog/catalog_cubit.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../constants/app_colors.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/formatters.dart';
import '../../viewmodels/market/market_cubits.dart';
import '../../widgets/ui/campus_map.dart';
import '../../../domain/entities/product_entity.dart';
import '../../viewmodels/product/product_cubit.dart';
import '../../widgets/ui/app_widgets.dart';
import '../../widgets/ui/product_cards.dart';
import '../../widgets/ui/product_image.dart';

/// Perfil público de un emprendimiento (Figma: "Restaurante").
class StorePage extends StatefulWidget {
  final String storeId;
  const StorePage({super.key, required this.storeId});

  @override
  State<StorePage> createState() => _StorePageState();
}

class _StorePageState extends State<StorePage> {
  String _section = 'Todo';

  @override
  Widget build(BuildContext context) {
    context.watch<CatalogCubit>(); // se reconstruye cuando llegan los datos de la API
    final store = Catalog.storeById(widget.storeId);
    final t = Theme.of(context).textTheme;
    if (store == null) {
      return Scaffold(
        appBar: AppBar(),
        body: const EmptyState(
          icon: Icons.storefront_rounded,
          title: 'Emprendimiento no encontrado',
          message: 'Puede que ya no esté disponible en UniMarket.',
        ),
      );
    }

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 260,
            pinned: true,
            backgroundColor: AppColors.background,
            leading: Padding(
              padding: const EdgeInsets.all(6),
              child: CircleIconButton(
                icon: Icons.arrow_back_ios_new_rounded,
                tooltip: 'Volver',
                size: 40,
                onPressed: () => context.pop(),
              ),
            ),
            flexibleSpace: FlexibleSpaceBar(
              background: ProductImage(
                imageUrl: store.imageUrl,
                category: store.category,
                radius: 0,
                iconSize: 72,
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
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(child: Text(store.name, style: t.headlineSmall)),
                      RatingBadge(rating: store.rating),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    store.description,
                    style: t.bodyMedium?.copyWith(
                      color: AppColors.textSecondary,
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: 14),
                  _StoreInfo(
                    storeId: store.id,
                    storeName: store.name,
                    schedule: store.schedule,
                  ),
                ],
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: ChoiceChipsRow(
              options: ['Todo', ...store.menuSections],
              selected: _section,
              onSelected: (s) => setState(() => _section = s),
            ),
          ),
          const SliverToBoxAdapter(child: SizedBox(height: 16)),
          BlocBuilder<ProductCubit, ProductState>(
            builder: (context, state) {
              final List<ProductEntity> products = state is ProductLoaded
                  ? state.products.where((p) => p.storeId == store.id).toList()
                  : <ProductEntity>[];
              if (products.isEmpty) {
                return const SliverToBoxAdapter(
                  child: EmptyState(
                    icon: Icons.restaurant_menu_rounded,
                    title: 'Menú vacío',
                    message:
                        'Este emprendimiento aún no ha publicado productos.',
                  ),
                );
              }
              return SliverPadding(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppTheme.pagePadding,
                ),
                sliver: SliverGrid(
                  gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                    maxCrossAxisExtent: 220,
                    mainAxisExtent: 250,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                  ),
                  delegate: SliverChildBuilderDelegate(
                    (_, i) => ProductTile(product: products[i]),
                    childCount: products.length,
                  ),
                ),
              );
            },
          ),
          const SliverToBoxAdapter(child: SizedBox(height: 32)),
        ],
      ),
    );
  }
}

class _InfoPill extends StatelessWidget {
  final IconData icon;
  final String text;
  const _InfoPill({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 16, color: AppColors.textSecondary),
        const SizedBox(width: 4),
        Flexible(
          child: Text(
            text,
            style: Theme.of(context).textTheme.bodySmall,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}

/// Información que configura el emprendedor: estado, entrega, recogida,
/// pagos y cupones activos.
class _StoreInfo extends StatelessWidget {
  final String storeId;
  final String storeName;
  final String schedule;
  const _StoreInfo({
    required this.storeId,
    required this.storeName,
    required this.schedule,
  });

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    final s = context.watch<StoreSettingsCubit>().of(storeId);
    final coupons = context.watch<PromotionsCubit>().activeCoupons(storeId);
    final place = Catalog.place(s.pickupPlaceId);
    final pays = [
      if (s.acceptsCash) 'Efectivo',
      if (s.acceptsNequi) 'Nequi',
      if (s.acceptsCard) 'Tarjeta',
    ];

    Widget line(IconData icon, String text) => Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: AppColors.textSecondary),
          const SizedBox(width: 8),
          Expanded(child: Text(text, style: t.bodyMedium)),
        ],
      ),
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            StatusChip(
              label: s.isOpen ? 'Abierto ahora' : 'Cerrado',
              color: s.isOpen ? AppColors.success : AppColors.danger,
            ),
            _InfoPill(
              icon: Icons.timer_outlined,
              text: 'Listo en ~${s.prepMinutes} min',
            ),
            _InfoPill(icon: Icons.calendar_month_outlined, text: schedule),
          ],
        ),
        const SizedBox(height: 14),
        SurfaceCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CampusMap(
                height: 150,
                radius: 14,
                selectedPlaceId: s.pickupPlaceId,
                pins: [
                  MapPin(
                    placeId: s.pickupPlaceId,
                    icon: Icons.storefront_rounded,
                    color: AppColors.primary,
                    label: storeName,
                  ),
                ],
              ),
              const SizedBox(height: 10),
              if (s.allowsPickup)
                line(
                  Icons.storefront_rounded,
                  'Recoge en ${place.name}${s.pickupNotes.isEmpty ? '' : ' · ${s.pickupNotes}'}',
                ),
              line(
                Icons.delivery_dining_rounded,
                s.allowsDelivery
                    ? 'Domicilio en el campus: ${s.deliveryFee == 0 ? 'gratis' : formatCop(s.deliveryFee)}${s.minOrder > 0 ? ' · pedido mínimo ${formatCop(s.minOrder)}' : ''}'
                    : 'No hace domicilios, solo para recoger',
              ),
              line(Icons.wallet_rounded, 'Recibe: ${pays.join(', ')}'),
            ],
          ),
        ),
        if (coupons.isNotEmpty) ...[
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final c in coupons)
                ActionChip(
                  avatar: const Icon(
                    Icons.confirmation_number_outlined,
                    size: 18,
                    color: AppColors.success,
                  ),
                  label: Text('Cupón ${c.code} · ${c.valueLabel}'),
                  onPressed: () {
                    Clipboard.setData(ClipboardData(text: c.code));
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          'Código ${c.code} copiado. Úsalo al finalizar tu compra.',
                        ),
                      ),
                    );
                  },
                ),
            ],
          ),
        ],
      ],
    );
  }
}
