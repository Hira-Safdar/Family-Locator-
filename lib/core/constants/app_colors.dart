import 'package:flutter/material.dart';

abstract final class AppColors {
  static const primary = Color(0xFF2E7D32);
  static const primaryContainer = Color(0xFFA5D6A7);
  static const onPrimary = Color(0xFFFFFFFF);

  static const background = Color(0xFFF5F5F5);
  static const surface = Color(0xFFFFFFFF);

  static const textDark = Color(0xFF1B1B1B);
  static const textLight = Color(0xff616161);

  static const error = Color(0xFFD32F2F);
  static const success = Color(0xFF388E3C);
  static const warning = Color(0xFFFBC02D);

  static const secondary = Color(0xFFEF6C00);
  static const onSecondary = Color(0xFFFFFFFF);
}

@immutable
class AppPalette extends ThemeExtension<AppPalette> {
  const AppPalette({
    required this.primary,
    required this.primaryContainer,
    required this.onPrimary,
    required this.background,
    required this.surface,
    required this.textDark,
    required this.textLight,
    required this.error,
    required this.success,
    required this.warning,
  });

  final Color primary;
  final Color primaryContainer;
  final Color onPrimary;
  final Color background;
  final Color surface;
  final Color textDark;
  final Color textLight;
  final Color error;
  final Color success;
  final Color warning;

  static const AppPalette light = AppPalette(
    primary: AppColors.primary,
    primaryContainer: AppColors.primaryContainer,
    onPrimary: AppColors.onPrimary,
    background: AppColors.background,
    surface: AppColors.surface,
    textDark: AppColors.textDark,
    textLight: AppColors.textLight,
    error: AppColors.error,
    success: AppColors.success,
    warning: AppColors.warning,
  );

  static const AppPalette dark = AppPalette(
    primary: Color(0xFF81C784),
    primaryContainer: Color(0xFF1B5E20),
    onPrimary: Color(0xFF00210B),
    background: Color(0xFF121212),
    surface: Color(0xFF1E1E1E),
    textDark: Color(0xFFECEFF1),
    textLight: Color(0xFF9E9E9E),
    error: Color(0xFFEF5350),
    success: Color(0xFF66BB6A),
    warning: Color(0xFFFFCA28),
  );

  @override
  AppPalette copyWith({
    Color? primary,
    Color? primaryContainer,
    Color? onPrimary,
    Color? background,
    Color? surface,
    Color? textDark,
    Color? textLight,
    Color? error,
    Color? success,
    Color? warning,
  }) {
    return AppPalette(
      primary: primary ?? this.primary,
      primaryContainer: primaryContainer ?? this.primaryContainer,
      onPrimary: onPrimary ?? this.onPrimary,
      background: background ?? this.background,
      surface: surface ?? this.surface,
      textDark: textDark ?? this.textDark,
      textLight: textLight ?? this.textLight,
      error: error ?? this.error,
      success: success ?? this.success,
      warning: warning ?? this.warning,
    );
  }

  @override
  AppPalette lerp(covariant ThemeExtension<AppPalette>? other, double t) {
    if (other is! AppPalette) return this;
    return AppPalette(
      primary: Color.lerp(primary, other.primary, t)!,
      primaryContainer: Color.lerp(
        primaryContainer,
        other.primaryContainer,
        t,
      )!,
      onPrimary: Color.lerp(onPrimary, other.onPrimary, t)!,
      background: Color.lerp(background, other.background, t)!,
      surface: Color.lerp(surface, other.surface, t)!,
      textDark: Color.lerp(textDark, other.textDark, t)!,
      textLight: Color.lerp(textLight, other.textLight, t)!,
      error: Color.lerp(error, other.error, t)!,
      success: Color.lerp(success, other.success, t)!,
      warning: Color.lerp(warning, other.warning, t)!,
    );
  }
}

extension AppPaletteX on BuildContext {
  AppPalette get palette =>
      Theme.of(this).extension<AppPalette>() ?? AppPalette.light;
}
