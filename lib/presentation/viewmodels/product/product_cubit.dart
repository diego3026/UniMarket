// lib/presentation/viewmodels/product/product_cubit.dart
// Catálogo de productos. Los precios con descuento ya vienen calculados por la API.
import 'package:flutter_bloc/flutter_bloc.dart';
export 'product_state.dart';
import '../../../domain/usecases/get_products_usecase.dart';
import '../../../domain/entities/product_entity.dart';
import 'product_state.dart';

class ProductCubit extends Cubit<ProductState> {
  final GetProductsUseCase getProductsUseCase;

  ProductCubit(this.getProductsUseCase) : super(ProductInitial());

  /// Carga el catálogo. Si ya había productos no muestra el cargando (refresco suave).
  Future<void> loadProducts() async {
    if (state is! ProductLoaded) emit(ProductLoading());

    final result = await getProductsUseCase();

    result.fold((failure) => emit(ProductError(failure.message)), (products) {
      _all = products;
      emit(products.isEmpty ? ProductEmpty() : ProductLoaded(products));
    });
  }

  List<ProductEntity> _all = [];

  /// Vuelve a mostrar todo el catálogo después de filtrar o buscar.
  void resetFilters() {
    if (_all.isNotEmpty) emit(ProductLoaded(_all));
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
