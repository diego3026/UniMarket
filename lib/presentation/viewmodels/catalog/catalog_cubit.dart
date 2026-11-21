// lib/presentation/viewmodels/catalog/catalog_cubit.dart
//
// Datos de referencia que casi todas las pantallas necesitan: tiendas, lugares
// del campus y categorías. Se cargan de la API al iniciar sesión y se pueden
// leer de forma síncrona con `Catalog.*` (las pantallas se reconstruyen al
// cambiar porque escuchan este cubit).
import 'dart:ui';

import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/injection_container.dart';
import '../../../core/network/api_client.dart';
import '../../../data/api/mappers.dart';
import '../../../domain/entities/market_entities.dart';
import '../../../domain/entities/store_entity.dart';

class CatalogState {
  final List<StoreEntity> stores;
  final List<CampusPlace> places;
  final List<String> categories;

  /// Tienda del emprendedor que inició sesión (aunque esté pendiente de aprobación).
  final StoreEntity? myStore;
  final bool loading;
  final String? error;

  const CatalogState({
    this.stores = const [],
    this.places = const [],
    this.categories = const [],
    this.myStore,
    this.loading = false,
    this.error,
  });

  CatalogState copyWith({
    List<StoreEntity>? stores,
    List<CampusPlace>? places,
    List<String>? categories,
    StoreEntity? myStore,
    bool clearMyStore = false,
    bool? loading,
    String? error,
  }) => CatalogState(
    stores: stores ?? this.stores,
    places: places ?? this.places,
    categories: categories ?? this.categories,
    myStore: clearMyStore ? null : (myStore ?? this.myStore),
    loading: loading ?? this.loading,
    error: error,
  );
}

class CatalogCubit extends Cubit<CatalogState> {
  final ApiClient _api;
  CatalogCubit(this._api) : super(const CatalogState());

  /// Configuración de cada tienda, recibida junto con la tienda.
  final Map<String, StoreSettings> settings = {};

  Future<void> load() async {
    emit(state.copyWith(loading: true));
    try {
      final results = await Future.wait([
        _api.getCached('/stores', query: {'size': 100}),
        _api.getCached('/campus/places'),
        _api.getCached('/categories'),
      ]);
      final storesJson = (results[0] as Map)['items'] as List;
      for (final s in storesJson) {
        final j = s as Json;
        settings[j['id'].toString()] = settingsFrom(j);
      }
      emit(
        state.copyWith(
          stores: [for (final s in storesJson) storeFrom(s as Json)],
          places: [for (final p in results[1] as List) placeFrom(p as Json)],
          categories: [for (final c in results[2] as List) c.toString()],
          loading: false,
        ),
      );
    } on ApiException catch (e) {
      emit(state.copyWith(loading: false, error: e.message));
    }
  }

  /// Tienda propia del emprendedor (GET /seller/store).
  Future<void> loadMyStore() async {
    try {
      final j = await _api.get('/seller/store') as Json;
      settings[j['id'].toString()] = settingsFrom(j);
      emit(state.copyWith(myStore: storeFrom(j)));
    } on ApiException catch (e) {
      if (e.status == 404) emit(state.copyWith(clearMyStore: true));
    }
  }

  void setMyStore(Json j) {
    settings[j['id'].toString()] = settingsFrom(j);
    final store = storeFrom(j);
    emit(
      state.copyWith(
        myStore: store,
        stores: [for (final s in state.stores) s.id == store.id ? store : s],
      ),
    );
  }

  void clear() {
    settings.clear();
    emit(const CatalogState());
  }
}

/// Acceso rápido y síncrono a los datos del catálogo ya cargados.
class Catalog {
  Catalog._();

  static CatalogState get _s => sl<CatalogCubit>().state;

  static List<StoreEntity> get stores => _s.stores;
  static List<CampusPlace> get places => _s.places;
  static List<String> get categories => _s.categories;
  static StoreEntity? get myStore => _s.myStore;

  /// Tienda del emprendedor o una vacía mientras carga (evita pantallas rotas).
  static StoreEntity get myStoreOrEmpty =>
      _s.myStore ??
      const StoreEntity(id: '', name: 'Mi tienda', category: '', description: '', ownerName: '', status: 'pending');

  static StoreEntity? storeById(String id) {
    if (_s.myStore?.id == id) return _s.myStore;
    for (final s in _s.stores) {
      if (s.id == id) return s;
    }
    return null;
  }

  static CampusPlace place(String id) {
    for (final p in _s.places) {
      if (p.id == id) return p;
    }
    return _s.places.isNotEmpty
        ? _s.places.first
        : CampusPlace(id, id.isEmpty ? 'Campus' : id, '');
  }

  /// Pines que sirven para entregar o recoger pedidos.
  static List<CampusPlace> get deliveryPlaces => _s.places.where((p) => p.isDeliveryPoint).toList();
}
