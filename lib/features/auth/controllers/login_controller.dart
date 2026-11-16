import 'package:flutter/foundation.dart';
import '../../../core/utils/executor_async.dart';
import '../../usuarios/models/usuario_model.dart';
import '../services/auth_service.dart';

class LoginController extends ChangeNotifier with ExecutorAsync {
  final AuthService _authService;

  LoginController({AuthService? authService})
      : _authService = authService ?? AuthService();

  UsuarioModel? _usuarioLogado;
  UsuarioModel? get usuarioLogado => _usuarioLogado;

  /// Mantém o nome usado pelas telas (`_controller.erro`).
  String? get erro => erroMensagem;

  Future<bool> entrar({required String email, required String senha}) =>
      executar(() async {
        _usuarioLogado = await _authService.autenticar(email: email, senha: senha);
      });

  Future<bool> configurarPrimeiroAcesso(
    String novaSenha,
    String confirmarSenha,
    String usuarioId,
  ) =>
      executar(() => _authService.salvarPrimeiroAcesso(
            novaSenha,
            confirmarSenha,
            usuarioId,
          ));

  Future<bool> recuperarSenha(String email) =>
      executar(() => _authService.recuperarSenha(email));

  Future<void> sair() => _authService.logout();
}