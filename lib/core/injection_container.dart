// lib/core/injection_container.dart
//
// Registro de dependencias (GetIt). Solo está lo que la app usa hoy.
import 'package:dio/dio.dart';
import 'package:get_it/get_it.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../constants/app_constants.dart';
import '../data/datasources/product_remote_data_source.dart';
import '../data/repositories/product_repository_impl.dart';
import '../domain/repositories/product_repository.dart';
import '../domain/usecases/get_products_usecase.dart';
import '../presentation/viewmodels/addresses/addresses_cubit.dart';
import '../presentation/viewmodels/admin/admin_businesses_products_cubit.dart';
import '../presentation/viewmodels/admin/admin_users_cubit.dart';
import '../presentation/viewmodels/admin/reports_cubit.dart';
import '../presentation/viewmodels/auth/auth_cubit.dart';
import '../presentation/viewmodels/cart/cart_cubit.dart';
import '../presentation/viewmodels/email_confirmation/email_confirmation_cubit.dart';
import '../presentation/viewmodels/entrepreneur/bank_data_cubit.dart';
import '../presentation/viewmodels/entrepreneur/documents_cubit.dart';
import '../presentation/viewmodels/favorites/favorites_cubit.dart';
import '../presentation/viewmodels/market/market_cubits.dart';
import '../presentation/viewmodels/notifications/notifications_cubit.dart';
import '../presentation/viewmodels/product/product_cubit.dart';
import '../presentation/viewmodels/profile/profile_cubit.dart';
import '../presentation/viewmodels/registration/registration_cubit.dart';

final sl = GetIt.instance;

Future<void> init() async {
  // ── Externos ───────────────────────────────────────────
  final sharedPreferences = await SharedPreferences.getInstance();
  sl.registerLazySingleton(() => sharedPreferences);
  sl.registerLazySingleton(
    () => Dio(
      BaseOptions(
        baseUrl: AppConstants.apiBaseUrl,
        connectTimeout: const Duration(milliseconds: AppConstants.apiTimeout),
      ),
    ),
  );

  // ── Datos ──────────────────────────────────────────────
  sl.registerLazySingleton<ProductRemoteDataSource>(
    () => ProductRemoteDataSourceImpl(),
  );
  sl.registerLazySingleton<ProductRepository>(
    () => ProductRepositoryImpl(sl()),
  );
  sl.registerLazySingleton(() => GetProductsUseCase(sl()));

  // ── Estado global (una sola instancia en toda la app) ──
  sl.registerLazySingleton(() => AuthCubit(sl()));
  sl.registerLazySingleton(() => ProfileCubit());
  sl.registerLazySingleton(() => ProductCubit(sl()));
  sl.registerLazySingleton(() => CartCubit());
  sl.registerLazySingleton(() => FavoritesCubit());
  sl.registerLazySingleton(() => NotificationsCubit());
  sl.registerLazySingleton(() => StoreSettingsCubit());
  sl.registerLazySingleton(() => PromotionsCubit());
  sl.registerLazySingleton(() => MarketOrdersCubit());
  sl.registerLazySingleton(() => WalletCubit());

  // ── Estado por pantalla (una instancia nueva cada vez) ─
  sl.registerFactory(() => RegistrationCubit());
  sl.registerFactory(() => EmailConfirmationCubit());
  sl.registerFactory(() => AddressesCubit());
  sl.registerFactory(() => BankDataCubit());
  sl.registerFactory(() => DocumentsCubit());
  sl.registerFactory(() => AdminUsersCubit());
  sl.registerFactory(() => AdminBusinessesCubit());
  sl.registerFactory(() => AdminProductsCubit());
  sl.registerFactory(() => ReportsCubit());
}
