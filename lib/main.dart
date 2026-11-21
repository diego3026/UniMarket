// lib/main.dart
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'constants/app_colors.dart';
import 'core/injection_container.dart' as di;
import 'core/router/app_router.dart';
import 'core/theme/app_theme.dart';
import 'presentation/viewmodels/auth/auth_cubit.dart';
import 'presentation/viewmodels/auth/auth_state.dart';
import 'domain/entities/user_role.dart';
import 'presentation/viewmodels/cart/cart_cubit.dart';
import 'presentation/viewmodels/catalog/catalog_cubit.dart';
import 'presentation/viewmodels/favorites/favorites_cubit.dart';
import 'presentation/viewmodels/market/market_cubits.dart';
import 'presentation/viewmodels/market/seller_products_cubit.dart';
import 'presentation/viewmodels/notifications/notifications_cubit.dart';
import 'presentation/viewmodels/onboarding/onboarding_cubit.dart';
import 'presentation/viewmodels/product/product_cubit.dart';
import 'presentation/viewmodels/profile/app_preferences_controller.dart';
import 'presentation/viewmodels/profile/order_preferences_controller.dart';
import 'presentation/viewmodels/profile/privacy_security_controller.dart';
import 'presentation/viewmodels/profile/profile_cubit.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // Precarga la tipografía para que no "salte" el texto al abrir la app.
  GoogleFonts.plusJakartaSans();
  GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700);
  GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w800);
  await GoogleFonts.pendingFonts().catchError((_) => <void>[]);
  final appPreferences = await bootstrap();
  runApp(UniMarketApp(appPreferences: appPreferences));
}

/// Inicializa formatos, dependencias y preferencias. También lo usan las pruebas.
Future<AppPreferencesController> bootstrap() async {
  await initializeDateFormatting('es_CO');
  await di.init();

  final preferences = di.sl<SharedPreferences>();
  final appPreferences = AppPreferencesController(preferences);
  await appPreferences.load();
  di.sl.registerSingleton<AppPreferencesController>(appPreferences);
  final orderPreferences = OrderPreferencesController(preferences);
  await orderPreferences.load();
  di.sl.registerSingleton<OrderPreferencesController>(orderPreferences);
  final privacySecurity = PrivacySecurityController(preferences);
  await privacySecurity.load();
  di.sl.registerSingleton<PrivacySecurityController>(privacySecurity);
  // Recupera la sesión guardada (tokens cifrados) antes de mostrar la primera pantalla.
  await di.sl<AuthCubit>().restore();
  return appPreferences;
}

class UniMarketApp extends StatefulWidget {
  final AppPreferencesController appPreferences;
  const UniMarketApp({super.key, required this.appPreferences});

  @override
  State<UniMarketApp> createState() => _UniMarketAppState();
}

class _UniMarketAppState extends State<UniMarketApp> {
  late final GoRouter _router = buildRouter();

  late final ProductCubit _productCubit;

  @override
  void initState() {
    super.initState();
    _productCubit = di.sl<ProductCubit>();
    _productCubit.stream.listen((s) {
      if (s is ProductLoaded) di.sl<CartCubit>().refreshPrices(s.products);
    });
    final user = di.sl<AuthCubit>().currentUser;
    if (user != null) _loadSession(user);
  }

  /// Carga desde la API todo lo que necesita el usuario según su rol.
  void _loadSession(AuthUser user) {
    final sl = di.sl;
    sl<ProfileCubit>().loadProfile();
    sl<CatalogCubit>().load();
    _productCubit.loadProducts();
    sl<PromotionsCubit>().loadPublic();
    sl<FavoritesCubit>().loadFavorites();
    sl<NotificationsCubit>().loadNotifications(user.id, user.role);
    switch (user.role) {
      case UserRole.consumer:
        sl<MarketOrdersCubit>().loadMine();
        sl<WalletCubit>().load();
      case UserRole.entrepreneur:
        sl<CatalogCubit>().loadMyStore();
        sl<PromotionsCubit>().loadMine();
        sl<MarketOrdersCubit>().loadStore();
        sl<SellerProductsCubit>().load();
      case UserRole.admin:
        break;
    }
  }

  /// Al cerrar sesión no queda nada del usuario anterior en memoria.
  void _clearSession() {
    final sl = di.sl;
    sl<CartCubit>().clearCart();
    sl<CatalogCubit>().clear();
    sl<PromotionsCubit>().clear();
    sl<MarketOrdersCubit>().clear();
    sl<WalletCubit>().clear();
    sl<SellerProductsCubit>().clear();
    sl<FavoritesCubit>().clearFavorites();
    sl<NotificationsCubit>().clear();
  }

  @override
  Widget build(BuildContext context) {
    final sl = di.sl;
    return MultiBlocProvider(
      providers: [
        BlocProvider.value(value: sl<AuthCubit>()),
        BlocProvider.value(value: sl<CatalogCubit>()),
        BlocProvider.value(value: _productCubit),
        BlocProvider.value(value: sl<StoreSettingsCubit>()),
        BlocProvider.value(value: sl<PromotionsCubit>()),
        BlocProvider.value(value: sl<MarketOrdersCubit>()),
        BlocProvider.value(value: sl<WalletCubit>()),
        BlocProvider.value(value: sl<SellerProductsCubit>()),
        BlocProvider.value(value: sl<CartCubit>()..loadCart()),
        BlocProvider.value(value: sl<FavoritesCubit>()),
        BlocProvider.value(value: sl<ProfileCubit>()),
        BlocProvider.value(value: sl<NotificationsCubit>()),
        BlocProvider(create: (_) => OnboardingCubit(sl<SharedPreferences>())),
      ],
      // Carga o limpia los datos cuando entra o sale un usuario.
      child: BlocListener<AuthCubit, AuthState>(
        listenWhen: (a, b) =>
            a.runtimeType != b.runtimeType ||
            (a is Authenticated && b is Authenticated && (a.user.id != b.user.id || a.user.role != b.user.role)),
        listener: (context, state) {
          if (state is Authenticated) {
            _loadSession(state.user);
          } else {
            _clearSession();
          }
        },
        child: AnimatedBuilder(
          animation: widget.appPreferences,
          builder: (context, _) => MaterialApp.router(
            title: 'UniMarket',
            debugShowCheckedModeBanner: false,
            // El emprendedor usa el naranja del Figma en todas sus pantallas.
            theme: AppTheme.light(
              seed:
                  context.watch<AuthCubit>().currentUser?.role.isEntrepreneur ??
                      false
                  ? AppColors.seller
                  : AppColors.primary,
            ),
            routerConfig: _router,
            locale: widget.appPreferences.locale,
            supportedLocales: const [Locale('es'), Locale('en'), Locale('pt')],
            localizationsDelegates: const [
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
            ],
          ),
        ),
      ),
    );
  }
}
