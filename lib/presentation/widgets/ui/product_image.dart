import 'package:flutter/material.dart';

/// Imagen de producto o tienda.
///
/// Si hay URL válida la carga de red; si no (o falla), muestra un degradado
/// con un ícono según la categoría, para que la app nunca se vea "rota".
class ProductImage extends StatelessWidget {
  final String imageUrl;
  final String category;
  final double radius;
  final double? height;
  final double? width;
  final double iconSize;

  const ProductImage({
    super.key,
    required this.imageUrl,
    required this.category,
    this.radius = 16,
    this.height,
    this.width,
    this.iconSize = 40,
  });

  static const Map<String, (List<Color>, IconData)> _styles = {
    'comida': (
      [Color(0xFFFFB86B), Color(0xFFFF7A45)],
      Icons.lunch_dining_rounded,
    ),
    'bebidas': (
      [Color(0xFFFFD86B), Color(0xFFFF9F1C)],
      Icons.local_drink_rounded,
    ),
    'postres': ([Color(0xFFFFA6C9), Color(0xFFE8559A)], Icons.cake_rounded),
    'accesorios': (
      [Color(0xFFB9A7FF), Color(0xFF7C5CFA)],
      Icons.diamond_rounded,
    ),
    'ropa': ([Color(0xFF8FD3FF), Color(0xFF3B82F6)], Icons.checkroom_rounded),
    'papelería': (
      [Color(0xFF9BE7C4), Color(0xFF1FA463)],
      Icons.edit_note_rounded,
    ),
  };

  static (List<Color>, IconData) styleFor(String category) =>
      _styles[category.toLowerCase()] ??
      (
        [const Color(0xFFC9B8FF), const Color(0xFF6B3AEE)],
        Icons.storefront_rounded,
      );

  @override
  Widget build(BuildContext context) {
    final (colors, icon) = styleFor(category);
    final placeholder = DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: colors,
        ),
      ),
      child: Stack(
        children: [
          Positioned(
            right: -iconSize * 0.4,
            bottom: -iconSize * 0.4,
            child: Icon(
              icon,
              size: iconSize * 2.4,
              color: Colors.white.withValues(alpha: 0.18),
            ),
          ),
          Center(
            child: Icon(icon, size: iconSize, color: Colors.white),
          ),
        ],
      ),
    );

    final hasUrl = imageUrl.startsWith('http');
    return ClipRRect(
      borderRadius: BorderRadius.circular(radius),
      child: SizedBox(
        height: height,
        width: width,
        child: hasUrl
            ? Image.network(
                imageUrl,
                fit: BoxFit.cover,
                errorBuilder: (_, _, _) => placeholder,
              )
            : placeholder,
      ),
    );
  }
}
