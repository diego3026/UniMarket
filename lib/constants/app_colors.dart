// lib/constants/app_colors.dart
//
// Paleta oficial de UniMarket, tomada del Figma "UNIMARKET FIGMA".
// - Cliente: morado #4320A2 + amarillo #F2C849 (colores del logo).
// - Emprendedor: naranja #FF8A00 como acento (pantallas de "Tienda").
import 'package:flutter/material.dart';

class AppColors {
  AppColors._();

  // Marca
  static const Color primary = Color(0xFF4320A2);
  static const Color primaryDark = Color(0xFF2A0F78);
  static const Color primaryLight = Color(0xFF7C5CFA);
  static const Color secondary = Color(0xFF6B3AEE);
  static const Color accent = Color(0xFFF2C849);

  // Emprendedor
  static const Color seller = Color(0xFFFF8A00);
  static const Color sellerLight = Color(0xFFFFF1E0);

  // Superficies
  static const Color background = Color(0xFFF7F6FB);
  static const Color surface = Colors.white;
  static const Color surfaceMuted = Color(0xFFF1EFF8);
  static const Color lightPanel = Color(0xFFF1EDFF);
  static const Color border = Color(0xFFE7E5EE);

  // Texto
  static const Color textPrimary = Color(0xFF1C1B22);
  static const Color textSecondary = Color(0xFF676767);
  static const Color textMuted = Color(0xFFA2A2A2);

  // Estados
  static const Color success = Color(0xFF1FA463);
  static const Color warning = Color(0xFFF59E0B);
  static const Color danger = Color(0xFFE5484D);
  static const Color info = Color(0xFF3B82F6);
  static const Color successLight = Color(0xFFE6F6EE);
  static const Color warningLight = Color(0xFFFEF3E2);
  static const Color dangerLight = Color(0xFFFDECEC);

  // Degradados
  static const Gradient purpleGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [Color(0xFF2A0F78), Color(0xFF4320A2), Color(0xFF6B3AEE)],
    stops: [0.0, 0.55, 1.0],
  );

  static const Gradient bannerGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF9D7BFF), Color(0xFF6B3AEE)],
  );

  static const Gradient sellerGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFFFFA733), Color(0xFFFF7A00)],
  );
}
