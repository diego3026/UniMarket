import 'package:flutter/material.dart';

import '../../../constants/app_colors.dart';
import '../../../core/injection_container.dart';
import '../../../core/network/api_client.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/formatters.dart';
import '../../widgets/ui/app_widgets.dart';

/// Ganancias y estadísticas del emprendedor (GET /seller/earnings?days=N).
class SellerStatsPage extends StatefulWidget {
  const SellerStatsPage({super.key});

  @override
  State<SellerStatsPage> createState() => _SellerStatsPageState();
}

class _SellerStatsPageState extends State<SellerStatsPage> {
  static const _periods = {7: '7 días', 30: '30 días', 180: '6 meses'};
  static const _months = ['Ene', 'Feb', 'Mar', 'Abr', 'May', 'Jun', 'Jul', 'Ago', 'Sep', 'Oct', 'Nov', 'Dic'];

  int _days = 30;
  Map<String, dynamic>? _data;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _error = null);
    try {
      final r = await sl<ApiClient>().get('/seller/earnings', query: {'days': _days});
      if (mounted) setState(() => _data = Map<String, dynamic>.from(r as Map));
    } on ApiException catch (e) {
      if (mounted) setState(() => _error = e.message);
    }
  }

  /// Barras: por día (≤ 31 días) o por mes (6 meses).
  List<(String, int)> _bars() {
    final days = [
      for (final d in (_data?['salesByDay'] as List? ?? const []))
        (DateTime.tryParse(d['date'].toString()) ?? DateTime.now(), (d['total'] as num).toInt()),
    ];
    if (_days <= 31) {
      final now = DateTime.now();
      final byDate = {for (final d in days) '${d.$1.year}-${d.$1.month}-${d.$1.day}': d.$2};
      return [
        for (var i = _days - 1; i >= 0; i--)
          () {
            final day = DateTime(now.year, now.month, now.day - i);
            return ('${day.day}/${day.month}', byDate['${day.year}-${day.month}-${day.day}'] ?? 0);
          }(),
      ];
    }
    final now = DateTime.now();
    final byMonth = <String, int>{};
    for (final d in days) {
      final k = '${d.$1.year}-${d.$1.month}';
      byMonth[k] = (byMonth[k] ?? 0) + d.$2;
    }
    return [
      for (var i = 5; i >= 0; i--)
        () {
          final m = DateTime(now.year, now.month - i);
          return (_months[m.month - 1], byMonth['${m.year}-${m.month}'] ?? 0);
        }(),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    final d = _data;

    Widget kpi(String label, String value, IconData icon, Color color) => Expanded(
      child: SurfaceCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: color),
            const SizedBox(height: 10),
            Text(value, style: t.headlineSmall, maxLines: 1, overflow: TextOverflow.ellipsis),
            Text(label, style: t.bodySmall),
          ],
        ),
      ),
    );

    Widget pad(Widget child) =>
        Padding(padding: const EdgeInsets.symmetric(horizontal: AppTheme.pagePadding), child: child);

    final bars = d == null ? const <(String, int)>[] : _bars();
    final maxV = bars.fold<int>(0, (m, b) => b.$2 > m ? b.$2 : m);
    final top = (d?['topProducts'] as List?) ?? const [];
    final rating = (d?['rating'] as num?)?.toDouble() ?? 0;

    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: RefreshIndicator(
          onRefresh: _load,
          child: ListView(
            padding: const EdgeInsets.only(bottom: 24),
            children: [
              const PageTitle(title: 'Estadísticas', subtitle: 'Resumen de tu emprendimiento'),
              pad(
                Wrap(
                  spacing: 8,
                  children: [
                    for (final e in _periods.entries)
                      ChoiceChip(
                        label: Text(e.value),
                        selected: _days == e.key,
                        onSelected: (_) {
                          setState(() => _days = e.key);
                          _load();
                        },
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              if (_error != null)
                pad(
                  SurfaceCard(
                    child: Column(
                      children: [
                        Text(_error!, textAlign: TextAlign.center),
                        TextButton(onPressed: _load, child: const Text('Reintentar')),
                      ],
                    ),
                  ),
                )
              else if (d == null)
                const Padding(padding: EdgeInsets.all(48), child: Center(child: CircularProgressIndicator()))
              else ...[
                pad(
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      gradient: AppColors.sellerGradient,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Ventas (${_periods[_days]})', style: const TextStyle(color: Colors.white70)),
                        const SizedBox(height: 4),
                        Text(
                          formatCop((d['totalSales'] as num).toInt()),
                          style: const TextStyle(color: Colors.white, fontSize: 30, fontWeight: FontWeight.w800),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'Ticket promedio ${formatCop((d['averageTicket'] as num).toInt())} · '
                          '${d['activeOrders']} pedidos en curso',
                          style: const TextStyle(color: Colors.white),
                          maxLines: 2,
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                pad(
                  Row(
                    children: [
                      kpi('Entregados', '${d['deliveredOrders']}', Icons.check_circle_outline_rounded,
                          AppColors.success),
                      const SizedBox(width: 12),
                      kpi('Cancelados', '${d['cancelledOrders']}', Icons.cancel_outlined, AppColors.danger),
                      const SizedBox(width: 12),
                      kpi('Calificación', rating == 0 ? '—' : rating.toStringAsFixed(1), Icons.star_rounded,
                          AppColors.accent),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                pad(
                  SurfaceCard(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(_days <= 31 ? 'Ventas por día' : 'Ventas por mes', style: t.titleMedium),
                        const SizedBox(height: 16),
                        SizedBox(
                          height: 180,
                          child: maxV == 0
                              ? Center(child: Text('Aún no hay ventas en este periodo', style: t.bodySmall))
                              : Row(
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  children: [
                                    for (final (i, b) in bars.indexed)
                                      Expanded(
                                        child: Tooltip(
                                          message: '${b.$1}: ${formatCop(b.$2)}',
                                          child: Column(
                                            mainAxisAlignment: MainAxisAlignment.end,
                                            children: [
                                              Container(
                                                height: 4 + 136 * (b.$2 / maxV),
                                                margin: EdgeInsets.symmetric(horizontal: bars.length > 10 ? 1 : 6),
                                                decoration: BoxDecoration(
                                                  color: i == bars.length - 1
                                                      ? AppColors.seller
                                                      : AppColors.seller.withValues(alpha: 0.35),
                                                  borderRadius: BorderRadius.circular(bars.length > 10 ? 2 : 8),
                                                ),
                                              ),
                                              const SizedBox(height: 8),
                                              Text(
                                                bars.length > 10 && i % 5 != 0 && i != bars.length - 1 ? '' : b.$1,
                                                style: t.bodySmall?.copyWith(fontSize: 10),
                                                maxLines: 1,
                                                overflow: TextOverflow.visible,
                                                softWrap: false,
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                  ],
                                ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                pad(
                  SurfaceCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Más vendidos', style: t.titleMedium),
                        const SizedBox(height: 8),
                        if (top.isEmpty) Text('Todavía no hay productos vendidos', style: t.bodySmall),
                        for (final (i, p) in top.indexed)
                          ListTile(
                            contentPadding: EdgeInsets.zero,
                            leading: CircleAvatar(
                              backgroundColor: AppColors.sellerLight,
                              child: Text(
                                '${i + 1}',
                                style: const TextStyle(color: AppColors.seller, fontWeight: FontWeight.w800),
                              ),
                            ),
                            title: Text('${p['name']}'),
                            subtitle: Text(formatCop((p['total'] as num).toInt())),
                            trailing: Text('${p['quantity']} und.', style: t.bodySmall),
                          ),
                      ],
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
