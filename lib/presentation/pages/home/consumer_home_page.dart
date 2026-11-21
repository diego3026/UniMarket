import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../constants/app_colors.dart';
import '../../../core/router/app_routes.dart';
import '../../../core/theme/app_theme.dart';
import '../../../data/datasources/mock/catalog_mock_data.dart';
import '../../../domain/entities/market_entities.dart';
import '../../viewmodels/market/market_cubits.dart';
import '../../viewmodels/notifications/notifications_cubit.dart';
import '../../widgets/ui/product_image.dart';
import '../../viewmodels/product/product_cubit.dart';
import '../../viewmodels/profile/profile_cubit.dart';
import '../../viewmodels/profile/profile_state.dart';
import '../../widgets/ui/app_widgets.dart';
import '../../widgets/ui/product_cards.dart';

/// Inicio del cliente (Figma: "Inicio").
class ConsumerHomePage extends StatefulWidget {
  const ConsumerHomePage({super.key});

  @override
  State<ConsumerHomePage> createState() => _ConsumerHomePageState();
}

class _ConsumerHomePageState extends State<ConsumerHomePage> {
  String _category = 'Todo';
  final _bannerController = PageController(viewportFraction: 0.92);
  int _banner = 0;

  @override
  void dispose() {
    _bannerController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: RefreshIndicator(
          onRefresh: () => context.read<ProductCubit>().loadProducts(),
          child: CustomScrollView(
            slivers: [
              const SliverToBoxAdapter(child: _HomeHeader()),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(
                    AppTheme.pagePadding,
                    4,
                    AppTheme.pagePadding,
                    16,
                  ),
                  child: AppSearchBar(
                    onTap: () => context.push(AppRoutes.search),
                  ),
                ),
              ),
              const SliverToBoxAdapter(child: _ActiveOrderBanner()),
              SliverToBoxAdapter(child: _banners()),
              const SliverToBoxAdapter(child: SizedBox(height: 24)),
              SliverToBoxAdapter(
                child: ChoiceChipsRow(
                  options: const ['Todo', ...CatalogMockData.categories],
                  selected: _category,
                  onSelected: (c) => setState(() => _category = c),
                ),
              ),
              const SliverToBoxAdapter(child: SizedBox(height: 20)),
              SliverToBoxAdapter(
                child: SectionHeader(
                  title: 'Emprendimientos populares',
                  actionLabel: 'Ver todo',
                  onAction: () => context.push(AppRoutes.search),
                ),
              ),
              SliverToBoxAdapter(child: _stores()),
              const SliverToBoxAdapter(child: SizedBox(height: 20)),
              const SliverToBoxAdapter(
                child: SectionHeader(title: 'Recomendados para ti'),
              ),
              const SliverToBoxAdapter(child: SizedBox(height: 8)),
              _productsGrid(),
              const SliverToBoxAdapter(child: SizedBox(height: 32)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _banners() {
    // Los banners salen de las promociones reales que crean los emprendedores.
    final promos =
        context
            .watch<PromotionsCubit>()
            .state
            .where((p) => p.isRunning)
            .toList()
          ..sort((x, y) => y.uses.compareTo(x.uses));
    const gradients = [
      AppColors.bannerGradient,
      LinearGradient(colors: [Color(0xFFFFB547), Color(0xFFFF7A00)]),
      LinearGradient(colors: [Color(0xFF3B82F6), Color(0xFF4320A2)]),
    ];
    final banners = [
      for (final (i, p) in promos.take(3).indexed)
        () {
          final store = CatalogMockData.storeById(p.storeId);
          final isCoupon = p.kind == PromotionKind.coupon;
          return PromoBanner(
            title: isCoupon ? 'Cupón ${p.code}' : '${p.valueLabel} ${p.title}',
            subtitle: isCoupon
                ? '${p.valueLabel} en ${store?.name ?? 'la tienda'} al finalizar tu compra'
                : 'En ${store?.name ?? 'el campus'} por tiempo limitado',
            icon: ProductImage.styleFor(store?.category ?? '').$2,
            gradient: gradients[i % gradients.length],
            cta: 'Ver tienda',
            onTap: () => context.push(AppRoutes.storePath(p.storeId)),
          );
        }(),
    ];
    if (banners.isEmpty) return const SizedBox.shrink();
    return Column(
      children: [
        SizedBox(
          height: 170,
          child: PageView.builder(
            controller: _bannerController,
            itemCount: banners.length,
            onPageChanged: (i) => setState(() => _banner = i),
            itemBuilder: (_, i) => Padding(
              padding: const EdgeInsets.symmetric(horizontal: 6),
              child: banners[i],
            ),
          ),
        ),
        const SizedBox(height: 10),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(
            banners.length,
            (i) => AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              margin: const EdgeInsets.symmetric(horizontal: 3),
              width: i == _banner ? 18 : 6,
              height: 6,
              decoration: BoxDecoration(
                color: i == _banner ? AppColors.primary : AppColors.border,
                borderRadius: BorderRadius.circular(999),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _stores() {
    final stores = CatalogMockData.stores
        .where((s) => _category == 'Todo' || s.category == _category)
        .toList();
    if (stores.isEmpty) {
      return const Padding(
        padding: EdgeInsets.all(AppTheme.pagePadding),
        child: Text('Aún no hay emprendimientos en esta categoría.'),
      );
    }
    return SizedBox(
      height: 200,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: AppTheme.pagePadding),
        itemCount: stores.length,
        separatorBuilder: (_, _) => const SizedBox(width: 14),
        itemBuilder: (_, i) => StoreCard(store: stores[i]),
      ),
    );
  }

  Widget _productsGrid() {
    return BlocBuilder<ProductCubit, ProductState>(
      builder: (context, state) {
        if (state is ProductLoading || state is ProductInitial) {
          return const SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.all(40),
              child: Center(child: CircularProgressIndicator()),
            ),
          );
        }
        if (state is ProductError) {
          return SliverToBoxAdapter(
            child: EmptyState(
              icon: Icons.wifi_off_rounded,
              title: 'No pudimos cargar los productos',
              message: 'Revisa tu conexión y vuelve a intentarlo.',
              actionLabel: 'Reintentar',
              onAction: () => context.read<ProductCubit>().loadProducts(),
            ),
          );
        }
        final all = state is ProductLoaded ? state.products : const [];
        final products = all
            .where((p) => _category == 'Todo' || p.category == _category)
            .toList();
        if (products.isEmpty) {
          return const SliverToBoxAdapter(
            child: EmptyState(
              icon: Icons.search_off_rounded,
              title: 'Sin productos',
              message: 'No hay productos en esta categoría por ahora.',
            ),
          );
        }
        return SliverPadding(
          padding: const EdgeInsets.symmetric(horizontal: AppTheme.pagePadding),
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
    );
  }
}

class _HomeHeader extends StatelessWidget {
  const _HomeHeader();

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsets.fromLTRB(AppTheme.pagePadding, 12, 12, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              BlocBuilder<NotificationsCubit, NotificationsState>(
                builder: (context, state) {
                  final unread = state is NotificationsLoaded
                      ? state.notifications.where((n) => !n.isRead).length
                      : 0;
                  return CircleIconButton(
                    icon: Icons.notifications_none_rounded,
                    tooltip: 'Notificaciones',
                    background: AppColors.surfaceMuted,
                    onPressed: () => context.push(AppRoutes.notifications),
                  ).withBadge(unread);
                },
              ),
              const SizedBox(width: 12),
              Expanded(
                child: InkWell(
                  borderRadius: BorderRadius.circular(8),
                  onTap: () => context.push(AppRoutes.addresses),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'ENTREGAR EN',
                        style: t.labelSmall?.copyWith(
                          color: AppColors.primary,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.8,
                        ),
                      ),
                      Row(
                        children: [
                          Flexible(
                            child: Text(
                              'Bloque 8 · Unimagdalena',
                              style: t.bodyMedium?.copyWith(
                                color: AppColors.textSecondary,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const Icon(
                            Icons.arrow_drop_down_rounded,
                            color: AppColors.textSecondary,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              IconButton(
                tooltip: 'Mi perfil',
                onPressed: () => context.push(AppRoutes.profile),
                icon: const CircleAvatar(
                  radius: 22,
                  backgroundColor: AppColors.primary,
                  child: Icon(Icons.person_rounded, color: Colors.white),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          BlocBuilder<ProfileCubit, ProfileState>(
            builder: (context, state) {
              final name = state is ProfileLoaded
                  ? state.user.name.split(' ').first
                  : '';
              return Text(
                name.isEmpty ? '¡Hola!' : '¡Hola, $name!',
                style: t.headlineSmall,
              );
            },
          ),
          Text(
            '¿Qué se te antoja hoy?',
            style: t.bodyMedium?.copyWith(color: AppColors.textSecondary),
          ),
        ],
      ),
    );
  }
}

extension _BadgeX on Widget {
  Widget withBadge(int count) => Badge(
    isLabelVisible: count > 0,
    label: Text(count > 99 ? '99+' : '$count'),
    child: this,
  );
}

/// Acceso rápido al pedido en curso más reciente.
class _ActiveOrderBanner extends StatelessWidget {
  const _ActiveOrderBanner();

  @override
  Widget build(BuildContext context) {
    final profile = context.watch<ProfileCubit>().state;
    final name = profile is ProfileLoaded ? profile.user.name : '';
    final active = context
        .watch<MarketOrdersCubit>()
        .forCustomer(name)
        .where((o) => o.status.isActive)
        .toList();
    if (active.isEmpty) return const SizedBox.shrink();
    final o = active.first;
    final t = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppTheme.pagePadding,
        0,
        AppTheme.pagePadding,
        16,
      ),
      child: Material(
        color: AppColors.primary,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () => context.push(AppRoutes.orderTrackingPath(o.id)),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              children: [
                const Icon(
                  Icons.delivery_dining_rounded,
                  color: Colors.white,
                  size: 30,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${o.storeName} · ${o.status.label}',
                        style: t.titleSmall?.copyWith(color: Colors.white),
                      ),
                      Text(
                        active.length > 1
                            ? 'Tienes ${active.length} pedidos en curso'
                            : 'Toca para seguir tu pedido',
                        style: t.bodySmall?.copyWith(color: Colors.white70),
                      ),
                    ],
                  ),
                ),
                const Icon(Icons.chevron_right_rounded, color: Colors.white),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
