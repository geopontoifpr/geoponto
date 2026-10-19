import 'package:flutter/material.dart';

class CustomTextField extends StatelessWidget {
  final TextEditingController controller;
  final String labelText;
  final IconData prefixIcon;
  final bool obscureText;
  
  // Novos parâmetros adicionados para suportar formulários!
  final bool enabled;
  final String? Function(String?)? validator;

  const CustomTextField({
    super.key,
    required this.controller,
    required this.labelText,
    required this.prefixIcon,
    this.obscureText = false,
    this.enabled = true,
    this.validator,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return TextFormField( // Trocado de TextField para TextFormField
      controller: controller,
      obscureText: obscureText,
      enabled: enabled,
      validator: validator,
      decoration: InputDecoration(
        labelText: labelText,
        prefixIcon: Icon(prefixIcon, color: enabled ? theme.primaryColor : theme.disabledColor),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        filled: true,
        // Fica cinza/transparente se estiver desabilitado (ex: email na edição)
        fillColor: enabled 
            ? theme.cardColor 
            : (isDark ? Colors.white10 : Colors.grey.shade200), 
      ),
    );
  }
}