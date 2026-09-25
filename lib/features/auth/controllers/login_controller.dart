import 'package:flutter/foundation.dart';
import '../../usuarios/models/usuario_model.dart';
import '../services/auth_service.dart';

class LoginController extends ChangeNotifier {
  final AuthService _authService;

  LoginController({AuthService? authService})
      : _authService = authService ?? AuthService();

  bool _carregando = false;
  String? _erro;
  UsuarioModel? _usuarioLogado;

  bool get carregando => _carregando;
  String? get erro => _erro;
  UsuarioModel? get usuarioLogado => _usuarioLogado;

  Future<bool> entrar({
    required String email,
    required String senha,
  }) async {
    _carregando = true;
    _erro = null;
    notifyListeners();

    try {
      _usuarioLogado = await _authService.autenticar(
        email: email,
        senha: senha,
      );
      _carregando = false;
      notifyListeners();
      return true;
    } catch (e) {
      _erro = e.toString().replaceAll('Exception: ', '');
      _carregando = false;
      notifyListeners();
      return false; // Retorno explícito obrigatório
    }
  }
}