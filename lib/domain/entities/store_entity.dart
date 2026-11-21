// lib/domain/entities/store_entity.dart
import 'package:equatable/equatable.dart';

/// Emprendimiento (tienda) de un estudiante en UniMarket.
class StoreEntity extends Equatable {
  final String id;
  final String name;
  final String category;
  final String description;
  final String ownerName;
  final String location;
  final String schedule;
  final double rating;
  final int deliveryMinutes;
  final bool isOpen;
  final String imageUrl;
  final List<String> menuSections;

  const StoreEntity({
    required this.id,
    required this.name,
    required this.category,
    required this.description,
    required this.ownerName,
    this.location = 'Campus Universidad del Magdalena',
    this.schedule = 'Lun a Vie · 8:00 a. m. – 5:00 p. m.',
    this.rating = 4.5,
    this.deliveryMinutes = 20,
    this.isOpen = true,
    this.imageUrl = '',
    this.menuSections = const [],
  });

  @override
  List<Object?> get props => [id, name, category, isOpen];
}
