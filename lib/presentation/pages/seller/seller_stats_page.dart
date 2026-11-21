import 'package:flutter/material.dart';

import '../../../constants/app_colors.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/formatters.dart';
import '../../widgets/ui/app_widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../domain/entities/market_entities.dart';
import '../../viewmodels/market/market_cubits.dart';
import 'seller_mock.dart';

/// Ganancias y estadísticas del emprendedor (Figma Emprendedor: "Estadisticas").
class SellerStatsPage extends StatelessWidget {
  const SellerStatsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    final months = SellerMock.monthlyEarnings;
    final total = months.fold<double>(0, (s, m) => s + m.$2);
    final maxV = months.map((m) => m.$2).reduce((a, b) => a > b ? a : b);
    final storeOrders = context.watch<MarketOrdersCubit>().forStore(
      SellerMock.store.id,
    );
    final delivered =
        storeOrders.where((o) => o.status == OrderStatus.delivered).length + 98;
    final cancelled =
        storeOrders.where((o) => o.status == OrderStatus.cancelled).length + 3;
    final rated = storeOrders.where((o) => o.rating != null).toList();
    final avg = rated.isEmpty
        ? 0.0
        : rated.fold<int>(0, (s, o) => s + o.rating!) / rated.length;

    Widget kpi(String label, String value, IconData icon, Color color) =>
        Expanded(
          child: SurfaceCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(icon, color: color),
                const SizedBox(height: 10),
                Text(value, style: t.headlineSmall),
                Text(label, style: t.bodySmall),
              ],
            ),
          ),
        );

    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: ListView(
          padding: const EdgeInsets.only(bottom: 24),
          children: [
            const PageTitle(
              title: 'Estadísticas',
              subtitle: 'Resumen de tu emprendimiento',
            ),
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppTheme.pagePadding,
              ),
              child: Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: AppColors.sellerGradient,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Ganancia total (6 meses)',
                      style: TextStyle(color: Colors.white70),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      formatCop(total),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 30,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 6),
                    const Row(
                      children: [
                        Icon(
                          Icons.trending_up_rounded,
                          color: Colors.white,
                          size: 18,
                        ),
                        SizedBox(width: 4),
                        Flexible(
                          child: Text(
                            '+13 % frente al mes anterior',
                            style: TextStyle(color: Colors.white),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppTheme.pagePadding,
              ),
              child: Row(
                children: [
                  kpi(
                    'Entregadas',
                    '$delivered',
                    Icons.check_circle_outline_rounded,
                    AppColors.success,
                  ),
                  const SizedBox(width: 12),
                  kpi(
                    'Canceladas',
                    '$cancelled',
                    Icons.cancel_outlined,
                    AppColors.danger,
                  ),
                  const SizedBox(width: 12),
                  kpi(
                    'Calificación',
                    avg == 0 ? '—' : avg.toStringAsFixed(1),
                    Icons.star_rounded,
                    AppColors.accent,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppTheme.pagePadding,
              ),
              child: SurfaceCard(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Últimos meses', style: t.titleMedium),
                    const SizedBox(height: 16),
                    SizedBox(
                      height: 180,
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: months.map((m) {
                          final isLast = m == months.last;
                          return Expanded(
                            child: Tooltip(
                              message: '${m.$1}: ${formatCop(m.$2)}',
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.end,
                                children: [
                                  Container(
                                    height: 140 * (m.$2 / maxV),
                                    margin: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                    ),
                                    decoration: BoxDecoration(
                                      color: isLast
                                          ? AppColors.seller
                                          : AppColors.seller.withValues(
                                              alpha: 0.35,
                                            ),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Text(m.$1, style: t.bodySmall),
                                ],
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppTheme.pagePadding,
              ),
              child: SurfaceCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Más vendidos', style: t.titleMedium),
                    const SizedBox(height: 8),
                    for (final (i, (name, n)) in const [
                      ('Picada Tropical', 64),
                      ('Limón Coco', 51),
                      ('Mango Biche con Sal', 38),
                    ].indexed)
                      ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: CircleAvatar(
                          backgroundColor: AppColors.sellerLight,
                          child: Text(
                            '${i + 1}',
                            style: const TextStyle(
                              color: AppColors.seller,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                        title: Text(name),
                        trailing: Text('$n ventas', style: t.bodySmall),
                      ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
