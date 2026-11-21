import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/router/app_routes.dart';
import '../../../core/theme/app_theme.dart';
import '../../widgets/ui/app_widgets.dart';

/// Ajustes (Figma: "Ajustes").
class AjustesPage extends StatelessWidget {
  const AjustesPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Ajustes')),
      body: ListView(
        padding: const EdgeInsets.all(AppTheme.pagePadding),
        children: [
          SurfaceCard(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Column(
              children: [
                MenuTile(
                  icon: Icons.notifications_active_outlined,
                  title: 'Notificaciones',
                  subtitle: 'Pedidos, promociones y novedades',
                  onTap: () => context.push(AppRoutes.settingsNotifications),
                ),
                MenuTile(
                  icon: Icons.tune_rounded,
                  title: 'Preferencias del pedido',
                  subtitle: 'Entrega, propinas y cubiertos',
                  onTap: () => context.push(AppRoutes.settingsOrders),
                ),
                MenuTile(
                  icon: Icons.language_rounded,
                  title: 'Preferencias de la app',
                  subtitle: 'Idioma y apariencia',
                  onTap: () => context.push(AppRoutes.settingsApp),
                ),
                MenuTile(
                  icon: Icons.lock_outline_rounded,
                  title: 'Privacidad y seguridad',
                  subtitle: 'Contraseña y datos personales',
                  onTap: () => context.push(AppRoutes.settingsPrivacy),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          Center(
            child: Text(
              'UniMarket v1.0.0',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ),
        ],
      ),
    );
  }
}
