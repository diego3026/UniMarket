import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../constants/app_colors.dart';
import '../../../core/router/app_routes.dart';
import '../../../core/theme/app_theme.dart';
import '../../../domain/entities/product_entity.dart';
import '../../viewmodels/favorites/favorites_cubit.dart';
import '../../viewmodels/product/product_cubit.dart';
import '../../widgets/ui/app_widgets.dart';
import '../../widgets/ui/product_cards.dart';

/// Favoritos con filtros y orden (Figma: "Favoritos - Ordenar").
class FavoritesPage extends StatefulWidget {
  const FavoritesPage({super.key});

  @override
  State<FavoritesPage> createState() => _FavoritesPageState();
}

class _FavoritesPageState extends State<FavoritesPage> {
  static const _sorts = [
    'Populares',
    'Nuevos',
    'Calificaciones',
    'Precio: de menor a mayor',
    'Precio: de mayor a menor',
  ];
  String _sort = 'Populares';
  final Set<String> _categories = {};
  bool _onlyPromos = false;

  List<ProductEntity> _apply(List<ProductEntity> items) {
    final list = items.where((p) {
      if (_categories.isNotEmpty && !_categories.contains(p.category)) {
        return false;
      }
      if (_onlyPromos && !p.isOnSale) return false;
      return true;
    }).toList();
    switch (_sort) {
      case 'Nuevos':
        list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      case 'Calificaciones':
        list.sort((a, b) => b.rating.compareTo(a.rating));
      case 'Precio: de menor a mayor':
        list.sort((a, b) => a.finalPrice.compareTo(b.finalPrice));
      case 'Precio: de mayor a menor':
        list.sort((a, b) => b.finalPrice.compareTo(a.finalPrice));
      default:
        list.sort(
          (a, b) => (b.isFeatured ? 1 : 0).compareTo(a.isFeatured ? 1 : 0),
        );
    }
    return list;
  }

  void _openSort() => showModalBottomSheet(
    context: context,
    builder: (ctx) => SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text('Ordenar', style: Theme.of(ctx).textTheme.titleLarge),
          const SizedBox(height: 8),
          for (final s in _sorts)
            ListTile(
              title: Text(s),
              selected: s == _sort,
              selectedTileColor: AppColors.primary.withValues(alpha: 0.08),
              trailing: s == _sort
                  ? const Icon(Icons.check_rounded, color: AppColors.primary)
                  : null,
              onTap: () {
                setState(() => _sort = s);
                Navigator.pop(ctx);
              },
            ),
          const SizedBox(height: 8),
        ],
      ),
    ),
  );

  void _openFilters(List<String> categories) => showModalBottomSheet(
    context: context,
    builder: (ctx) => StatefulBuilder(
      builder: (ctx, setSheet) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Filtros', style: Theme.of(ctx).textTheme.titleLarge),
              const SizedBox(height: 12),
              Text('Categorías', style: Theme.of(ctx).textTheme.titleSmall),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final c in categories)
                    FilterChip(
                      label: Text(c),
                      selected: _categories.contains(c),
                      onSelected: (v) {
                        setState(
                          () => v ? _categories.add(c) : _categories.remove(c),
                        );
                        setSheet(() {});
                      },
                    ),
                ],
              ),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Solo con descuento'),
                value: _onlyPromos,
                onChanged: (v) {
                  setState(() => _onlyPromos = v);
                  setSheet(() {});
                },
              ),
              Row(
                children: [
                  TextButton(
                    onPressed: () {
                      setState(() {
                        _categories.clear();
                        _onlyPromos = false;
                      });
                      setSheet(() {});
                    },
                    child: const Text('Limpiar'),
                  ),
                  const Spacer(),
                  FilledButton(
                    style: FilledButton.styleFrom(
                      minimumSize: const Size(140, 46),
                    ),
                    onPressed: () => Navigator.pop(ctx),
                    child: const Text('Ver resultados'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    ),
  );

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    // Los favoritos se muestran con el precio actual del catálogo (promos al día).
    final catalog = context.watch<ProductCubit>().state;
    final byId = {
      if (catalog is ProductLoaded)
        for (final p in catalog.products) p.id: p,
    };
    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: BlocBuilder<FavoritesCubit, FavoritesState>(
          builder: (context, state) {
            final raw = state is FavoritesLoaded
                ? state.items
                : const <ProductEntity>[];
            final favs = [for (final p in raw) byId[p.id] ?? p];
            final items = _apply(favs);
            final categories = {for (final p in favs) p.category}.toList();
            final filterCount = _categories.length + (_onlyPromos ? 1 : 0);
            return ListView(
              padding: const EdgeInsets.only(bottom: 24),
              children: [
                PageTitle(
                  title: 'Favoritos',
                  subtitle: favs.isEmpty ? null : '${favs.length} guardados',
                ),
                if (favs.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(12, 0, 12, 8),
                    child: Row(
                      children: [
                        TextButton.icon(
                          onPressed: () => _openFilters(categories),
                          icon: const Icon(Icons.filter_list_rounded),
                          label: Text(
                            filterCount > 0
                                ? 'Filtros ($filterCount)'
                                : 'Filtros',
                          ),
                        ),
                        TextButton.icon(
                          onPressed: _openSort,
                          icon: const Icon(Icons.swap_vert_rounded),
                          label: const Text('Ordenar'),
                        ),
                        const Spacer(),
                        Text(_sort.split(':').first, style: t.bodySmall),
                        const SizedBox(width: 8),
                      ],
                    ),
                  ),
                if (favs.isEmpty)
                  EmptyState(
                    icon: Icons.favorite_border_rounded,
                    title: 'Aún no tienes favoritos',
                    message:
                        'Toca el corazón en un producto para guardarlo aquí.',
                    actionLabel: 'Descubrir productos',
                    onAction: () => context.go(AppRoutes.home),
                  )
                else if (items.isEmpty)
                  const EmptyState(
                    icon: Icons.filter_alt_off_rounded,
                    title: 'Ningún favorito coincide',
                    message: 'Cambia o limpia los filtros.',
                  )
                else
                  for (final p in items)
                    Padding(
                      padding: const EdgeInsets.fromLTRB(
                        AppTheme.pagePadding,
                        0,
                        AppTheme.pagePadding,
                        12,
                      ),
                      child: ProductRow(
                        product: p,
                        trailing: Column(
                          children: [
                            IconButton(
                              tooltip: 'Quitar de favoritos',
                              onPressed: () => context
                                  .read<FavoritesCubit>()
                                  .removeFromFavorites(p.id),
                              icon: const Icon(
                                Icons.close_rounded,
                                color: AppColors.textMuted,
                              ),
                            ),
                            IconButton.filledTonal(
                              tooltip: 'Agregar a la bolsa',
                              onPressed: () =>
                                  addToCartWithFeedback(context, p),
                              icon: const Icon(
                                Icons.add_shopping_cart_rounded,
                                size: 20,
                              ),
                            ),
                          ],
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
