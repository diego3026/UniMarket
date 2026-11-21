import 'package:unimarket/domain/entities/product_entity.dart';

class CartItem {
  final ProductEntity product;
  int quantity;

  CartItem({required this.product, this.quantity = 1});

  double get totalPrice => product.finalPrice * quantity;

  CartItem copyWith({ProductEntity? product, int? quantity}) {
    return CartItem(
      product: product ?? this.product,
      quantity: quantity ?? this.quantity,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CartItem &&
          runtimeType == other.runtimeType &&
          product.id == other.product.id &&
          quantity == other.quantity;

  @override
  int get hashCode => Object.hash(product.id, quantity);
}
