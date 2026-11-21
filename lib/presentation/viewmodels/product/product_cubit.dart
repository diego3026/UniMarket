// lib/presentation/viewmodels/product/product_cubit.dart
import 'package:flutter_bloc/flutter_bloc.dart';
export 'product_state.dart';
import '../../../domain/usecases/get_products_usecase.dart';
import '../../../domain/entities/product_entity.dart';
import 'product_state.dart';

class ProductCubit extends Cubit<ProductState> {
  final GetProductsUseCase getProductsUseCase;

  ProductCubit(this.getProductsUseCase) : super(ProductInitial());

  /// Catálogo sin descuentos y función que calcula el precio con promociones.
  List<ProductEntity> _base = [];
  double? Function(ProductEntity product)? _pricing;

  /// Recalcula los precios cuando el emprendedor cambia sus promociones.
  void applyPricing(double? Function(ProductEntity product) pricing) {
    _pricing = pricing;
    if (_base.isNotEmpty) emit(ProductLoaded(_priced()));
  }

  List<ProductEntity> _priced() {
    final f = _pricing;
    if (f == null) return _base;
    return [
      for (final p in _base)
        () {
          final d = f(p);
          return p.withDiscount(d != null && d < p.price ? d : null);
        }(),
    ];
  }

  Future<void> loadProducts() async {
    emit(ProductLoading());

    final result = await getProductsUseCase();

    result.fold((failure) => emit(ProductError(failure.toString())), (
      products,
    ) {
      _base = products;
      if (products.isEmpty) {
        emit(ProductEmpty());
      } else {
        emit(ProductLoaded(_priced()));
      }
    });
  }

  void filterByCategory(String category) {
    if (state is ProductLoaded) {
      final currentState = state as ProductLoaded;
      final filtered = currentState.products
          .where((product) => product.category == category)
          .toList();
      emit(ProductLoaded(filtered));
    }
  }

  void sortByPrice(bool ascending) {
    if (state is ProductLoaded) {
      final currentState = state as ProductLoaded;
      final sorted = List<ProductEntity>.from(currentState.products);
      sorted.sort(
        (a, b) => ascending
            ? a.finalPrice.compareTo(b.finalPrice)
            : b.finalPrice.compareTo(a.finalPrice),
      );
      emit(ProductLoaded(sorted));
    }
  }

  void searchProducts(String query) {
    if (state is ProductLoaded) {
      final originalState = state as ProductLoaded;
      final queryLower = query.toLowerCase();
      final filtered = originalState.products
          .where(
            (product) =>
                product.name.toLowerCase().contains(queryLower) ||
                product.description.toLowerCase().contains(queryLower) ||
                product.category.toLowerCase().contains(queryLower),
          )
          .toList();
      emit(ProductLoaded(filtered));
    }
  }

  /// Obtiene productos con descuentos activos (promos)
  List<ProductEntity> getPromoProducts() {
    if (state is ProductLoaded) {
      final currentState = state as ProductLoaded;
      return currentState.products
          .where((product) => product.isOnSale)
          .toList();
    }
    return [];
  }

  /// Obtiene productos destacados/principales para inicio
  List<ProductEntity> getFeaturedProducts() {
    if (state is ProductLoaded) {
      final currentState = state as ProductLoaded;
      return currentState.products
          .where((product) => product.isFeatured)
          .toList();
    }
    return [];
  }

  /// Obtiene todos los productos disponibles
  List<ProductEntity> getAllProducts() {
    if (state is ProductLoaded) {
      final currentState = state as ProductLoaded;
      return currentState.products;
    }
    return [];
  }
}
