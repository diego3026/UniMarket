import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../constants/app_colors.dart';
import '../../../core/router/app_routes.dart';
import '../../../core/theme/app_theme.dart';
import '../../../domain/entities/user_role.dart';
import '../../viewmodels/auth/auth_cubit.dart';
import '../../viewmodels/profile/profile_cubit.dart';
import '../../viewmodels/profile/profile_state.dart';
import '../../widgets/ui/app_widgets.dart';

/// Perfil (Figma: "Perfil"). Muestra opciones distintas según el rol.
class ProfilePage extends StatelessWidget {
  /// En la pestaña "Perfil" del emprendedor no hay botón atrás.
  final bool showBack;
  const ProfilePage({super.key, this.showBack = true});

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    final accent = Theme.of(context).colorScheme.primary;
    return Scaffold(
      appBar: showBack ? AppBar(title: const Text('Perfil')) : null,
      body: SafeArea(
        child: BlocBuilder<ProfileCubit, ProfileState>(
          builder: (context, state) {
            if (state is! ProfileLoaded) {
              return const Center(child: CircularProgressIndicator());
            }
            final user = state.user;
            final role = user.role;
            return ListView(
              padding: const EdgeInsets.only(bottom: 32),
              children: [
                if (!showBack) const PageTitle(title: 'Perfil'),
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppTheme.pagePadding,
                  ),
                  child: SurfaceCard(
                    onTap: () => context.push(AppRoutes.editProfile),
                    child: Row(
                      children: [
                        CircleAvatar(
                          radius: 34,
                          backgroundColor: accent.withValues(alpha: 0.12),
                          child: Text(
                            user.name.isEmpty
                                ? '?'
                                : user.name[0].toUpperCase(),
                            style: TextStyle(
                              fontSize: 28,
                              fontWeight: FontWeight.w800,
                              color: accent,
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(user.name, style: t.titleLarge),
                              Text(user.email, style: t.bodySmall),
                              const SizedBox(height: 6),
                              StatusChip(
                                label: role.displayName,
                                color: accent,
                              ),
                            ],
                          ),
                        ),
                        const Icon(
                          Icons.edit_outlined,
                          color: AppColors.textMuted,
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                ..._sections(context, role),
                Padding(
                  padding: const EdgeInsets.fromLTRB(
                    AppTheme.pagePadding,
                    24,
                    AppTheme.pagePadding,
                    0,
                  ),
                  child: OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.danger,
                      side: const BorderSide(color: AppColors.danger),
                      minimumSize: const Size.fromHeight(52),
                    ),
                    onPressed: () => _confirmLogout(context),
                    icon: const Icon(Icons.logout_rounded),
                    label: const Text('Cerrar sesión'),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  List<Widget> _sections(BuildContext context, UserRole role) {
    Widget group(String title, List<Widget> tiles) => Padding(
      padding: const EdgeInsets.fromLTRB(
        AppTheme.pagePadding,
        0,
        AppTheme.pagePadding,
        16,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(left: 4, bottom: 8),
            child: Text(
              title.toUpperCase(),
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: AppColors.textSecondary,
                letterSpacing: 0.8,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          SurfaceCard(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Column(children: tiles),
          ),
        ],
      ),
    );

    final common = group('General', [
      MenuTile(
        icon: Icons.settings_outlined,
        title: 'Ajustes',
        onTap: () => context.push(AppRoutes.settings),
      ),
      MenuTile(
        icon: Icons.help_outline_rounded,
        title: 'Ayuda',
        onTap: () => context.push(AppRoutes.help),
      ),
    ]);

    switch (role) {
      case UserRole.consumer:
        return [
          group('Mi cuenta', [
            MenuTile(
              icon: Icons.receipt_long_outlined,
              title: 'Mis pedidos',
              onTap: () => context.go(AppRoutes.orders),
            ),
            MenuTile(
              icon: Icons.place_outlined,
              title: 'Mis direcciones',
              onTap: () => context.push(AppRoutes.addresses),
            ),
            MenuTile(
              icon: Icons.credit_card_rounded,
              title: 'Métodos de pago',
              onTap: () => context.push(AppRoutes.paymentMethods),
            ),
            MenuTile(
              icon: Icons.notifications_none_rounded,
              title: 'Notificaciones',
              onTap: () => context.push(AppRoutes.notifications),
            ),
          ]),
          Padding(
            padding: const EdgeInsets.fromLTRB(
              AppTheme.pagePadding,
              0,
              AppTheme.pagePadding,
              16,
            ),
            child: SurfaceCard(
              onTap: () => context.push(AppRoutes.becomeSeller),
              child: Row(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      gradient: AppColors.sellerGradient,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: const Icon(
                      Icons.storefront_rounded,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Quiero ser emprendedor/a',
                          style: Theme.of(context).textTheme.titleSmall,
                        ),
                        Text(
                          'Vende tus productos a toda la universidad',
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ],
                    ),
                  ),
                  const Icon(
                    Icons.chevron_right_rounded,
                    color: AppColors.textMuted,
                  ),
                ],
              ),
            ),
          ),
          common,
        ];
      case UserRole.entrepreneur:
        return [
          group('Mi emprendimiento', [
            MenuTile(
              icon: Icons.tune_rounded,
              title: 'Configurar tienda',
              subtitle: 'Punto de recogida, domicilios y pagos',
              onTap: () => context.push(AppRoutes.sellerSettings),
            ),
            MenuTile(
              icon: Icons.local_offer_outlined,
              title: 'Promociones y cupones',
              onTap: () => context.go(AppRoutes.sellerPromos),
            ),
            MenuTile(
              icon: Icons.schedule_rounded,
              title: 'Horario de atención',
              onTap: () => context.push(AppRoutes.sellerSchedule),
            ),
            MenuTile(
              icon: Icons.add_box_outlined,
              title: 'Crear producto',
              onTap: () => context.push(AppRoutes.sellerNewProduct),
            ),
            MenuTile(
              icon: Icons.insights_rounded,
              title: 'Clientes, inventario y calificaciones',
              onTap: () => context.push(AppRoutes.sellerManagement),
            ),
            MenuTile(
              icon: Icons.account_balance_outlined,
              title: 'Datos bancarios',
              onTap: () => context.push(AppRoutes.sellerBank),
            ),
            MenuTile(
              icon: Icons.description_outlined,
              title: 'Documentos',
              onTap: () => context.push(AppRoutes.sellerDocuments),
            ),
          ]),
          common,
        ];
      case UserRole.admin:
        return [
          group('Administración', [
            MenuTile(
              icon: Icons.inventory_2_outlined,
              title: 'Gestionar productos',
              onTap: () => context.push(AppRoutes.adminProducts),
            ),
            MenuTile(
              icon: Icons.group_outlined,
              title: 'Usuarios',
              onTap: () => context.go(AppRoutes.adminUsers),
            ),
            MenuTile(
              icon: Icons.store_mall_directory_outlined,
              title: 'Negocios',
              onTap: () => context.go(AppRoutes.adminBusinesses),
            ),
          ]),
          common,
        ];
    }
  }

  Future<void> _confirmLogout(BuildContext context) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('¿Cerrar sesión?'),
        content: const Text(
          'Tendrás que volver a ingresar con tu correo institucional.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Seguir aquí'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.danger,
              minimumSize: const Size(0, 44),
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Cerrar sesión'),
          ),
        ],
      ),
    );
    if (ok == true && context.mounted) {
      await context.read<AuthCubit>().logout();
    }
  }
}
