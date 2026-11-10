import 'package:flutter/material.dart';
import '../../../core/widgets/custom_app_bar.dart';
import '../../usuarios/models/usuario_model.dart';

class PainelGestorScreen extends StatelessWidget {
  final UsuarioModel usuario;

  const PainelGestorScreen({super.key, required this.usuario});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      appBar: CustomAppBar(
        usuario: widget.usuario,
      ),      
    );
  }
}