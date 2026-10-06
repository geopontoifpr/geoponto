import 'package:supabase_flutter/supabase_flutter.dart';
import '../repositories/auth_repository.dart';
import '../../usuarios/models/usuario_model.dart';
import '../../../core/errors/app_exception.dart';

class AuthService {
  final AuthRepository _repository;

  AuthService({AuthRepository? repository})
      : _repository = repository ?? AuthRepository();

  Future<UsuarioModel> autenticar({
    required String email,
    required String senha,
  }) async {
    final emailTratado = email.trim();

    if (emailTratado.isEmpty || senha.isEmpty) {
      throw const CamposObrigatoriosException();
    }

    // Consulta na tabela usuarios
    final usuario = await _repository.buscarPorCredenciais(
      email: emailTratado,
      senha: senha,
    );

    if (usuario == null) {
      throw const AuthExceptionApp('E-mail ou senha inválidos. Verifique suas credenciais.');
    }

    if (!usuario.ativo) {
      throw const UsuarioInativoException('Usuário inativo. Entre em contato com a administração.');
    }

    return usuario;
  }

  Future<void> logout() async {
    await _repository.deslogar();
  }
}