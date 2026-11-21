import 'package:flutter/material.dart';

import '../../../constants/app_colors.dart';
import '../../../domain/entities/market_entities.dart';
import '../../viewmodels/catalog/catalog_cubit.dart';
import 'uni_map.dart';

/// Hoja para elegir un punto de entrega o de recogida en el mapa o en la lista.
/// Solo muestra los pines que el administrador marcó como punto de entrega.
Future<CampusPlace?> showCampusPlacePicker(
  BuildContext context, {
  required String title,
  String? selectedId,
}) {
  return showModalBottomSheet<CampusPlace>(
    context: context,
    isScrollControlled: true,
    builder: (ctx) {
      String? sel = selectedId;
      final places = Catalog.deliveryPlaces;
      return StatefulBuilder(
        builder: (ctx, setState) => SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: Theme.of(ctx).textTheme.titleLarge),
                const SizedBox(height: 4),
                Text(
                  'Toca un pin del mapa o elige de la lista.',
                  style: Theme.of(ctx).textTheme.bodySmall,
                ),
                const SizedBox(height: 12),
                UniMap(
                  height: 230,
                  deliveryOnly: true,
                  selectedPlaceId: sel,
                  onPlaceTap: (p) => setState(() => sel = p.id),
                ),
                const SizedBox(height: 8),
                ConstrainedBox(
                  constraints: BoxConstraints(
                    maxHeight: MediaQuery.of(ctx).size.height * 0.3,
                  ),
                  child: places.isEmpty
                      ? const Padding(
                          padding: EdgeInsets.all(16),
                          child: Text(
                            'Aún no hay puntos de entrega. El administrador los agrega en el mapa.',
                          ),
                        )
                      : ListView(
                          shrinkWrap: true,
                          children: [
                            for (final p in places)
                              ListTile(
                                onTap: () => setState(() => sel = p.id),
                                leading: Icon(
                                  sel == p.id
                                      ? Icons.radio_button_checked_rounded
                                      : Icons.radio_button_off_rounded,
                                  color: sel == p.id
                                      ? Theme.of(ctx).colorScheme.primary
                                      : AppColors.textMuted,
                                ),
                                title: Text(p.name),
                                subtitle: Text(
                                  [
                                    if (p.hint.isNotEmpty) p.hint,
                                    if (!p.hasLocation)
                                      'sin ubicación en el mapa',
                                  ].join(' · '),
                                ),
                                contentPadding: EdgeInsets.zero,
                                dense: true,
                              ),
                          ],
                        ),
                ),
                const SizedBox(height: 8),
                FilledButton(
                  onPressed: sel == null
                      ? null
                      : () => Navigator.pop(ctx, Catalog.place(sel!)),
                  child: const Text('Confirmar lugar'),
                ),
              ],
            ),
          ),
        ),
      );
    },
  );
}
