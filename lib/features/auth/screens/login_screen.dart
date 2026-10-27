import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/screens/painel_unificado_screen.dart';
import '../../../core/utils/snackbar_util.dart';
import '../../../core/widgets/custom_text_field.dart';
import '../../../core/widgets/primary_button.dart';
import '../controllers/login_controller.dart';
import 'primeiro_acesso_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  late final LoginController _controller;
  final _emailController = TextEditingController();
  final _senhaController = TextEditingController();

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
      SnackbarUtil.showError(context, 'Por favor, preencha o e-mail e a senha.');
      return;
    }

    final sucesso = await _controller.entrar(
      email: email,
      senha: senha,
    );

    if (sucesso && mounted) {
      final usuario = _controller.usuarioLogado!;

      final Widget destino = usuario.primeiroAcesso
          ? PrimeiroAcessoScreen(usuario: usuario)
          : PainelUnificadoScreen(usuario: usuario);

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => destino),
      );
    }
  }
  
  Future<void> _abrirModalRecuperacao() async {
    final emailRecuperacaoController = TextEditingController();
    
    await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Recuperar Senha'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Informe seu e-mail corporativo para receber o link de redefinição de senha.'),
            const SizedBox(height: 16),
            TextField(
              controller: emailRecuperacaoController,
              decoration: InputDecoration(
                labelText: 'E-mail',
                prefixIcon: const Icon(Icons.email_outlined),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
              keyboardType: TextInputType.emailAddress,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () async {
              final email = emailRecuperacaoController.text.trim();
              if (email.isEmpty || !email.contains('@')) {
                SnackbarUtil.showError(ctx, 'Informe um e-mail válido.');
                return;
              }
              
              // Chama o método que criamos no LoginController
              final sucesso = await _controller.recuperarSenha(email);
              
              if (!ctx.mounted) return;
              
              if (sucesso) {
                Navigator.pop(ctx);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('E-mail de recuperação enviado com sucesso!'),
                    backgroundColor: Colors.green,
                  ),
                );
              } else {
                SnackbarUtil.showError(ctx, _controller.erro ?? 'Erro ao enviar e-mail');
              }
            },
            child: const Text('Enviar Link'),
          ),
        ],
      ),
    );
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
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Align(
                  alignment: Alignment.center,
                  child: Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      color: Colors.white,
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
                      color: Color(0xFFF05B5B),
                    ),
                  ),
                ),
                const SizedBox(height: 24),
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
                CustomTextField(
                  controller: _emailController,
                  labelText: 'E-mail corporativo',
                  prefixIcon: Icons.email_outlined,
                ),
                const SizedBox(height: 24),
                CustomTextField(
                  controller: _senhaController,
                  labelText: 'Senha',
                  prefixIcon: Icons.lock_outline,
                  obscureText: true,
                ),
                const SizedBox(height: 24),

                // Botão "Esqueci minha senha" alinhado à direita
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(
                    onPressed: _abrirModalRecuperacao,
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      minimumSize: Size.zero,
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                    child: const Text(
                      'Esqueci minha senha',
                      style: TextStyle(fontWeight: FontWeight.w600),
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                
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