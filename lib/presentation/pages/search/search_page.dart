import 'package:unimarket/presentation/viewmodels/catalog/catalog_cubit.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../constants/app_colors.dart';
import '../../../core/theme/app_theme.dart';
import '../../../domain/entities/product_entity.dart';
import '../../viewmodels/product/product_cubit.dart';
import '../../widgets/ui/app_widgets.dart';
import '../../widgets/ui/product_cards.dart';

/// Búsqueda de productos y emprendimientos (Figma: "Búsqueda").
///
/// Filtra en memoria sin modificar el estado global de [ProductCubit].
class SearchPage extends StatefulWidget {
  const SearchPage({super.key});

  @override
  State<SearchPage> createState() => _SearchPageState();
}

class _SearchPageState extends State<SearchPage> {
  final _controller = TextEditingController();
  String _query = '';
  String _category = 'Todo';
  String _sort = 'Relevancia';

  static const _suggestions = [
    'Mango',
    'Pizza',
    'Brownie',
    'Mochila',
    'Sándwich',
    'Aretes',
  ];

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  List<ProductEntity> _filter(List<ProductEntity> all) {
    final q = _query.trim().toLowerCase();
    final list = all.where((p) {
      final matchQ =
          q.isEmpty ||
          p.name.toLowerCase().contains(q) ||
          p.description.toLowerCase().contains(q) ||
          p.storeName.toLowerCase().contains(q) ||
          p.category.toLowerCase().contains(q);
      final matchC = _category == 'Todo' || p.category == _category;
      return matchQ && matchC;
    }).toList();
    switch (_sort) {
      case 'Menor precio':
        list.sort((a, b) => a.finalPrice.compareTo(b.finalPrice));
      case 'Mayor precio':
        list.sort((a, b) => b.finalPrice.compareTo(a.finalPrice));
      case 'Mejor calificados':
        list.sort((a, b) => b.rating.compareTo(a.rating));
    }
    return list;
  }

  @override
  Widget build(BuildContext context) {
    context.watch<CatalogCubit>(); // se reconstruye cuando llegan los datos de la API
    final t = Theme.of(context).textTheme;
    final stores = Catalog.stores
        .where(
          (s) =>
              _query.isNotEmpty &&
              s.name.toLowerCase().contains(_query.toLowerCase()),
        )
        .toList();

    return Scaffold(
      appBar: AppBar(
        titleSpacing: 0,
        leading: IconButton(
          tooltip: 'Volver',
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => context.pop(),
        ),
        title: Padding(
          padding: const EdgeInsets.only(right: 16),
          child: AppSearchBar(
            controller: _controller,
            autofocus: true,
            onChanged: (v) => setState(() => _query = v),
            trailing: _query.isEmpty
                ? null
                : IconButton(
                    tooltip: 'Borrar búsqueda',
                    icon: const Icon(Icons.close_rounded),
                    onPressed: () {
                      _controller.clear();
                      setState(() => _query = '');
                    },
                  ),
          ),
        ),
      ),
      body: BlocBuilder<ProductCubit, ProductState>(
        builder: (context, state) {
          final all = state is ProductLoaded
              ? state.products
              : <ProductEntity>[];
          final results = _filter(all);
          return ListView(
            padding: const EdgeInsets.only(bottom: 24),
            children: [
              const SizedBox(height: 8),
              ChoiceChipsRow(
                options: ['Todo', ...Catalog.categories],
                selected: _category,
                onSelected: (c) => setState(() => _category = c),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(
                  AppTheme.pagePadding,
                  12,
                  8,
                  4,
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        '${results.length} resultados',
                        style: t.bodySmall,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    PopupMenuButton<String>(
                      tooltip: 'Ordenar',
                      initialValue: _sort,
                      onSelected: (v) => setState(() => _sort = v),
                      itemBuilder: (_) =>
                          const [
                                'Relevancia',
                                'Menor precio',
                                'Mayor precio',
                                'Mejor calificados',
                              ]
                              .map(
                                (o) => PopupMenuItem(value: o, child: Text(o)),
                              )
                              .toList(),
                      child: Padding(
                        padding: const EdgeInsets.all(8),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.sort_rounded,
                              size: 18,
                              color: AppColors.primary,
                            ),
                            const SizedBox(width: 4),
                            ConstrainedBox(
                              constraints: const BoxConstraints(maxWidth: 160),
                              child: Text(
                                _sort,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: t.labelLarge?.copyWith(
                                  color: AppColors.primary,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              if (_query.isEmpty) ...[
                Padding(
                  padding: const EdgeInsets.fromLTRB(
                    AppTheme.pagePadding,
                    8,
                    AppTheme.pagePadding,
                    8,
                  ),
                  child: Text('Búsquedas populares', style: t.titleMedium),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppTheme.pagePadding,
                  ),
                  child: Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: _suggestions
                        .map(
                          (s) => ActionChip(
                            avatar: const Icon(
                              Icons.trending_up_rounded,
                              size: 18,
                            ),
                            label: Text(s),
                            onPressed: () {
                              _controller.text = s;
                              setState(() => _query = s);
                            },
                          ),
                        )
                        .toList(),
                  ),
                ),
                const SizedBox(height: 12),
              ],
              if (stores.isNotEmpty) ...[
                const SectionHeader(title: 'Emprendimientos'),
                SizedBox(
                  height: 200,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppTheme.pagePadding,
                    ),
                    itemCount: stores.length,
                    separatorBuilder: (_, _) => const SizedBox(width: 12),
                    itemBuilder: (_, i) => StoreCard(store: stores[i]),
                  ),
                ),
                const SizedBox(height: 8),
              ],
              if (results.isEmpty)
                const EmptyState(
                  icon: Icons.search_off_rounded,
                  title: 'Sin resultados',
                  message: 'Prueba con otra palabra o cambia la categoría.',
                )
              else
                ...results.map(
                  (p) => Padding(
                    padding: const EdgeInsets.fromLTRB(
                      AppTheme.pagePadding,
                      0,
                      AppTheme.pagePadding,
                      12,
                    ),
                    child: ProductRow(product: p),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}
