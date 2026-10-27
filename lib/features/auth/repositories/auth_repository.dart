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
          .select('*, setores!setor_id(nome)')
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
  // Atualiza a senha no cofre do Supabase (Auth)
  Future<void> atualizarSenha(String novaSenha) async {
    try {
      await _client.auth.updateUser(UserAttributes(password: novaSenha));
    } catch (e) {
      throw ServidorException('Erro ao atualizar a senha no provedor de autenticação.');
    }
  }

  // Remove a flag de primeiro acesso na tabela pública
  Future<void> removerFlagPrimeiroAcesso(String usuarioId) async {
    try {
      await _client.from('usuarios').update({'primeiro_acesso': false}).eq('id', usuarioId);
    } catch (e) {
      throw ServidorException('Erro ao atualizar o status de primeiro acesso.');
    }
  }
  // Vincula o dispositivo ao usuário na tabela pública
  Future<void> vincularDispositivo(String usuarioId, String dispositivoId) async {
    try {
      await _client
          .from('usuarios')
          .update({'dispositivo_usuario': dispositivoId})
          .eq('id', usuarioId);
    } catch (e) {
      throw ServidorException('Erro ao vincular o dispositivo ao usuário.');
    }
  }
}
