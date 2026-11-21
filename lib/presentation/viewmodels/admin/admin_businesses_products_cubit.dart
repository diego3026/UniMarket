import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/network/api_client.dart';
import 'admin_businesses_products_state.dart';

/// Revisión de tiendas (GET /admin/stores, POST /admin/stores/{id}/review).
class AdminBusinessesCubit extends Cubit<AdminBusinessesState> {
  final ApiClient _api;
  AdminBusinessesCubit(this._api) : super(const AdminBusinessesInitial());

  List<AdminBusinessModel> _businesses = [];

  Future<void> loadBusinesses() async {
    if (_businesses.isEmpty) emit(const AdminBusinessesLoading());
    try {
      final r = await _api.get('/admin/stores', query: {'size': 100}) as Map<String, dynamic>;
      _businesses = [for (final b in r['items'] as List) AdminBusinessModel.fromJson(b as Map<String, dynamic>)]
        // las pendientes de revisión primero
        ..sort((a, b) => (a.status == 'Pendiente' ? 0 : 1).compareTo(b.status == 'Pendiente' ? 0 : 1));
      emit(AdminBusinessesLoaded(businesses: _businesses, totalCount: (r['total'] as num).toInt()));
    } on ApiException catch (e) {
      emit(AdminBusinessesError(e.message));
    }
  }

  Future<void> _review(String id, String status, [String note = '']) async {
    try {
      await _api.post('/admin/stores/$id/review', data: {'status': status, 'note': note});
    } on ApiException catch (e) {
      emit(AdminBusinessesError(e.message));
    }
    await loadBusinesses();
  }

  Future<void> suspendBusiness(String id) => _review(id, 'suspended');

  /// Aprueba una tienda pendiente o reactiva una suspendida.
  Future<void> activateBusiness(String id) => _review(id, 'approved');

  Future<void> deleteBusiness(String id) => _review(id, 'rejected');

  Future<void> rejectBusiness(String id, String note) => _review(id, 'rejected', note);

  Map<String, dynamic> getBusinessStatistics() => {
    'totalBusinesses': _businesses.length,
    'activeBusinesses': _businesses.where((b) => b.status == 'Activo').length,
    'pendingBusinesses': _businesses.where((b) => b.status == 'Pendiente').length,
    'averageRating': _businesses.isEmpty
        ? 0.0
        : _businesses.map((b) => b.rating).reduce((a, b) => a + b) / _businesses.length,
  };
}

/// Moderación de productos (GET /admin/products, POST /admin/products/{id}/moderate).
class AdminProductsCubit extends Cubit<AdminProductsState> {
  final ApiClient _api;
  AdminProductsCubit(this._api) : super(const AdminProductsInitial());

  List<AdminProductModel> _products = [];

  Future<void> loadProducts() async {
    if (_products.isEmpty) emit(const AdminProductsLoading());
    try {
      final r = await _api.get('/admin/products', query: {'size': 100}) as Map<String, dynamic>;
      _products = [for (final p in r['items'] as List) AdminProductModel.fromJson(p as Map<String, dynamic>)];
      emit(AdminProductsLoaded(products: _products, totalCount: (r['total'] as num).toInt()));
    } on ApiException catch (e) {
      emit(AdminProductsError(e.message));
    }
  }

  Future<void> _moderate(String id, bool hidden) async {
    try {
      await _api.post('/admin/products/$id/moderate', data: {'isHidden': hidden});
    } on ApiException catch (e) {
      emit(AdminProductsError(e.message));
    }
    await loadProducts();
  }

  Future<void> approveProduct(String id) => _moderate(id, false);
  Future<void> rejectProduct(String id) => _moderate(id, true);
  Future<void> deleteProduct(String id) => _moderate(id, true);

  Map<String, dynamic> getProductStatistics() => {
    'totalProducts': _products.length,
    'activeProducts': _products.where((p) => p.status == 'Activo').length,
    'hiddenProducts': _products.where((p) => p.status == 'Rechazado').length,
  };
}
