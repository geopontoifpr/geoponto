import 'package:flutter/foundation.dart';
import '../../usuarios/models/usuario_model.dart';
import '../services/auth_service.dart';
import '../../../core/errors/app_exception.dart';

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
      return false; 
    }
  }

  // --- MÉTODO CORRIGIDO ---
  Future<bool> configurarPrimeiroAcesso(String novaSenha, String confirmarSenha, String usuarioId) async {
    _carregando = true;
    _erro = null;
    notifyListeners(); // Avisa a tela que começou a carregar
    
    try {
      // Chama o Service
      await _authService.salvarPrimeiroAcesso(novaSenha, confirmarSenha, usuarioId);
      
      _carregando = false;
      notifyListeners(); // Avisa a tela que parou de carregar
      return true;
    } on AppException catch (e) {
      _erro = e.mensagem;
      _carregando = false;
      notifyListeners();
      return false;
    } catch (e) {
      _erro = e.toString().replaceAll('Exception: ', '');
      _carregando = false;
      notifyListeners();
      return false;
    }
  }
}