import 'package:flutter/material.dart';
import '../services/supabase_service.dart';
import '../themes/theme_controller.dart';
import 'user_header.dart';
import '../../features/auth/screens/login_screen.dart';
import '../../features/usuarios/models/usuario_model.dart'; 
import '../../features/auth/controllers/login_controller.dart';
import '../../features/usuarios/screens/perfil_usuario_screen.dart';

class CustomAppBar extends StatelessWidget implements PreferredSizeWidget {
  final UsuarioModel usuario; // Recebe o objeto completo
  final VoidCallback? onPerfilPressed;
  final void Function(String)? onNomeAlterado; // 1. Novo callback opcional

  const CustomAppBar({
    super.key,
    required this.usuario,
    this.onPerfilPressed,
    this.onNomeAlterado, // 2. Inicializa o callback
  });

  // Altura aumentada para acomodar o Card com Avatar
  @override
  Size get preferredSize => const Size.fromHeight(110.0);

  void _confirmarLogout(BuildContext context) {
    final loginController = LoginController();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Encerrar Sessão'),
        content: const Text('Deseja realmente sair da aplicação?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(ctx);
              await loginController.sair();
              if (context.mounted) {
                Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(builder: (_) => const LoginScreen()),
                  (route) => false,
                );
              }
            },
            child: const Text('Sair'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final themeController = ThemeController.instance;

    return AppBar(
      automaticallyImplyLeading: false,
      toolbarHeight: 110.0, // Reflete a nova altura
      title: UserHeader(
        nome: usuario.nome,
        tipoUsuario: usuario.tipoUsuario,
        setorNome: usuario.setorNome,
      ),
      actions: [
        ListenableBuilder(
          listenable: themeController,
          builder: (context, _) {
            return IconButton(
              tooltip: themeController.isDarkMode ? 'Tema Claro' : 'Tema Escuro',
              icon: Icon(
                themeController.isDarkMode
                    ? Icons.light_mode_outlined
                    : Icons.dark_mode_outlined,
              ),
              onPressed: () => themeController.alternarTema(),
            );
          },
        ),
          IconButton(
            icon: const Icon(Icons.person),
            onPressed: () async {
              // Aguarda a tela de perfil abrir e ser fechada
              await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => PerfilUsuarioScreen(usuario: usuario),
                ),
              );

              // Ao retornar para cá (seja pela seta ou gesto do celular), 
              // a variável 'usuario.nome' já foi atualizada na memória pelo Controller.
              // Basta acionar o callback incondicionalmente para a tela principal dar setState.
              if (onPerfilPressed != null) {
                onPerfilPressed!();
              }
            },
          ),
          IconButton(
            tooltip: 'Sair',
            icon: const Icon(Icons.logout),
            onPressed: () => _confirmarLogout(context),
          ),
        const SizedBox(width: 8),
      ],
    );
  }
}