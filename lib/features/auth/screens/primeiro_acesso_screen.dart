import 'package:flutter/material.dart';
import '../../../core/widgets/custom_text_field.dart';
import '../../../core/utils/snackbar_util.dart';
import '../../usuarios/models/usuario_model.dart';
import '../controllers/login_controller.dart'; // <-- IMPORT CORRETO DO CONTROLLER
import '../../gestor/screens/painel_gestor_screen.dart';
import '../../admin/screens/painel_empresa_screen.dart';
import '../../colaborador/screens/painel_colaborador_screen.dart';
import 'login_screen.dart'; 
import '../services/auth_service.dart';

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
  
  // <-- INSTANCIANDO O CONTROLLER CORRETO AQUI
  final _loginController = LoginController();

  @override
  void dispose() {
    _senhaController.dispose();
    _confirmarSenhaController.dispose();
    _loginController.dispose(); // Não esqueça de dar dispose no controller
    super.dispose();
  }

  Future<void> _salvarNovaSenha() async {
    if (!_formKey.currentState!.validate()) return;

    // Chama o método que acabamos de arrumar no controller!
    final sucesso = await _loginController.configurarPrimeiroAcesso(
      _senhaController.text,
      _confirmarSenhaController.text,
      widget.usuario.id,
    );

    if (!mounted) return;
    if (sucesso) {
      // Cria uma cópia do usuário com o primeiroAcesso alterado para false
      final usuarioAtualizado = widget.usuario.copyWith(primeiroAcesso: false);
      
      Widget destino;
      switch (widget.usuario.tipoUsuario) {
        case TipoUsuario.administrador:
          destino = PainelEmpresaScreen(usuario: widget.usuario);
          break;
        case TipoUsuario.gestor:
          destino = PainelGestorScreen(usuario: widget.usuario);
          break;
        case TipoUsuario.funcionario:
          destino = PainelColaboradorScreen(usuario: widget.usuario);
          break;
      }

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => destino),
      );
      
    }else {
      // Usa o erro capturado pelo controller
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
        automaticallyImplyLeading: false, // Impede de voltar para a tela de login sem salvar
        actions: [
          // Botão de Sair que adicionamos
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Sair',
            onPressed: () async {
              // 1. Limpa a sessão no Supabase
              await AuthService().logout(); 
              
              if (!context.mounted) return;
              
              // 2. Manda de volta para o Login
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (context) => const LoginScreen()),
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
                  style: TextStyle(color: theme.disabledColor),
                ),
                const SizedBox(height: 32),

                // NOVA SENHA
                CustomTextField(
                  controller: _senhaController,
                  labelText: 'Nova Senha',
                  prefixIcon: Icons.lock_outline,
                  obscureText: true,
                  // Mantemos apenas a validação básica de UI aqui, a regra pesada está no Service
                  validator: (value) => value == null || value.isEmpty ? 'Informe a senha' : null,
                ),
                const SizedBox(height: 16),

                // CONFIRMAR SENHA
                CustomTextField(
                  controller: _confirmarSenhaController,
                  labelText: 'Confirmar Nova Senha',
                  prefixIcon: Icons.lock_reset,
                  obscureText: true,
                  validator: (value) => value == null || value.isEmpty ? 'Confirme a senha' : null,
                ),
                const SizedBox(height: 32),

                // <-- BOTÃO ENVOLVIDO NO LISTENABLE BUILDER
                ListenableBuilder(
                  listenable: _loginController,
                  builder: (context, _) {
                    return SizedBox(
                      height: 50,
                      child: ElevatedButton(
                        // Usa a variável "carregando" do controller
                        onPressed: _loginController.carregando ? null : _salvarNovaSenha,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: theme.primaryColor,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        child: _loginController.carregando 
                            ? const SizedBox(
                                height: 24, 
                                width: 24, 
                                child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)
                              )
                            : const Text('Salvar e Continuar', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                      ),
                    );
                  }
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}