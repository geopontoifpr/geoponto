import 'package:flutter/material.dart';


// Popup de erro na parte inferior da tela, com fundo vermelho e texto branco
// para reaproveitamento em toda a aplicação.
class SnackbarUtil {
  static void showError(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
     SnackBar(
        content: Text(
          message,
          style: const TextStyle(color: Colors.white), // <-- Força o texto a ficar branco
        ),
        backgroundColor: Theme.of(context).colorScheme.error,
        behavior: SnackBarBehavior.floating, // Fica mais elegante
      )
    );
  }
}