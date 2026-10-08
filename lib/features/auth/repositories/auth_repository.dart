import 'package:supabase_flutter/supabase_flutter.dart';
import '../../usuarios/models/usuario_model.dart';
import '../../../core/errors/app_exception.dart';

class AuthRepository {
  final _client = Supabase.instance.client;

  // Parâmetros posicionais (String email, String senha)
  Future<UsuarioModel?> buscarPorCredenciais(String email, String senha) async {
    try {
      // 1. Gera o Token JWT nativo do Supabase
      final AuthResponse res = await _client.auth.signInWithPassword(
        email: email,
        password: senha,
      );

      final user = res.user;
      if (user == null) {
        throw AuthExceptionApp('Erro ao autenticar usuário.'); // Sem 'const'
      }

      // 2. Busca o perfil na tabela pública (O RLS agora permite pois temos o Token!)
      final dadosUsuario = await _client
          .from('usuarios')
          .select()
          .eq('id', user.id)
          .single();

      return UsuarioModel.fromMap(dadosUsuario);
      
    } on AuthException catch (_) {
      // Captura o erro nativo de senha incorreta do Supabase
      return null; 
    } on PostgrestException catch (e) {
      throw ServidorException('Erro no banco de dados: ${e.message}');
    } catch (e) {
      throw ServidorException('Falha inesperada no login.');
    }
  }

  Future<void> deslogar() async {
    await _client.auth.signOut();
  }
}