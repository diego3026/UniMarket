// lib/data/repositories/product_repository_impl.dart
import '../../domain/repositories/product_repository.dart';
import '../../domain/entities/product_entity.dart';
import '../../core/errors/failures.dart';
import '../datasources/product_remote_data_source.dart';
import 'package:dartz/dartz.dart';

class ProductRepositoryImpl implements ProductRepository {
  final ProductRemoteDataSource remoteDataSource;

  ProductRepositoryImpl(this.remoteDataSource);

  @override
  Future<Either<Failure, List<ProductEntity>>> getProducts() async {
    try {
      final products = await remoteDataSource.getProducts();
      return Right(products);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, ProductEntity>> getProductById(String id) async {
    try {
      final product = await remoteDataSource.getProductById(id);
      return Right(product);
    } catch (e) {
      return Left(ServerFailure('Error al obtener producto: $e'));
    }
  }

  @override
  Future<Either<Failure, List<ProductEntity>>> getProductsByCategory(
    String category,
  ) async {
    // Implementación
    return Left(ServerFailure('No implementado'));
  }

  @override
  Future<Either<Failure, List<ProductEntity>>> searchProducts(
    String query,
  ) async {
    // Implementación
    return Left(ServerFailure('No implementado'));
  }

  @override
  Future<Either<Failure, List<ProductEntity>>> getFeaturedProducts() async {
    try {
      final products = await remoteDataSource.getProducts();
      final featured = products.where((p) => p.isFeatured).toList();
      return Right(featured);
    } catch (e) {
      return Left(ServerFailure('Error al obtener destacados: $e'));
    }
  }
}
