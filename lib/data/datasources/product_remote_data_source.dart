// lib/data/datasources/product_remote_data_source.dart
import '../../core/network/api_client.dart';
import '../../domain/entities/product_entity.dart';
import '../api/mappers.dart';

abstract class ProductRemoteDataSource {
  Future<List<ProductEntity>> getProducts();
  Future<ProductEntity> getProductById(String id);
}

/// Catálogo desde `GET /api/v1/products`. `discountPrice` ya viene calculado por el servidor.
class ProductRemoteDataSourceImpl implements ProductRemoteDataSource {
  final ApiClient _api;
  ProductRemoteDataSourceImpl(this._api);

  /// Trae hasta 500 productos (5 páginas). Suficiente para el catálogo del campus;
  /// la búsqueda del servidor cubre el resto.
  @override
  Future<List<ProductEntity>> getProducts() async {
    final all = <ProductEntity>[];
    for (var page = 1; page <= 5; page++) {
      final r = await _api.getCached('/products', query: {'page': page, 'size': 100}) as Json;
      final items = r['items'] as List;
      all.addAll([for (final p in items) productFrom(p as Json)]);
      if (all.length >= (r['total'] as num) || items.isEmpty) break;
    }
    return all;
  }

  @override
  Future<ProductEntity> getProductById(String id) async =>
      productFrom(await _api.getCached('/products/$id') as Json);
}
