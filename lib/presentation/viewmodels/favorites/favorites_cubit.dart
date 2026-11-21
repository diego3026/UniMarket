import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:unimarket/domain/entities/product_entity.dart';

import '../../../core/network/api_client.dart';
import '../../../data/api/mappers.dart';

part 'favorites_state.dart';

/// Favoritos guardados en la cuenta (se ven en cualquier dispositivo).
class FavoritesCubit extends Cubit<FavoritesState> {
  final ApiClient _api;
  FavoritesCubit(this._api) : super(const FavoritesInitial());

  List<ProductEntity> _items = [];

  List<ProductEntity> get items => _items;

  Future<void> loadFavorites() async {
    if (_items.isEmpty) emit(const FavoritesLoading());
    try {
      final r = await _api.get('/me/favorites') as List;
      _items = [for (final p in r) productFrom(p as Json)];
      emit(FavoritesLoaded(items: List.unmodifiable(_items)));
    } on ApiException catch (e) {
      emit(FavoritesError(message: e.message));
    }
  }

  /// Cambia el corazón al instante y lo guarda en la API; si falla, lo revierte.
  Future<void> toggleFavorite(ProductEntity product) async {
    final was = isFavorite(product.id);
    _items = was
        ? _items.where((p) => p.id != product.id).toList()
        : [product, ..._items];
    emit(FavoritesLoaded(items: List.unmodifiable(_items)));
    try {
      if (was) {
        await _api.delete('/me/favorites/${product.id}');
      } else {
        await _api.put('/me/favorites/${product.id}');
      }
    } on ApiException {
      _items = was ? [product, ..._items] : _items.where((p) => p.id != product.id).toList();
      emit(FavoritesLoaded(items: List.unmodifiable(_items)));
    }
  }

  void addToFavorites(ProductEntity product) {
    if (!isFavorite(product.id)) toggleFavorite(product);
  }

  void removeFromFavorites(String productId) {
    for (final p in _items) {
      if (p.id == productId) {
        toggleFavorite(p);
        return;
      }
    }
  }

  bool isFavorite(String productId) => _items.any((item) => item.id == productId);

  void clearFavorites() {
    _items = [];
    emit(const FavoritesLoaded(items: []));
  }
}
