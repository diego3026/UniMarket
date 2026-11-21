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
import 'presentation/viewmodels/cart/cart_cubit.dart';
import 'presentation/viewmodels/favorites/favorites_cubit.dart';
import 'presentation/viewmodels/market/market_cubits.dart';
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

  /// Precio de cada producto según las promociones activas de su tienda.
  void _syncPricing() {
    final promos = di.sl<PromotionsCubit>();
    _productCubit.applyPricing((p) {
      final best = promos.bestFor(p.storeId, p.id, p.price);
      return best?.apply(p.price);
    });
  }

  @override
  void initState() {
    super.initState();
    _productCubit = di.sl<ProductCubit>();
    _syncPricing();
    _productCubit.loadProducts();
    di.sl<PromotionsCubit>().stream.listen((_) => _syncPricing());
    _productCubit.stream.listen((s) {
      if (s is ProductLoaded) di.sl<CartCubit>().refreshPrices(s.products);
    });
    // Sesión restaurada: cargar el perfil desde el inicio.
    if (di.sl<AuthCubit>().isAuthenticated()) {
      di.sl<ProfileCubit>().loadProfile();
    }
  }

  @override
  Widget build(BuildContext context) {
    final sl = di.sl;
    return MultiBlocProvider(
      providers: [
        BlocProvider.value(value: sl<AuthCubit>()),
        BlocProvider.value(value: _productCubit),
        BlocProvider.value(value: sl<StoreSettingsCubit>()),
        BlocProvider.value(value: sl<PromotionsCubit>()),
        BlocProvider.value(value: sl<MarketOrdersCubit>()),
        BlocProvider.value(value: sl<WalletCubit>()),
        BlocProvider.value(value: sl<CartCubit>()..loadCart()),
        BlocProvider.value(value: sl<FavoritesCubit>()..loadFavorites()),
        BlocProvider.value(value: sl<ProfileCubit>()),
        BlocProvider.value(value: sl<NotificationsCubit>()),
        BlocProvider(create: (_) => OnboardingCubit(sl<SharedPreferences>())),
      ],
      // Recarga el perfil cada vez que cambia la sesión.
      child: BlocListener<AuthCubit, AuthState>(
        listener: (context, state) {
          if (state is Authenticated) {
            final profile = sl<ProfileCubit>();
            profile.loadProfile();
          } else {
            sl<CartCubit>().clearCart();
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
