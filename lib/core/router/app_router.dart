// lib/core/router/app_router.dart
//
// Navegación central de UniMarket con go_router.
// - Pantallas públicas: onboarding, login, registro, recuperar contraseña.
// - Tres "shells" con barra inferior, uno por rol: cliente, emprendedor, admin.
// - El resto de pantallas se abren encima con `context.push`.
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../domain/entities/product_entity.dart';
import '../../domain/entities/user_role.dart';
import '../../presentation/pages/addresses/add_address_page.dart';
import '../../presentation/pages/addresses/map_address_page.dart';
import '../../presentation/pages/admin/admin_home_page.dart';
import '../../presentation/pages/cart/cart_page.dart';
import '../../presentation/pages/checkout/checkout_page.dart';
import '../../presentation/pages/dashboards/entrepreneur_dashboard.dart';
import '../../presentation/pages/email_confirmation/email_confirmation_page.dart';
import '../../presentation/pages/favorites/favorites_page.dart';
import '../../presentation/pages/help/help_page.dart';
import '../../presentation/pages/home/consumer_home_page.dart';
import '../../presentation/pages/login/login_page.dart';
import '../../presentation/pages/notifications/notifications_page.dart';
import '../../presentation/pages/onboarding/onboarding_page.dart';
import '../../presentation/pages/order_confirmation/order_confirmation_page.dart';
import '../../presentation/pages/order_tracking/order_tracking_page.dart';
import '../../presentation/pages/orders/orders_page.dart';
import '../../presentation/pages/password_recovery/password_recovery_page.dart';
import '../../presentation/pages/product_detail/product_detail_page.dart';
import '../../presentation/pages/product_review/product_review_page.dart';
import '../../presentation/pages/profile/admin_pages/manage_business_page.dart';
import '../../presentation/pages/profile/admin_pages/manage_products_page.dart';
import '../../presentation/pages/profile/admin_pages/manage_users_page.dart';
import '../../presentation/pages/profile/admin_pages/reports_page.dart';
import '../../presentation/pages/profile/ajustes_page.dart';
import '../../presentation/pages/profile/ajustes_subviews/app_preferences_page.dart';
import '../../presentation/pages/profile/ajustes_subviews/notifications_page.dart';
import '../../presentation/pages/profile/ajustes_subviews/order_preferences_page.dart';
import '../../presentation/pages/profile/ajustes_subviews/privacy_security_page.dart';
import '../../presentation/pages/profile/consumer_pages/addresses_management_page.dart';
import '../../presentation/pages/profile/consumer_pages/payment_methods_page.dart';
import '../../presentation/pages/profile/edit_profile_page.dart';
import '../../presentation/pages/profile/entrepreneur_page.dart';
import '../../presentation/pages/profile/entrepreneur_pages/bank_data_page.dart';
import '../../presentation/pages/profile/entrepreneur_pages/documents_page.dart';
import '../../presentation/pages/profile/profile_page.dart';
import '../../presentation/pages/promos/promos_page.dart';
import '../../presentation/pages/registration/registration_page.dart';
import '../../presentation/pages/search/search_page.dart';
import '../../presentation/pages/seller/create_product_page.dart';
import '../../presentation/viewmodels/market/seller_products_cubit.dart';
import '../../presentation/pages/seller/schedule_page.dart';
import '../../presentation/pages/seller/seller_home_page.dart';
import '../../presentation/pages/seller/seller_menu_page.dart';
import '../../presentation/pages/seller/seller_promotions_page.dart';
import '../../presentation/pages/seller/seller_stats_page.dart';
import '../../presentation/pages/seller/store_settings_page.dart';
import '../../domain/entities/market_entities.dart';
import '../../presentation/pages/store/store_page.dart';
import '../../presentation/viewmodels/addresses/addresses_viewmodel.dart';
import '../../presentation/viewmodels/auth/auth_cubit.dart';
import '../../presentation/viewmodels/registration/registration_cubit.dart';
import '../../presentation/widgets/shell/role_shells.dart';
import '../../constants/app_colors.dart';
import '../injection_container.dart';
import '../theme/app_theme.dart';
import 'app_routes.dart';

/// Ruta inicial de cada rol después de iniciar sesión.
String homeForRole(UserRole role) {
  switch (role) {
    case UserRole.entrepreneur:
      return AppRoutes.sellerHome;
    case UserRole.admin:
      return AppRoutes.adminHome;
    case UserRole.consumer:
      return AppRoutes.home;
  }
}

/// Notifica a go_router cuando cambia la sesión para re-evaluar redirecciones.
class _AuthRefresh extends ChangeNotifier {
  late final StreamSubscription _sub;
  _AuthRefresh(Stream stream) {
    _sub = stream.listen((_) => notifyListeners());
  }

  @override
  void dispose() {
    _sub.cancel();
    super.dispose();
  }
}

final _rootKey = GlobalKey<NavigatorState>(debugLabel: 'root');

GoRouter buildRouter() {
  final auth = sl<AuthCubit>();
  final prefs = sl<SharedPreferences>();

  GoRoute page(String path, Widget Function(GoRouterState s) builder) =>
      GoRoute(
        path: path,
        parentNavigatorKey: _rootKey,
        builder: (context, state) => builder(state),
      );

  // Las pantallas del emprendedor usan el acento naranja del Figma.
  Widget seller(Widget child) => Theme(
    data: AppTheme.light(seed: AppColors.seller),
    child: child,
  );

  return GoRouter(
    navigatorKey: _rootKey,
    initialLocation: AppRoutes.home,
    refreshListenable: _AuthRefresh(auth.stream),
    redirect: (context, state) {
      final loc = state.matchedLocation;
      final seenOnboarding = prefs.getBool('has_seen_onboarding') ?? false;
      final isPublic = AppRoutes.publicRoutes.contains(loc);

      if (!seenOnboarding && loc != AppRoutes.onboarding) {
        return AppRoutes.onboarding;
      }
      final user = auth.currentUser;
      if (user == null) {
        return isPublic ? null : AppRoutes.login;
      }
      if (isPublic) return homeForRole(user.role);
      // Cada rol se queda en su propia sección (p. ej. al abrir la app de nuevo).
      const consumerTabs = {
        AppRoutes.home,
        AppRoutes.promos,
        AppRoutes.orders,
        AppRoutes.favorites,
      };
      final inSeller = loc.startsWith(AppRoutes.sellerHome);
      final inAdmin = loc.startsWith(AppRoutes.adminHome);
      final inConsumerTabs = consumerTabs.contains(loc);
      final wrongArea = switch (user.role) {
        UserRole.consumer => inSeller || inAdmin,
        UserRole.entrepreneur => inAdmin || inConsumerTabs,
        UserRole.admin => inSeller || inConsumerTabs,
      };
      if (wrongArea) return homeForRole(user.role);
      return null;
    },
    routes: [
      // ── Acceso ──────────────────────────────────────────
      page(AppRoutes.onboarding, (_) => const OnboardingPage()),
      page(AppRoutes.login, (_) => const LoginPage()),
      page(
        AppRoutes.register,
        (_) => BlocProvider(
          create: (_) => sl<RegistrationCubit>(),
          child: const RegistrationPage(),
        ),
      ),
      page(AppRoutes.recoverPassword, (_) => const PasswordRecoveryPage()),
      page(
        AppRoutes.confirmEmail,
        (s) => const EmailConfirmationPage(),
      ),

      // ── Cliente ─────────────────────────────────────────
      StatefulShellRoute.indexedStack(
        builder: (context, state, shell) => ConsumerShell(shell: shell),
        branches: [
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoutes.home,
                builder: (_, _) => const ConsumerHomePage(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoutes.promos,
                builder: (_, _) => const PromosPage(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoutes.orders,
                builder: (_, _) => const OrdersPage(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoutes.favorites,
                builder: (_, _) => const FavoritesPage(),
              ),
            ],
          ),
        ],
      ),
      page(AppRoutes.search, (_) => const SearchPage()),
      page(AppRoutes.notifications, (_) => const NotificationsPage()),
      page(
        AppRoutes.product,
        (s) => ProductDetailPage(
          productId: s.pathParameters['id']!,
          product: s.extra as ProductEntity?,
        ),
      ),
      page(AppRoutes.store, (s) => StorePage(storeId: s.pathParameters['id']!)),
      page(AppRoutes.cart, (_) => const CartPage()),
      page(AppRoutes.checkout, (s) {
        final args = s.extra! as CheckoutArgs;
        return CheckoutPage(storeId: args.storeId, storeName: args.storeName);
      }),
      page(
        AppRoutes.orderTracking,
        (s) => OrderTrackingPage(orderId: s.pathParameters['id']!),
      ),
      page(
        AppRoutes.orderSuccess,
        (s) => OrderConfirmationPage(orderId: s.pathParameters['id']!),
      ),
      page(
        AppRoutes.orderReview,
        (s) => ProductReviewPage(orderId: s.pathParameters['id']!),
      ),

      // ── Perfil y ajustes ────────────────────────────────
      page(AppRoutes.profile, (_) => const ProfilePage()),
      page(AppRoutes.editProfile, (_) => const EditarPerfilPage()),
      page(AppRoutes.addresses, (_) => const AddressesManagementPage()),
      page(
        AppRoutes.addAddress,
        (s) => AddAddressPage(initial: s.extra as Address?),
      ),
      page(AppRoutes.mapAddress, (_) => const MapAddressPage()),
      page(AppRoutes.paymentMethods, (_) => const SavedPaymentMethodsPage()),
      page(AppRoutes.settings, (_) => const AjustesPage()),
      page(AppRoutes.settingsApp, (_) => const AppPreferencesPage()),
      page(AppRoutes.settingsOrders, (_) => const OrderPreferencesPage()),
      page(
        AppRoutes.settingsNotifications,
        (_) => const NotificationSettingsPage(),
      ),
      page(AppRoutes.settingsPrivacy, (_) => const PrivacySecurityPage()),
      page(AppRoutes.becomeSeller, (_) => const EntrepreneurPage()),
      page(AppRoutes.help, (_) => const HelpPage()),

      // ── Emprendedor ─────────────────────────────────────
      StatefulShellRoute.indexedStack(
        builder: (context, state, shell) => SellerShell(shell: shell),
        branches: [
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoutes.sellerHome,
                builder: (_, _) => const SellerHomePage(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoutes.sellerMenu,
                builder: (_, _) => const SellerMenuPage(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoutes.sellerPromos,
                builder: (_, _) => const SellerPromotionsPage(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoutes.sellerStats,
                builder: (_, _) => const SellerStatsPage(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoutes.sellerProfile,
                builder: (_, _) => const ProfilePage(showBack: false),
              ),
            ],
          ),
        ],
      ),
      page(
        AppRoutes.sellerNewProduct,
        (s) => seller(CreateProductPage(initial: s.extra as SellerProduct?)),
      ),
      page(
        AppRoutes.sellerPromoForm,
        (s) => seller(PromotionFormPage(initial: s.extra as PromotionEntity?)),
      ),
      page(AppRoutes.sellerSettings, (_) => seller(const StoreSettingsPage())),
      page(AppRoutes.sellerSchedule, (_) => seller(const SchedulePage())),
      page(AppRoutes.sellerBank, (_) => seller(const BankDataPage())),
      page(AppRoutes.sellerDocuments, (_) => seller(const DocumentsPage())),
      page(
        AppRoutes.sellerManagement,
        (_) => seller(
          Scaffold(
            appBar: AppBar(title: const Text('Gestión del negocio')),
            body: const EntrepreneurDashboard(),
          ),
        ),
      ),

      // ── Administrador ───────────────────────────────────
      StatefulShellRoute.indexedStack(
        builder: (context, state, shell) => AdminShell(shell: shell),
        branches: [
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoutes.adminHome,
                builder: (_, _) => const AdminHomePage(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoutes.adminUsers,
                builder: (_, _) => const ManageUsersPage(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoutes.adminBusinesses,
                builder: (_, _) => const ManageBusinessPage(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoutes.adminReports,
                builder: (_, _) => const ReportsPage(),
              ),
            ],
          ),
        ],
      ),
      page(AppRoutes.adminProducts, (_) => const ManageProductsPage()),
    ],
  );
}
