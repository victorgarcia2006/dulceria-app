import 'package:flutter/material.dart';

/// Espaciados de toda la app. No usar números sueltos en las pantallas.
class AppSpacing {
  AppSpacing._();

  static const double xs = 4;
  static const double sm = 8;
  static const double md = 16;
  static const double lg = 24;
  static const double xl = 32;
}

/// Radios de esquina de toda la app.
class AppRadius {
  AppRadius._();

  static const double card = 16;
  static const double chip = 8;
}

/// Colores de marca y de estado. Los demás salen del `ColorScheme` del tema.
class AppColors {
  AppColors._();

  /// Color semilla de Material 3 (frambuesa, tono de dulcería).
  static const Color seed = Color(0xFFD81B60);

  /// Advertencia (pocas existencias): texto/ícono y fondo suave.
  static const Color warning = Color(0xFFB26A00);
  static const Color warningContainer = Color(0xFFFFF1D6);

  /// Estados informativos de producto.
  static const Color agotado = Color(0xFFB3261E);
}

/// Altura mínima de cualquier botón (zona de toque cómoda).
const double kAlturaMinimaBoton = 48;

/// Único tema de la app (Material 3).
ThemeData buildAppTheme() {
  final scheme = ColorScheme.fromSeed(seedColor: AppColors.seed);
  const botonMinimo = Size(kAlturaMinimaBoton, kAlturaMinimaBoton);
  final formaBoton = RoundedRectangleBorder(
    borderRadius: BorderRadius.circular(AppRadius.card),
  );

  return ThemeData(
    useMaterial3: true,
    colorScheme: scheme,
    scaffoldBackgroundColor: scheme.surface,
    appBarTheme: AppBarTheme(
      centerTitle: false,
      backgroundColor: scheme.surface,
      foregroundColor: scheme.onSurface,
      scrolledUnderElevation: 0,
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        minimumSize: botonMinimo,
        shape: formaBoton,
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
      ),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        minimumSize: botonMinimo,
        shape: formaBoton,
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        minimumSize: botonMinimo,
        shape: formaBoton,
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        minimumSize: botonMinimo,
        shape: formaBoton,
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
      ),
    ),
    iconButtonTheme: IconButtonThemeData(
      style: IconButton.styleFrom(minimumSize: botonMinimo),
    ),
    floatingActionButtonTheme: const FloatingActionButtonThemeData(
      extendedPadding: EdgeInsets.symmetric(horizontal: AppSpacing.lg),
    ),
    cardTheme: CardThemeData(
      elevation: 0,
      color: scheme.surfaceContainerLow,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.card),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppRadius.card),
      ),
    ),
    snackBarTheme: const SnackBarThemeData(behavior: SnackBarBehavior.floating),
    dialogTheme: DialogThemeData(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.card),
      ),
    ),
    navigationBarTheme: NavigationBarThemeData(
      backgroundColor: scheme.surfaceContainer,
      height: 72,
    ),
  );
}
