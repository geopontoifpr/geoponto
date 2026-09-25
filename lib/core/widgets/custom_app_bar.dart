import 'package:flutter/material.dart';
import '../services/supabase_service.dart';
import '../themes/theme_controller.dart';
import 'user_header.dart';
import '../../features/auth/screens/login_screen.dart';

class CustomAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String nomeUsuario;
  final VoidCallback? onPerfilPressed;

  const CustomAppBar({
    super.key,
    required this.nomeUsuario,
    this.onPerfilPressed,
  });

  @override
  Size get preferredSize => const Size.fromHeight(60.0);

  void _confirmarLogout(BuildContext context) {
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
              await SupabaseService.instance.auth.signOut();
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
      title: UserHeader(nome: nomeUsuario),
      actions: [
        // Botão Alternar Tema (Claro / Escuro)
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
        // Botão Perfil
        IconButton(
          tooltip: 'Meu Perfil',
          icon: const Icon(Icons.person_outline),
          onPressed: onPerfilPressed ?? () {},
        ),
        // Botão Logout
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