import 'package:flutter/material.dart';
import '../../../core/screens/painel_unificado_screen.dart';
import '../../../core/utils/snackbar_util.dart';
import '../../../core/widgets/custom_text_field.dart';
import '../../../core/widgets/primary_button.dart';
import '../../usuarios/models/usuario_model.dart';
import '../controllers/login_controller.dart';
import 'login_screen.dart';

class PrimeiroAcessoScreen extends StatefulWidget {
  final UsuarioModel usuario;

  const PrimeiroAcessoScreen({super.key, required this.usuario});

  @override
  State<PrimeiroAcessoScreen> createState() => _PrimeiroAcessoScreenState();
}

class _PrimeiroAcessoScreenState extends State<PrimeiroAcessoScreen> {
  final _formKey = GlobalKey<FormState>();
  final _senhaController = TextEditingController();
  final _confirmarSenhaController = TextEditingController();
  final _loginController = LoginController();

  @override
  void dispose() {
    _senhaController.dispose();
    _confirmarSenhaController.dispose();
    _loginController.dispose();
    super.dispose();
  }

  Future<void> _salvarNovaSenha() async {
    if (!_formKey.currentState!.validate()) return;

    final sucesso = await _loginController.configurarPrimeiroAcesso(
      _senhaController.text,
      _confirmarSenhaController.text,
      widget.usuario.id,
    );

    if (!mounted) return;

    if (sucesso) {
      final usuarioAtualizado = widget.usuario.copyWith(primeiroAcesso: false);

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => PainelUnificadoScreen(usuario: usuarioAtualizado),
        ),
      );
    } else {
      SnackbarUtil.showError(
        context,
        _loginController.erro ?? 'Erro inesperado.',
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Bem-vindo ao GEOPONTO'),
        automaticallyImplyLeading: false,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Sair',
            onPressed: () async {
              await _loginController.sair();
              if (!context.mounted) return;
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (_) => const LoginScreen()),
              );
            },
          ),
        ],
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Icon(Icons.security, size: 80, color: theme.primaryColor),
                const SizedBox(height: 24),
                const Text(
                  'Segurança em primeiro lugar',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Text(
                  'Este é o seu primeiro acesso. Por favor, cadastre uma nova senha pessoal e intransferível.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: theme.colorScheme.onSurfaceVariant),
                ),
                const SizedBox(height: 32),
                CustomTextField(
                  controller: _senhaController,
                  labelText: 'Nova Senha',
                  prefixIcon: Icons.lock_outline,
                  obscureText: true,
                  validator: (value) =>
                      value == null || value.isEmpty ? 'Informe a senha' : null,
                ),
                const SizedBox(height: 16),
                CustomTextField(
                  controller: _confirmarSenhaController,
                  labelText: 'Confirmar Nova Senha',
                  prefixIcon: Icons.lock_reset,
                  obscureText: true,
                  validator: (value) =>
                      value == null || value.isEmpty ? 'Confirme a senha' : null,
                ),
                const SizedBox(height: 32),
                ListenableBuilder(
                  listenable: _loginController,
                  builder: (context, _) {
                    return PrimaryButton(
                      onPressed: _loginController.carregando ? null : _salvarNovaSenha,
                      isLoading: _loginController.carregando,
                      text: 'Salvar e Continuar',
                    );
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}