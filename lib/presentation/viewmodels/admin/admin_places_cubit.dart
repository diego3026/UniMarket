import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/injection_container.dart';
import '../../../core/network/api_client.dart';
import '../../../data/api/mappers.dart';
import '../../../domain/entities/market_entities.dart';
import '../catalog/catalog_cubit.dart';

class AdminPlacesState {
  final List<CampusPlace> places;
  final bool loading;
  final String? error;
  const AdminPlacesState({
    this.places = const [],
    this.loading = false,
    this.error,
  });
}

/// Pines del mapa que administra el admin (/admin/places).
class AdminPlacesCubit extends Cubit<AdminPlacesState> {
  final ApiClient _api;
  AdminPlacesCubit(this._api) : super(const AdminPlacesState());

  Future<void> load() async {
    emit(AdminPlacesState(places: state.places, loading: true));
    try {
      final r = await _api.get('/admin/places') as List;
      emit(AdminPlacesState(places: [for (final p in r) placeFrom(p as Json)]));
    } on ApiException catch (e) {
      emit(AdminPlacesState(places: state.places, error: e.message));
    }
  }

  /// Crea (id vacío) o actualiza un pin. Devuelve el error o null.
  Future<String?> save(CampusPlace p) async {
    try {
      if (p.id.isEmpty) {
        await _api.post('/admin/places', data: placeToJson(p));
      } else {
        await _api.patch('/admin/places/${p.id}', data: placeToJson(p));
      }
      await _refresh();
      return null;
    } on ApiException catch (e) {
      return e.message;
    }
  }

  Future<String?> remove(String id) async {
    try {
      await _api.delete('/admin/places/$id');
      await _refresh();
      return null;
    } on ApiException catch (e) {
      return e.message;
    }
  }

  /// Recarga la lista y los pines que ve el resto de la app.
  Future<void> _refresh() async {
    await load();
    _api.clearCache();
    sl<CatalogCubit>().load();
  }
}
