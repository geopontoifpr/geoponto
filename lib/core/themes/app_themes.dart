import 'package:flutter/material.dart';
import '../constants/app_colors.dart';

class AppThemes {
  static const Color primaryColor = AppColors.primary;
  static const Color errorColor = AppColors.error;
  static const Color warningColor = AppColors.warning;
  static const Color infoColor = AppColors.info;

  // Tema Claro
  static final ThemeData lightTheme = ThemeData(
    brightness: Brightness.light,
    primaryColor: AppColors.primary,
    scaffoldBackgroundColor: AppColors.backgroundLight,
    cardColor: AppColors.cardLight,
    dividerColor: AppColors.borderLight,
    shadowColor: Colors.black.withOpacity(0.05),
    appBarTheme: const AppBarTheme(
      backgroundColor: AppColors.cardLight,
      foregroundColor: AppColors.textPrimaryLight,
      elevation: 0.5,
    ),
    colorScheme: const ColorScheme.light(
      primary: AppColors.primary,
      surface: AppColors.cardLight,
      onSurface: AppColors.textPrimaryLight,
      onSurfaceVariant: AppColors.textSecondaryLight,
      outline: AppColors.borderLight,
      surfaceContainerHighest: AppColors.surfaceVariantLight,
      error: AppColors.error,
    ),
    useMaterial3: true,
  );

  // Tema Escuro
  static final ThemeData darkTheme = ThemeData(
    brightness: Brightness.dark,
    primaryColor: AppColors.primary,
    scaffoldBackgroundColor: AppColors.backgroundDark,
    cardColor: AppColors.cardDark,
    dividerColor: AppColors.borderDark,
    shadowColor: Colors.black.withOpacity(0.3),
    appBarTheme: const AppBarTheme(
      backgroundColor: AppColors.cardDark,
      foregroundColor: AppColors.textPrimaryDark,
      elevation: 0.5,
    ),
    colorScheme: const ColorScheme.dark(
      primary: AppColors.primary,
      surface: AppColors.cardDark,
      onSurface: AppColors.textPrimaryDark,
      onSurfaceVariant: AppColors.textSecondaryDark,
      outline: AppColors.borderDark,
      surfaceContainerHighest: AppColors.surfaceVariantDark,
      error: AppColors.error,
    ),
    useMaterial3: true,
  );

  // Helpers semânticos para evitar lógica de tema dentro das Screens
  static BoxShadow cardShadow(BuildContext context) {
    return BoxShadow(
      color: Theme.of(context).shadowColor,
      blurRadius: 10,
      offset: const Offset(0, 4),
    );
  }

  static ({Color bg, Color border, Color text}) coresStatusCalendario(
    BuildContext context, {
    required String status, // 'verde', 'laranja', 'vermelho', 'neutro'
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    switch (status) {
      case 'verde':
        return (
          bg: isDark ? const Color(0xFF14532D).withOpacity(0.7) : const Color(0xFFE8F5E9),
          border: isDark ? const Color(0xFF22C55E) : const Color(0xFF81C784),
          text: isDark ? const Color(0xFF86EFAC) : const Color(0xFF2E7D32),
        );
      case 'laranja':
        return (
          bg: isDark ? const Color(0xFF7C2D12).withOpacity(0.7) : const Color(0xFFFFF3E0),
          border: isDark ? const Color(0xFFF97316) : const Color(0xFFFFB74D),
          text: isDark ? const Color(0xFFFDBA74) : const Color(0xFFE65100),
        );
      case 'vermelho':
        return (
          bg: isDark ? const Color(0xFF7F1D1D).withOpacity(0.7) : const Color(0xFFFFEBEE),
          border: isDark ? const Color(0xFFEF4444) : const Color(0xFFE57373),
          text: isDark ? const Color(0xFFFCA5A5) : const Color(0xFFC62828),
        );
      default:
        return (
          bg: Theme.of(context).colorScheme.surfaceContainerHighest,
          border: Colors.transparent,
          text: Theme.of(context).colorScheme.onSurfaceVariant,
        );
    }
  }
}