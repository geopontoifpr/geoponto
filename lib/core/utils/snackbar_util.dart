import 'package:flutter/material.dart';
import '../constants/app_colors.dart';

class SnackbarUtil {
  static void showError(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
     SnackBar(
        content: Text(
          message,
          style: const TextStyle(color: AppColors.cardLight), 
        ),
        // Fundo 100% sólido
        backgroundColor: AppColors.error.withOpacity(1.0),
        behavior: SnackBarBehavior.floating, 
      )
    );
  }

  static void showSuccess(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: const TextStyle(color: AppColors.cardLight), 
        ),
        // Fundo 100% sólido
        backgroundColor: AppColors.success.withOpacity(1.0),
        behavior: SnackBarBehavior.floating, 
      )
    );
  }
}