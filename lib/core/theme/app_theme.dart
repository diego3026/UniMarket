import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../constants/app_colors.dart';

/// Tema global de UniMarket.
///
/// Todas las pantallas heredan de aquí colores, tipografía, botones, campos
/// de texto, tarjetas y chips, para que la app se vea consistente con el Figma.
class AppTheme {
  AppTheme._();

  static const double radiusSm = 10;
  static const double radiusMd = 16;
  static const double radiusLg = 24;
  static const double pagePadding = 20;

  /// En las pruebas automáticas se desactiva para no descargar fuentes.
  static bool useGoogleFonts = true;

  static ThemeData light({Color seed = AppColors.primary}) {
    final scheme =
        ColorScheme.fromSeed(
          seedColor: seed,
          brightness: Brightness.light,
        ).copyWith(
          primary: seed,
          secondary: AppColors.accent,
          surface: AppColors.surface,
          error: AppColors.danger,
        );

    final baseText = useGoogleFonts
        ? GoogleFonts.plusJakartaSansTextTheme()
        : ThemeData.light().textTheme;
    final textTheme = baseText.copyWith(
      displaySmall: baseText.displaySmall?.copyWith(
        fontWeight: FontWeight.w800,
        color: AppColors.textPrimary,
        letterSpacing: -0.5,
      ),
      headlineMedium: baseText.headlineMedium?.copyWith(
        fontWeight: FontWeight.w800,
        color: AppColors.textPrimary,
        letterSpacing: -0.4,
      ),
      headlineSmall: baseText.headlineSmall?.copyWith(
        fontWeight: FontWeight.w700,
        color: AppColors.textPrimary,
      ),
      titleLarge: baseText.titleLarge?.copyWith(
        fontSize: 19,
        fontWeight: FontWeight.w700,
        color: AppColors.textPrimary,
      ),
      titleMedium: baseText.titleMedium?.copyWith(
        fontWeight: FontWeight.w700,
        color: AppColors.textPrimary,
      ),
      titleSmall: baseText.titleSmall?.copyWith(
        fontWeight: FontWeight.w600,
        color: AppColors.textPrimary,
      ),
      bodyLarge: baseText.bodyLarge?.copyWith(color: AppColors.textPrimary),
      bodyMedium: baseText.bodyMedium?.copyWith(color: AppColors.textPrimary),
      bodySmall: baseText.bodySmall?.copyWith(color: AppColors.textSecondary),
      labelLarge: baseText.labelLarge?.copyWith(fontWeight: FontWeight.w700),
    );

    final rounded = RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(radiusMd),
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      textTheme: textTheme,
      scaffoldBackgroundColor: AppColors.background,
      splashFactory: InkSparkle.splashFactory,
      appBarTheme: AppBarTheme(
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        backgroundColor: AppColors.background,
        surfaceTintColor: Colors.transparent,
        foregroundColor: AppColors.textPrimary,
        titleTextStyle: textTheme.titleLarge,
      ),
      cardTheme: CardThemeData(
        color: AppColors.surface,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radiusMd),
          side: const BorderSide(color: AppColors.border),
        ),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radiusLg),
        ),
      ),
      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: AppColors.surface,
        showDragHandle: true,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(radiusLg)),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: seed,
          foregroundColor: Colors.white,
          minimumSize: const Size.fromHeight(54),
          shape: rounded,
          textStyle: textTheme.labelLarge?.copyWith(fontSize: 16),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: seed,
          foregroundColor: Colors.white,
          elevation: 0,
          minimumSize: const Size(64, 48),
          shape: rounded,
          textStyle: textTheme.labelLarge,
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: seed,
          minimumSize: const Size(64, 48),
          side: BorderSide(color: seed.withValues(alpha: 0.35)),
          shape: rounded,
          textStyle: textTheme.labelLarge,
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: seed,
          textStyle: textTheme.labelLarge,
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.surface,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 16,
        ),
        hintStyle: textTheme.bodyMedium?.copyWith(color: AppColors.textMuted),
        labelStyle: textTheme.bodyMedium?.copyWith(
          color: AppColors.textSecondary,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusMd),
          borderSide: const BorderSide(color: AppColors.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusMd),
          borderSide: const BorderSide(color: AppColors.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusMd),
          borderSide: BorderSide(color: seed, width: 1.6),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusMd),
          borderSide: const BorderSide(color: AppColors.danger),
        ),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: AppColors.surface,
        selectedColor: seed,
        labelStyle: textTheme.labelLarge?.copyWith(fontSize: 13),
        secondaryLabelStyle: textTheme.labelLarge?.copyWith(
          fontSize: 13,
          color: Colors.white,
        ),
        side: const BorderSide(color: AppColors.border),
        shape: const StadiumBorder(),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        showCheckmark: false,
      ),
      listTileTheme: ListTileThemeData(
        iconColor: AppColors.textSecondary,
        titleTextStyle: textTheme.titleSmall,
        subtitleTextStyle: textTheme.bodySmall,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16),
      ),
      dividerTheme: const DividerThemeData(
        color: AppColors.border,
        space: 1,
        thickness: 1,
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: AppColors.textPrimary,
        contentTextStyle: textTheme.bodyMedium?.copyWith(color: Colors.white),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radiusSm),
        ),
      ),
      tabBarTheme: TabBarThemeData(
        labelColor: seed,
        unselectedLabelColor: AppColors.textSecondary,
        indicatorColor: seed,
        labelStyle: textTheme.labelLarge,
        dividerColor: Colors.transparent,
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: seed,
        foregroundColor: Colors.white,
      ),
    );
  }
}
