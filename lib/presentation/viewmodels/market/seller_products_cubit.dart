import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/network/api_client.dart';
import '../../../data/api/mappers.dart';
import '../../../domain/entities/product_entity.dart';

/// Producto tal como lo ve su dueño (incluye disponibilidad y moderación).
class SellerProduct {
  final ProductEntity product;
  final bool isAvailable;
  final bool isHidden; // oculto por un administrador
  const SellerProduct(this.product, {required this.isAvailable, required this.isHidden});

  factory SellerProduct.fromJson(Json j) =>
      SellerProduct(productFrom(j), isAvailable: j['isAvailable'] != false, isHidden: j['isHidden'] == true);
}

class SellerProductsState {
  final List<SellerProduct> items;
  final bool loading;
  final String? error;
  const SellerProductsState({this.items = const [], this.loading = false, this.error});
}

/// Menú del emprendedor: /seller/products (listar, crear, editar, borrar).
class SellerProductsCubit extends Cubit<SellerProductsState> {
  final ApiClient _api;
  SellerProductsCubit(this._api) : super(const SellerProductsState());

  Future<void> load() async {
    emit(SellerProductsState(items: state.items, loading: true));
    try {
      final r = await _api.get('/seller/products') as List;
      emit(SellerProductsState(items: [for (final p in r) SellerProduct.fromJson(p as Json)]));
    } on ApiException catch (e) {
      emit(SellerProductsState(items: state.items, error: e.message));
    }
  }

  /// Crea (id null) o actualiza un producto. Devuelve un mensaje de error o null.
  Future<String?> save({String? id, required Json data}) async {
    try {
      if (id == null) {
        await _api.post('/seller/products', data: data);
      } else {
        await _api.patch('/seller/products/$id', data: data);
      }
      await load();
      return null;
    } on ApiException catch (e) {
      return e.message;
    }
  }

  Future<String?> setAvailable(String id, bool available) async {
    // Cambio optimista: el switch responde al instante.
    emit(SellerProductsState(items: [
      for (final p in state.items)
        p.product.id == id ? SellerProduct(p.product, isAvailable: available, isHidden: p.isHidden) : p,
    ]));
    return save(id: id, data: {'isAvailable': available});
  }

  Future<String?> delete(String id) async {
    try {
      await _api.delete('/seller/products/$id');
      await load();
      return null;
    } on ApiException catch (e) {
      return e.message;
    }
  }

  void clear() => emit(const SellerProductsState());
}
