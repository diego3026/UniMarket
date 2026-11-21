// lib/domain/entities/product_entity.dart
import 'package:equatable/equatable.dart';

class ProductEntity extends Equatable {
  final String id;
  final String name;
  final String description;
  final double price;
  final double? discountPrice;
  final String category;
  final String imageUrl;
  final int stock;
  final double rating;
  final bool isFeatured;
  final DateTime createdAt;
  final String storeId;
  final String storeName;

  const ProductEntity({
    required this.id,
    required this.name,
    required this.description,
    required this.price,
    this.discountPrice,
    required this.category,
    required this.imageUrl,
    required this.stock,
    this.rating = 0.0,
    this.isFeatured = false,
    required this.createdAt,
    this.storeId = '',
    this.storeName = '',
  });

  double get finalPrice => discountPrice ?? price;

  /// Copia con otro precio de descuento (null = sin descuento).
  ProductEntity withDiscount(double? newDiscount) => ProductEntity(
    id: id,
    name: name,
    description: description,
    price: price,
    discountPrice: newDiscount,
    category: category,
    imageUrl: imageUrl,
    stock: stock,
    rating: rating,
    isFeatured: isFeatured,
    createdAt: createdAt,
    storeId: storeId,
    storeName: storeName,
  );
  double get discountPercentage =>
      discountPrice != null ? ((price - discountPrice!) / price * 100) : 0.0;
  bool get hasStock => stock > 0;
  bool get isOnSale => discountPrice != null;

  @override
  List<Object?> get props => [
    id,
    name,
    description,
    price,
    discountPrice,
    category,
    imageUrl,
    stock,
    rating,
    isFeatured,
    createdAt,
    storeId,
    storeName,
  ];
}
