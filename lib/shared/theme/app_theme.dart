import 'package:flutter/material.dart';

import '../../core/constants/app_colors.dart';

class AppTheme {
  AppTheme._();

  static const brandGradient = LinearGradient(
    colors: [AppColors.primary700, AppColors.primary500],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  // Selalu terang (lihat SiMasjidApp.themeMode) — tampilan elegan/profesional
  // yang diinginkan bergantung pada latar terang; sebelumnya app juga
  // mengikuti dark mode sistem HP, yang membuat teks di atas kartu/tile
  // berlatar terang (mis. Menu Cepat, ringkasan kelas) jadi tak terbaca
  // karena warna teks default ikut berubah jadi terang juga.
  static ThemeData get light {
    const surface = Colors.white;
    const onSurface = AppColors.slate900;
    const border = AppColors.slate200;

    final colorScheme = ColorScheme(
      brightness: Brightness.light,
      primary: AppColors.primary600,
      onPrimary: Colors.white,
      secondary: AppColors.gold500,
      onSecondary: Colors.white,
      error: AppColors.danger,
      onError: Colors.white,
      surface: surface,
      onSurface: onSurface,
    );

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: AppColors.slate50,
      appBarTheme: const AppBarTheme(
        backgroundColor: surface,
        foregroundColor: onSurface,
        elevation: 0,
        centerTitle: false,
        surfaceTintColor: Colors.transparent,
      ),
      cardTheme: CardThemeData(
        color: surface,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: border),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: surface,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.primary600, width: 1.5),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary600,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 14),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          textStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
        ),
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: surface,
        selectedItemColor: AppColors.primary600,
        unselectedItemColor: AppColors.slate500,
        type: BottomNavigationBarType.fixed,
      ),
      textTheme: ThemeData(brightness: Brightness.light).textTheme.apply(
            bodyColor: onSurface,
            displayColor: onSurface,
          ),
    );
  }
}
