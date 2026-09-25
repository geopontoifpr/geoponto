import 'package:flutter/material.dart';
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
    final sucesso = await _controller.entrar(
      email: _emailController.text,
      senha: _senhaController.text,
    );

    if (sucesso && mounted) {
      final usuario = _controller.usuarioLogado;

      // Redirecionamento por perfil conforme regras do GeoPonto
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
        title: const Text('GeoPonto'),
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text(
                'Iniciar sessão',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 30),
              TextField(
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
                decoration: const InputDecoration(
                  labelText: 'E-mail',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
             TextField(
                  controller: _senhaController,
                  obscureText: _ocultarSenha,
                  enableSuggestions: false,
                  autocorrect: false,
                  decoration: InputDecoration(
                    labelText: 'Senha',
                    border: const OutlineInputBorder(),
                    suffixIcon: IconButton(
                      icon: Icon(
                        _ocultarSenha ? Icons.visibility_off : Icons.visibility,
                      ),
                      onPressed: () {
                        setState(() {
                          _ocultarSenha = !_ocultarSenha;
                        });
                      },
                    ),
                  ),
                ),
              const SizedBox(height: 20),
              if (_controller.erro != null) ...[
                Text(
                  _controller.erro!,
                  style: const TextStyle(color: Colors.red),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 20),
              ],
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  onPressed: _controller.carregando ? null : _submeter,
                  child: _controller.carregando
                      ? const SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text('Entrar'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
