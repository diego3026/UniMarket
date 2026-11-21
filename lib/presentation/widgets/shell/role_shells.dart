import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../constants/app_colors.dart';
import '../../../core/router/app_routes.dart';
import '../../../core/theme/app_theme.dart';
import '../../viewmodels/cart/cart_cubit.dart';

class _NavItem {
  final IconData icon;
  final IconData activeIcon;
  final String label;
  const _NavItem(this.icon, this.activeIcon, this.label);
}

/// Barra inferior redondeada (Figma: barra blanca con íconos).
class _RoundedNavBar extends StatelessWidget {
  final List<_NavItem> items;
  final int currentIndex;
  final ValueChanged<int> onTap;
  final Color color;

  /// Si no es nulo se dibuja un botón central (la bolsa del cliente).
  final Widget? center;

  const _RoundedNavBar({
    required this.items,
    required this.currentIndex,
    required this.onTap,
    required this.color,
    this.center,
  });

  @override
  Widget build(BuildContext context) {
    final half = items.length ~/ 2;
    Widget item(int i) {
      final it = items[i];
      final sel = i == currentIndex;
      return Expanded(
        child: InkResponse(
          onTap: () => onTap(i),
          radius: 32,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: sel
                        ? color.withValues(alpha: 0.12)
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Icon(
                    sel ? it.activeIcon : it.icon,
                    color: sel ? color : AppColors.textMuted,
                    size: 24,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  it.label,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: sel ? FontWeight.w800 : FontWeight.w600,
                    color: sel ? color : AppColors.textMuted,
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Container(
      decoration: const BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        boxShadow: [
          BoxShadow(
            color: Color(0x14000000),
            blurRadius: 24,
            offset: Offset(0, -6),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(8, 6, 8, 6),
          child: Row(
            children: [
              for (var i = 0; i < items.length; i++) ...[
                if (center != null && i == half) center!,
                item(i),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

/// Botón "atrás" del sistema dentro de las pestañas.
///
/// - Si hay una pantalla encima (detalle, carrito, un diálogo…) la cierra.
/// - Si no, vuelve a la pestaña que se estaba viendo antes.
/// - En la primera pestaña sin historial pide confirmar antes de salir.
///
/// Las pantallas de acceso (login, registro…) nunca quedan en el historial:
/// el router las reemplaza al iniciar sesión, así que "atrás" no regresa a ellas.
class _ShellBackHandler extends StatefulWidget {
  final StatefulNavigationShell shell;
  final Widget child;
  const _ShellBackHandler({required this.shell, required this.child});

  @override
  State<_ShellBackHandler> createState() => _ShellBackHandlerState();
}

class _ShellBackHandlerState extends State<_ShellBackHandler> {
  final List<int> _history = [];
  bool _goingBack = false;
  DateTime? _lastBackPress;

  @override
  void didUpdateWidget(covariant _ShellBackHandler old) {
    super.didUpdateWidget(old);
    final from = old.shell.currentIndex;
    final to = widget.shell.currentIndex;
    if (from == to) return;
    if (_goingBack) {
      _goingBack = false;
      return;
    }
    _history
      ..remove(from)
      ..add(from);
  }

  Future<bool> _onBack() async {
    final router = GoRouter.of(context);
    // Hay algo encima de las pestañas: que el router lo cierre normalmente.
    if (router.canPop()) return false;

    final shell = widget.shell;
    _history.remove(shell.currentIndex);
    if (_history.isNotEmpty || shell.currentIndex != 0) {
      final target = _history.isNotEmpty ? _history.removeLast() : 0;
      _goingBack = true;
      shell.goBranch(target);
      return true;
    }

    final now = DateTime.now();
    if (_lastBackPress == null ||
        now.difference(_lastBackPress!) > const Duration(seconds: 2)) {
      _lastBackPress = now;
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          const SnackBar(
            content: Text('Presiona atrás otra vez para salir'),
            duration: Duration(seconds: 2),
          ),
        );
      return true;
    }
    await SystemNavigator.pop();
    return true;
  }

  @override
  Widget build(BuildContext context) =>
      BackButtonListener(onBackButtonPressed: _onBack, child: widget.child);
}

/// Shell del cliente: Inicio · Promos · [Bolsa] · Pedidos · Favoritos.
class ConsumerShell extends StatelessWidget {
  final StatefulNavigationShell shell;
  const ConsumerShell({super.key, required this.shell});

  static const _items = [
    _NavItem(Icons.home_outlined, Icons.home_rounded, 'Inicio'),
    _NavItem(Icons.local_offer_outlined, Icons.local_offer_rounded, 'Promos'),
    _NavItem(
      Icons.receipt_long_outlined,
      Icons.receipt_long_rounded,
      'Pedidos',
    ),
    _NavItem(
      Icons.favorite_border_rounded,
      Icons.favorite_rounded,
      'Favoritos',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return _ShellBackHandler(
      shell: shell,
      child: Scaffold(
        body: shell,
        bottomNavigationBar: _RoundedNavBar(
          items: _items,
          currentIndex: shell.currentIndex,
          color: AppColors.primary,
          onTap: (i) =>
              shell.goBranch(i, initialLocation: i == shell.currentIndex),
          center: const _CartButton(),
        ),
      ),
    );
  }
}

class _CartButton extends StatelessWidget {
  const _CartButton();

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<CartCubit, CartState>(
      builder: (context, state) {
        final count = state is CartLoaded ? state.totalQuantity : 0;
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 6),
          child: Tooltip(
            message: 'Mi bolsa',
            child: GestureDetector(
              onTap: () {
                ScaffoldMessenger.of(context).hideCurrentSnackBar();
                context.push(AppRoutes.cart);
              },
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  Container(
                    width: 58,
                    height: 58,
                    decoration: BoxDecoration(
                      gradient: AppColors.purpleGradient,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.primary.withValues(alpha: 0.35),
                          blurRadius: 16,
                          offset: const Offset(0, 6),
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.shopping_bag_rounded,
                      color: Colors.white,
                      size: 26,
                    ),
                  ),
                  if (count > 0)
                    Positioned(
                      top: -2,
                      right: -2,
                      child: Container(
                        constraints: const BoxConstraints(minWidth: 22),
                        height: 22,
                        padding: const EdgeInsets.symmetric(horizontal: 6),
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: AppColors.accent,
                          borderRadius: BorderRadius.circular(999),
                          border: Border.all(color: Colors.white, width: 2),
                        ),
                        child: Text(
                          count > 99 ? '99+' : '$count',
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w800,
                            color: AppColors.textPrimary,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

/// Shell del emprendedor (acento naranja, como en el Figma "Emprendedor").
class SellerShell extends StatelessWidget {
  final StatefulNavigationShell shell;
  const SellerShell({super.key, required this.shell});

  static const _items = [
    _NavItem(Icons.storefront_outlined, Icons.storefront_rounded, 'Tienda'),
    _NavItem(
      Icons.restaurant_menu_outlined,
      Icons.restaurant_menu_rounded,
      'Menú',
    ),
    _NavItem(Icons.local_offer_outlined, Icons.local_offer_rounded, 'Promos'),
    _NavItem(Icons.payments_outlined, Icons.payments_rounded, 'Ganancias'),
    _NavItem(Icons.person_outline_rounded, Icons.person_rounded, 'Perfil'),
  ];

  @override
  Widget build(BuildContext context) {
    return Theme(
      data: AppTheme.light(seed: AppColors.seller),
      child: _ShellBackHandler(
        shell: shell,
        child: Scaffold(
          body: shell,
          bottomNavigationBar: _RoundedNavBar(
            items: _items,
            currentIndex: shell.currentIndex,
            color: AppColors.seller,
            onTap: (i) =>
                shell.goBranch(i, initialLocation: i == shell.currentIndex),
          ),
        ),
      ),
    );
  }
}

/// Shell del administrador.
class AdminShell extends StatelessWidget {
  final StatefulNavigationShell shell;
  const AdminShell({super.key, required this.shell});

  static const _items = [
    _NavItem(Icons.dashboard_outlined, Icons.dashboard_rounded, 'Panel'),
    _NavItem(Icons.group_outlined, Icons.group_rounded, 'Usuarios'),
    _NavItem(
      Icons.store_mall_directory_outlined,
      Icons.store_mall_directory_rounded,
      'Negocios',
    ),
    _NavItem(
      Icons.insert_chart_outlined_rounded,
      Icons.insert_chart_rounded,
      'Reportes',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return _ShellBackHandler(
      shell: shell,
      child: Scaffold(
        body: shell,
        bottomNavigationBar: _RoundedNavBar(
          items: _items,
          currentIndex: shell.currentIndex,
          color: AppColors.primary,
          onTap: (i) =>
              shell.goBranch(i, initialLocation: i == shell.currentIndex),
        ),
      ),
    );
  }
}
