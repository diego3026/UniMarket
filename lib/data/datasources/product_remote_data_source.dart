// lib/data/datasources/product_remote_data_source.dart
import '../models/product_model.dart';
import 'mock/catalog_mock_data.dart';

abstract class ProductRemoteDataSource {
  Future<List<ProductModel>> getProducts();
  Future<ProductModel> getProductById(String id);
}

/// Por ahora devuelve datos de ejemplo. Cuando el backend en FastAPI esté
/// listo, aquí se hará la llamada con Dio a `GET /api/v1/products`.
class ProductRemoteDataSourceImpl implements ProductRemoteDataSource {
  @override
  Future<List<ProductModel>> getProducts() async {
    await Future.delayed(const Duration(milliseconds: 600));
    return CatalogMockData.products();
  }

  @override
  Future<ProductModel> getProductById(String id) async {
    final products = await getProducts();
    return products.firstWhere((product) => product.id == id);
  }
}
