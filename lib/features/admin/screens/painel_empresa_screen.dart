import 'package:flutter/material.dart';
import '../../auth/screens/login_screen.dart';
import '../../usuarios/models/usuario_model.dart';
import '../../../core/widgets/custom_app_bar.dart';

class PainelEmpresaScreen extends StatelessWidget {
  final UsuarioModel usuario;

  const PainelEmpresaScreen({super.key, required this.usuario});
      @override
        Widget build(BuildContext context) {
          return Scaffold(
            appBar: CustomAppBar(
              nomeUsuario: usuario.nome,
              onPerfilPressed: () {
                // Abrirá tela de perfil na Etapa 2
              },
            ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Card(
            elevation: 2,
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.check_circle_outline,
                    size: 64,
                    color: Colors.green,
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Bem-vindo ao GeoPonto!',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text('Nome: ${usuario.nome}'),
                  const SizedBox(height: 8),
                  Text('E-mail: ${usuario.email}'),
                  const SizedBox(height: 8),
                  Text('Perfil: ${usuario.tipoUsuario.toDbValue()}'),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}