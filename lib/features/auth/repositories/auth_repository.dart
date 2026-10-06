import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/services/supabase_service.dart';
import '../../usuarios/models/usuario_model.dart';

class AuthRepository {
  final SupabaseClient _client;

  AuthRepository({SupabaseClient? client})
      : _client = client ?? SupabaseService.instance.client;

  User? get usuarioAuthAtual => _client.auth.currentUser;

  Future<AuthResponse> loginComEmailSenha({
    required String email,
    required String senha,
  }) async {
    return await _client.auth.signInWithPassword(
      email: email,
      password: senha,
    );
  }

  Future<void> deslogar() async {
    await _client.auth.signOut();
  }

//   Future<UsuarioModel?> buscarDadosPerfil(String email) async {
//     final response = await _client
//         .from('usuarios')
//         .select()
//         .eq('email', email)
//         .maybeSingle();

//     if (response == null) return null;
//     return UsuarioModel.fromMap(response);
//   }

  // Busca o usuário usando email e senha diretamente na tabela usuarios
  // Invoca a RPC segura mantendo as políticas de RLS ativas
  Future<UsuarioModel?> buscarPorCredenciais({
    required String email,
    required String senha,
  }) async {
    try {
      final List<dynamic> response = await _client.rpc(
        'autenticar_usuario',
        params: {
          'p_email': email.trim(),
          'p_senha': senha,
        },
      );

      if (response.isEmpty) {
        return null;
      }

      final Map<String, dynamic> dados = response.first as Map<String, dynamic>;
      return UsuarioModel.fromMap(dados);
    } catch (e) {
      rethrow;
    }
  }
}
