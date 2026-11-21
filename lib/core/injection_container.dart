// lib/core/injection_container.dart
//
// Registro de dependencias (GetIt). Solo está lo que la app usa hoy.
import 'package:get_it/get_it.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'network/api_client.dart';
import 'network/token_storage.dart';
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
import '../presentation/viewmodels/catalog/catalog_cubit.dart';
import '../presentation/viewmodels/entrepreneur/bank_data_cubit.dart';
import '../presentation/viewmodels/entrepreneur/documents_cubit.dart';
import '../presentation/viewmodels/favorites/favorites_cubit.dart';
import '../presentation/viewmodels/market/market_cubits.dart';
import '../presentation/viewmodels/market/seller_products_cubit.dart';
import '../presentation/viewmodels/notifications/notifications_cubit.dart';
import '../presentation/viewmodels/product/product_cubit.dart';
import '../presentation/viewmodels/profile/profile_cubit.dart';
import '../presentation/viewmodels/registration/registration_cubit.dart';

final sl = GetIt.instance;

Future<void> init() async {
  // ── Externos ───────────────────────────────────────────
  final sharedPreferences = await SharedPreferences.getInstance();
  sl.registerLazySingleton(() => sharedPreferences);
  sl.registerLazySingleton(() => TokenStorage());
  sl.registerLazySingleton(() => ApiClient(sl()));

  // ── Datos ──────────────────────────────────────────────
  sl.registerLazySingleton<ProductRemoteDataSource>(
    () => ProductRemoteDataSourceImpl(sl()),
  );
  sl.registerLazySingleton<ProductRepository>(
    () => ProductRepositoryImpl(sl()),
  );
  sl.registerLazySingleton(() => GetProductsUseCase(sl()));

  // ── Estado global (una sola instancia en toda la app) ──
  sl.registerLazySingleton(() => AuthCubit(sl(), sl()));
  sl.registerLazySingleton(() => ProfileCubit(sl()));
  sl.registerLazySingleton(() => CatalogCubit(sl()));
  sl.registerLazySingleton(() => ProductCubit(sl()));
  sl.registerLazySingleton(() => CartCubit());
  sl.registerLazySingleton(() => FavoritesCubit(sl()));
  sl.registerLazySingleton(() => NotificationsCubit(sl()));
  sl.registerLazySingleton(() => StoreSettingsCubit(sl(), sl()));
  sl.registerLazySingleton(() => PromotionsCubit(sl()));
  sl.registerLazySingleton(() => MarketOrdersCubit(sl()));
  sl.registerLazySingleton(() => WalletCubit(sl()));
  sl.registerLazySingleton(() => SellerProductsCubit(sl()));

  // ── Estado por pantalla (una instancia nueva cada vez) ─
  sl.registerFactory(() => RegistrationCubit(sl()));
  sl.registerFactory(() => AddressesCubit(sl()));
  sl.registerFactory(() => BankDataCubit(sl()));
  sl.registerFactory(() => DocumentsCubit(sl()));
  sl.registerFactory(() => AdminUsersCubit(sl()));
  sl.registerFactory(() => AdminBusinessesCubit(sl()));
  sl.registerFactory(() => AdminProductsCubit(sl()));
  sl.registerFactory(() => ReportsCubit(sl()));
}
