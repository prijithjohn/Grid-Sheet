import 'package:flutter/material.dart';

import 'app_colors.dart';
import 'app_typography.dart';

/// Desktop ThemeData builders for Light ("Grid Professional") and Dark ("Graphite & Mint").
class AppTheme {
  AppTheme._();

  /// Light theme matching Stitch "Grid Professional" specs.
  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      colorScheme: const ColorScheme.light(
        primary: AppColors.primary,
        onPrimary: AppColors.canvasWhite,
        primaryContainer: AppColors.primaryContainer,
        surface: AppColors.canvasWhite,
        onSurface: AppColors.textPrimary,
        outline: AppColors.neutralBorder,
      ),
      scaffoldBackgroundColor: AppColors.recessedChrome,
      dividerColor: AppColors.neutralBorder,
      fontFamily: AppTypography.uiFontFamily,
      tooltipTheme: const TooltipThemeData(
        waitDuration: Duration(milliseconds: 500),
        textStyle: TextStyle(fontSize: 11, color: AppColors.canvasWhite),
        decoration: BoxDecoration(
          color: AppColors.textPrimary,
          borderRadius: BorderRadius.all(Radius.circular(2)),
        ),
      ),
    );
  }

  /// Dark theme matching Stitch "Graphite & Mint" specs.
  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: const ColorScheme.dark(
        primary: AppColors.mintPrimary,
        onPrimary: AppColors.darkSurface,
        primaryContainer: AppColors.mintContainer,
        surface: AppColors.darkSurface,
        onSurface: AppColors.darkTextPrimary,
        outline: AppColors.darkGridline,
      ),
      scaffoldBackgroundColor: AppColors.darkSurfaceLow,
      dividerColor: AppColors.darkGridline,
      fontFamily: AppTypography.uiFontFamily,
    );
  }
}
