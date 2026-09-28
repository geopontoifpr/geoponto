import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../controllers/login_controller.dart';
import '../../usuarios/models/usuario_model.dart';
import '../../admin/screens/painel_empresa_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  late final LoginController _controller;
  final _formKey = GlobalKey<FormState>();
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
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final sucesso = await _controller.entrar(
      email: _emailController.text.trim(),
      senha: _senhaController.text,
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

  String? _validarEmail(String? value) {
    if (value == null || value.isEmpty) {
      return 'Por favor, insira o e-mail.';
    }
    final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
    if (!emailRegex.hasMatch(value)) {
      return 'Insira um e-mail válido.';
    }
    return null;
  }

  // Widget auxiliar para criar os labels acima dos campos
  Widget _buildLabel(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8, left: 4),
      child: Text(
        text,
        style: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.bold,
          color: AppColors.textLabel,
          letterSpacing: 1.2,
        ),
      ),
    );
  }

  // Decoração padrão para os inputs focando no fundo branco e bordas arredondadas
  InputDecoration _buildInputDecoration({required String hintText}) {
    return InputDecoration(
      hintText: hintText,
      hintStyle: TextStyle(color: AppColors.textSecondary.withOpacity(0.5)),
      filled: true,
      fillColor: AppColors.inputBackground,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColors.inputBorder),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColors.inputBorder),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColors.error),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      // Removida a AppBar para ocupar a tela toda como no protótipo
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.stretch, // Estica os elementos para ocupar a largura
                children: [
                  // Placeholder para a Logo
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
                        // quando for colocar uma imagem da logo, mudar essa parte de cima por:
                        /*
                        child: Image.asset(
                          'assets/images/logo.png',
                          fit: BoxFit.contain,
                        ),
                        */ ///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
                      ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  
                  // Títulos
                  const Text(
                    'GeoPonto',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.w900,
                      color: AppColors.textPrimary,
                      letterSpacing: -0.5,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Controle de jornada e ponto eletrônico',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 16,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 48),
                  
                  // Campo E-mail
                  _buildLabel('E-MAIL CORPORATIVO'),
                  TextFormField(
                    controller: _emailController,
                    keyboardType: TextInputType.emailAddress,
                    validator: _validarEmail,
                    decoration: _buildInputDecoration(hintText: 'colaborador@empresa.com'),
                  ),
                  const SizedBox(height: 24),
                  
                  // Campo Senha
                  _buildLabel('SENHA'),
                  TextFormField(
                    controller: _senhaController,
                    obscureText: _ocultarSenha,
                    enableSuggestions: false,
                    autocorrect: false,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Por favor, insira a senha.';
                      }
                      return null;
                    },
                    decoration: _buildInputDecoration(hintText: '••••••••').copyWith(
                      suffixIcon: IconButton(
                        icon: Icon(
                          _ocultarSenha ? Icons.visibility_off : Icons.visibility,
                          color: AppColors.textSecondary,
                        ),
                        onPressed: () {
                          setState(() {
                            _ocultarSenha = !_ocultarSenha;
                          });
                        },
                      ),
                    ),
                  ),
                  const SizedBox(height: 32),
                  
                  // Exibição de Erro
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
                  
                  // Botão Acessar Sistema
                  SizedBox(
                    height: 56, // Altura maior para ficar parecido com o protótipo
                    child: ElevatedButton(
                      onPressed: _controller.carregando ? null : _submeter,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: AppColors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16), // Bordas bem arredondadas
                        ),
                      ),
                      child: _controller.carregando
                          ? const SizedBox(
                              width: 24,
                              height: 24,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: AppColors.white,
                              ),
                            )
                          : const Text(
                              'Acessar Sistema', // Texto exato do protótipo
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}