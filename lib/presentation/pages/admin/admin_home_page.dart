import 'package:unimarket/presentation/viewmodels/catalog/catalog_cubit.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../constants/app_colors.dart';
import '../../../core/router/app_routes.dart';
import '../../../core/theme/app_theme.dart';
import '../../widgets/ui/app_widgets.dart';
import '../dashboards/admin_dashboard.dart';

/// Panel del administrador: resumen + secciones del dashboard existente.
class AdminHomePage extends StatelessWidget {
  const AdminHomePage({super.key});

  @override
  Widget build(BuildContext context) {
    context.watch<CatalogCubit>(); // se reconstruye cuando llegan los datos de la API
    final t = Theme.of(context).textTheme;
    Widget kpi(String label, String value, IconData icon, Color color) =>
        Expanded(
          child: SurfaceCard(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(icon, color: color, size: 22),
                const SizedBox(height: 8),
                Text(value, style: t.titleLarge),
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
        child: Column(
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
              child: Row(
                children: [
                  kpi(
                    'Emprendimientos',
                    '${Catalog.stores.length}',
                    Icons.storefront_rounded,
                    AppColors.seller,
                  ),
                  const SizedBox(width: 10),
                  kpi(
                    'Usuarios',
                    '1.248',
                    Icons.group_rounded,
                    AppColors.primary,
                  ),
                  const SizedBox(width: 10),
                  kpi(
                    'Pedidos hoy',
                    '87',
                    Icons.receipt_long_rounded,
                    AppColors.success,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            const Expanded(child: AdminDashboard()),
          ],
        ),
      ),
    );
  }
}
