import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../constants/app_colors.dart';
import '../../../core/injection_container.dart';
import '../../../core/network/api_client.dart';
import '../../../core/router/app_routes.dart';
import '../../../core/theme/app_theme.dart';
import '../../widgets/ui/app_widgets.dart';

/// Panel del administrador: cifras de hoy (GET /admin/reports?days=1) y accesos.
class AdminHomePage extends StatefulWidget {
  const AdminHomePage({super.key});

  @override
  State<AdminHomePage> createState() => _AdminHomePageState();
}

class _AdminHomePageState extends State<AdminHomePage> {
  Map<String, dynamic>? _today;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final r = await sl<ApiClient>().get('/admin/reports', query: {'days': 1});
      if (mounted) setState(() => _today = Map<String, dynamic>.from(r as Map));
    } on ApiException catch (e) {
      if (mounted) setState(() => _error = e.message);
    }
  }

  int _sum(String key) => ((_today?[key] as Map?) ?? const {}).values.fold<int>(
    0,
    (a, v) => a + (v as num).toInt(),
  );

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    final stores = (_today?['storesByStatus'] as Map?) ?? const {};
    String v(Object? x) => _today == null ? '—' : '$x';

    Widget kpi(String label, String value, IconData icon, Color color) =>
        Expanded(
          child: SurfaceCard(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(icon, color: color, size: 22),
                const SizedBox(height: 8),
                Text(
                  value,
                  style: t.titleLarge,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  label,
                  style: t.bodySmall,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        );

    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: RefreshIndicator(
          onRefresh: _load,
          child: ListView(
            padding: const EdgeInsets.only(bottom: 24),
            children: [
              PageTitle(
                title: 'Panel',
                subtitle: 'Administración de UniMarket',
                trailing: IconButton(
                  tooltip: 'Mi perfil',
                  onPressed: () => context.push(AppRoutes.profile),
                  icon: const CircleAvatar(
                    backgroundColor: AppColors.primary,
                    child: Icon(
                      Icons.admin_panel_settings_rounded,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppTheme.pagePadding,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        kpi(
                          'Tiendas activas',
                          v(stores['approved'] ?? 0),
                          Icons.storefront_rounded,
                          AppColors.seller,
                        ),
                        const SizedBox(width: 10),
                        kpi(
                          'Usuarios',
                          v(_sum('usersByRole')),
                          Icons.group_rounded,
                          AppColors.primary,
                        ),
                        const SizedBox(width: 10),
                        kpi(
                          'Pedidos hoy',
                          v(_today?['ordersTotal'] ?? 0),
                          Icons.receipt_long_rounded,
                          AppColors.success,
                        ),
                      ],
                    ),
                    if (_error != null)
                      Padding(
                        padding: const EdgeInsets.only(top: 8),
                        child: Text(
                          _error!,
                          style: const TextStyle(color: AppColors.danger),
                        ),
                      ),
                    if ((stores['pending'] ?? 0) > 0)
                      Padding(
                        padding: const EdgeInsets.only(top: 12),
                        child: SurfaceCard(
                          child: ListTile(
                            contentPadding: EdgeInsets.zero,
                            leading: const Icon(
                              Icons.pending_actions_rounded,
                              color: AppColors.warning,
                            ),
                            title: Text(
                              '${stores['pending']} tienda(s) esperan aprobación',
                            ),
                            trailing: const Icon(Icons.chevron_right_rounded),
                            onTap: () => context.go(AppRoutes.adminBusinesses),
                          ),
                        ),
                      ),
                    const SizedBox(height: 16),
                    SurfaceCard(
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      child: Column(
                        children: [
                          MenuTile(
                            icon: Icons.map_rounded,
                            title: 'Pines del mapa',
                            subtitle:
                                'Puntos de entrega y guías para los usuarios',
                            onTap: () => context.push(AppRoutes.adminMapPins),
                          ),
                          MenuTile(
                            icon: Icons.storefront_rounded,
                            title: 'Emprendimientos',
                            subtitle: 'Aprobar, suspender y revisar',
                            onTap: () => context.go(AppRoutes.adminBusinesses),
                          ),
                          MenuTile(
                            icon: Icons.group_rounded,
                            title: 'Usuarios',
                            onTap: () => context.go(AppRoutes.adminUsers),
                          ),
                          MenuTile(
                            icon: Icons.inventory_2_outlined,
                            title: 'Moderar productos',
                            onTap: () => context.push(AppRoutes.adminProducts),
                          ),
                          MenuTile(
                            icon: Icons.bar_chart_rounded,
                            title: 'Reportes',
                            onTap: () => context.go(AppRoutes.adminReports),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
