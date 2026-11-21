import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart'
    show BitmapDescriptor;

import '../../../constants/app_colors.dart';
import '../../../core/router/app_routes.dart';
import '../../../core/utils/directions.dart';
import '../../viewmodels/catalog/catalog_cubit.dart';
import '../../viewmodels/market/market_cubits.dart';
import '../../widgets/ui/uni_map.dart';

/// Mapa de UniMarket: tiendas con local físico y pines del campus
/// (puntos de entrega y guías que configura el administrador).
class ExploreMapPage extends StatefulWidget {
  const ExploreMapPage({super.key});

  @override
  State<ExploreMapPage> createState() => _ExploreMapPageState();
}

class _ExploreMapPageState extends State<ExploreMapPage> {
  bool _stores = true;
  bool _pins = true;
  bool _deliveryOnly = false;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    context.watch<CatalogCubit>();
    final settings = context.watch<StoreSettingsCubit>();
    final stores = [
      for (final s in Catalog.stores)
        if (settings.of(s.id).hasLocation) (s, settings.of(s.id)),
    ];
    final places = Catalog.places
        .where((p) => p.hasLocation && (!_deliveryOnly || p.isDeliveryPoint))
        .toList();

    return Scaffold(
      appBar: AppBar(title: const Text('Mapa')),
      body: Column(
        children: [
          SizedBox(
            height: 52,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              children: [
                FilterChip(
                  label: const Text('Tiendas'),
                  avatar: const Icon(Icons.storefront_rounded, size: 18),
                  selected: _stores,
                  onSelected: (v) => setState(() => _stores = v),
                ),
                const SizedBox(width: 8),
                FilterChip(
                  label: const Text('Lugares del campus'),
                  avatar: const Icon(Icons.place_rounded, size: 18),
                  selected: _pins,
                  onSelected: (v) => setState(() => _pins = v),
                ),
                const SizedBox(width: 8),
                FilterChip(
                  label: const Text('Solo puntos de entrega'),
                  selected: _deliveryOnly,
                  onSelected: (v) => setState(() => _deliveryOnly = v),
                ),
              ],
            ),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: LayoutBuilder(
                builder: (context, c) => UniMap(
                  height: c.maxHeight,
                  zoom: 16,
                  places: places,
                  showGuidePins: _pins,
                  markers: [
                    if (_stores)
                      for (final (s, st) in stores)
                        UniMarker(
                          id: s.id,
                          latitude: st.latitude!,
                          longitude: st.longitude!,
                          title: s.name,
                          snippet:
                              '${st.address.isEmpty ? s.category : st.address} · Ver tienda',
                          hue: BitmapDescriptor.hueOrange,
                          onTap: () => context.push(AppRoutes.storePath(s.id)),
                        ),
                  ],
                ),
              ),
            ),
          ),
          SizedBox(
            height: 128,
            child: stores.isEmpty || !_stores
                ? Center(
                    child: Text(
                      _stores
                          ? 'Ninguna tienda ha marcado un local físico todavía'
                          : 'Toca un pin para ver su nombre',
                      style: t.bodySmall,
                    ),
                  )
                : ListView.separated(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.all(12),
                    itemCount: stores.length,
                    separatorBuilder: (_, _) => const SizedBox(width: 10),
                    itemBuilder: (context, i) {
                      final (s, st) = stores[i];
                      return SizedBox(
                        width: 240,
                        child: Card(
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                            side: const BorderSide(color: AppColors.border),
                          ),
                          child: InkWell(
                            borderRadius: BorderRadius.circular(14),
                            onTap: () =>
                                context.push(AppRoutes.storePath(s.id)),
                            child: Padding(
                              padding: const EdgeInsets.all(10),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    s.name,
                                    style: t.titleSmall,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  Text(
                                    st.address.isEmpty
                                        ? s.category
                                        : st.address,
                                    style: t.bodySmall,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  const Spacer(),
                                  Align(
                                    alignment: Alignment.centerRight,
                                    child: TextButton.icon(
                                      onPressed: () => openDirections(
                                        st.latitude!,
                                        st.longitude!,
                                      ),
                                      icon: const Icon(
                                        Icons.directions_rounded,
                                        size: 18,
                                      ),
                                      label: const Text('Cómo llegar'),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
