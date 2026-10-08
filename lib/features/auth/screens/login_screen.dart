import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../controllers/login_controller.dart';
import '../../usuarios/models/usuario_model.dart';
import '../../admin/screens/painel_empresa_screen.dart';
import '../../../core/widgets/custom_text_field.dart';
import '../../../core/widgets/primary_button.dart';
import '../../../core/themes/theme_controller.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  late final LoginController _controller;
  final _emailController = TextEditingController();
  final _senhaController = TextEditingController();
  
  bool _ocultarSenha = true;

  @override
  void initState() {
    super.initState();
    _controller = LoginController();
    _controller.addListener(_aoAtualizarEstado);
  }

  void _aoAtualizarEstado() {
    if (mounted) setState(() {});
  }

  Future<void> _submeter() async {
    final email = _emailController.text.trim();
    final senha = _senhaController.text;

    if (email.isEmpty || senha.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Por favor, preencha o e-mail e a senha.'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    final sucesso = await _controller.entrar(
      email: email,
      senha: senha,
    );

    if (sucesso && mounted) {
      final usuario = _controller.usuarioLogado;

      Widget destino;
      switch (usuario?.tipoUsuario) {
        case TipoUsuario.administrador:
          destino = PainelEmpresaScreen(usuario: usuario!);
          break;
        case TipoUsuario.gestor:
        case TipoUsuario.funcionario:
        default:
          destino = PainelEmpresaScreen(usuario: usuario!);
          break;
      }

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => destino),
      );
    }
  }

  @override
  void dispose() {
    _controller.removeListener(_aoAtualizarEstado);
    _controller.dispose();
    _emailController.dispose();
    _senhaController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          ListenableBuilder(
            listenable: ThemeController.instance,
            builder: (context, _) {
              return IconButton(
                tooltip: ThemeController.instance.isDarkMode ? 'Tema Claro' : 'Tema Escuro',
                icon: Icon(
                  ThemeController.instance.isDarkMode
                      ? Icons.light_mode_outlined
                      : Icons.dark_mode_outlined,
                  color: Theme.of(context).colorScheme.onSurface, // Adapta a cor do ícone
                ),
                onPressed: () {
                  ThemeController.instance.alternarTema();
                },
              );
            },
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // A Logo
                Align(
                  alignment: Alignment.center,
                  child: Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      color: Theme.of(context).cardColor,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.05),
                          blurRadius: 15,
                          offset: const Offset(0, 5),
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.location_on, 
                      size: 45, 
                      color: AppColors.logoRed,
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                
                // Títulos
                Text(
                  'GeoPonto',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.w900,
                    color: Theme.of(context).colorScheme.onSurface,
                    letterSpacing: -0.5,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Controle de jornada e ponto eletrônico',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 16,
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                ),
                const SizedBox(height: 48),
                
                // Input de E-mail
                CustomTextField(
                  controller: _emailController,
                  labelText: 'E-mail',
                  prefixIcon: Icons.email_outlined,
                ),
                const SizedBox(height: 24),
                
                // Input de Senha com ocultação
                CustomTextField(
                  controller: _senhaController,
                  labelText: 'Senha',
                  prefixIcon: Icons.lock_outline,
                  obscureText: _ocultarSenha,
                  suffixIcon: IconButton(
                    icon: Icon(
                      _ocultarSenha ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                      color: Theme.of(context).primaryColor,
                    ),
                    onPressed: () {
                      setState(() {
                        _ocultarSenha = !_ocultarSenha;
                      });
                    },
                  ),
                ),
                const SizedBox(height: 32),
                
                if (_controller.erro != null) ...[
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.error.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: AppColors.error.withOpacity(0.5)),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.error_outline, color: AppColors.error),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            _controller.erro!,
                            style: const TextStyle(color: AppColors.error),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                ],
                
                PrimaryButton(
                  onPressed: _controller.carregando ? null : _submeter,
                  isLoading: _controller.carregando,
                  text: 'Acessar Sistema',
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}