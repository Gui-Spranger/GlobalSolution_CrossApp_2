import 'package:flutter/material.dart';

/// Paleta do Radar Territorial (tema escuro). Todas as cores de texto têm
/// contraste mínimo AA sobre o fundo.
class AppColors {
  AppColors._();

  static const background = Color(0xFF0E1316);
  static const surface = Color(0xFF172027);
  static const surfaceHigh = Color(0xFF1F2A32);
  static const border = Color(0xFF2B3740);
  static const text = Color(0xFFE7EEF2);
  static const muted = Color(0xFFA3B1BA);

  static const primary = Color(0xFF4FD1C5); // verde-água
  static const amber = Color(0xFFF6AD55); // projeção / atenção
  static const red = Color(0xFFFF7B7B); // crítico / capacidade
  static const blue = Color(0xFF7CC4FA); // observação / chuva
  static const green = Color(0xFF7BE0A0); // ok
}

/// Troca de tela instantânea, sem animação.
class NoTransitionsBuilder extends PageTransitionsBuilder {
  const NoTransitionsBuilder();

  @override
  Widget buildTransitions<T>(
    PageRoute<T> route,
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) =>
      child;
}

ThemeData buildDarkTheme() {
  const scheme = ColorScheme.dark(
    primary: AppColors.primary,
    onPrimary: Color(0xFF00201D),
    secondary: AppColors.amber,
    onSecondary: Colors.black,
    surface: AppColors.surface,
    onSurface: AppColors.text,
    error: AppColors.red,
    onError: Colors.black,
    outline: AppColors.border,
  );
  final radius = BorderRadius.circular(12);

  return ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    colorScheme: scheme,
    scaffoldBackgroundColor: AppColors.background,
    dividerColor: AppColors.border,
    splashFactory: NoSplash.splashFactory,
    pageTransitionsTheme: const PageTransitionsTheme(builders: {
      TargetPlatform.android: NoTransitionsBuilder(),
      TargetPlatform.iOS: NoTransitionsBuilder(),
      TargetPlatform.fuchsia: NoTransitionsBuilder(),
      TargetPlatform.linux: NoTransitionsBuilder(),
      TargetPlatform.macOS: NoTransitionsBuilder(),
      TargetPlatform.windows: NoTransitionsBuilder(),
    }),
    appBarTheme: const AppBarTheme(
      backgroundColor: AppColors.background,
      foregroundColor: AppColors.text,
      elevation: 0,
      scrolledUnderElevation: 0,
      titleTextStyle: TextStyle(
          fontSize: 20, fontWeight: FontWeight.w700, color: AppColors.text),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: AppColors.surface,
      labelStyle: const TextStyle(color: AppColors.muted),
      helperStyle: const TextStyle(color: AppColors.muted),
      border: OutlineInputBorder(borderRadius: radius),
      enabledBorder: OutlineInputBorder(
          borderRadius: radius,
          borderSide: const BorderSide(color: AppColors.border)),
      focusedBorder: OutlineInputBorder(
          borderRadius: radius,
          borderSide: const BorderSide(color: AppColors.primary, width: 2)),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        minimumSize: const Size(64, 52),
        shape: RoundedRectangleBorder(borderRadius: radius),
        textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
      ),
    ),
    bottomNavigationBarTheme: const BottomNavigationBarThemeData(
      backgroundColor: AppColors.surface,
      selectedItemColor: AppColors.primary,
      unselectedItemColor: AppColors.muted,
      type: BottomNavigationBarType.fixed,
    ),
    snackBarTheme: const SnackBarThemeData(
      backgroundColor: AppColors.surfaceHigh,
      contentTextStyle: TextStyle(color: AppColors.text),
    ),
  );
}
