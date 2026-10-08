import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/errors/app_exception.dart';
import '../../usuarios/models/usuario_model.dart';

class EquipeRepository {
  final _client = Supabase.instance.client;

  Future<List<UsuarioModel>> listarEquipe(String empresaId) async {
    try {
      final response = await _client
          .from('usuarios')
          .select('*, setores(nome)') // Pega o nome do setor junto!
          .eq('empresa_id', empresaId)
          .order('nome', ascending: true);
          
      return (response as List).map((e) => UsuarioModel.fromMap(e)).toList();
    } on PostgrestException catch (e) {
      throw ServidorException('Erro ao carregar equipe: ${e.message}');
    }
  }

  Future<void> criarMembro(Map<String, dynamic> dados) async {
    try {
      // Chama a Edge Function
      final res = await _client.functions.invoke(
        'criar_membro_equipe',
        body: dados,
      );
      
      if (res.status != 200) {
        throw ServidorException('Erro da função: ${res.data['error']}');
      }
    } on FunctionException catch (e) {
      throw ServidorException('Falha de conexão com o servidor de autenticação.');
    }
  }

  Future<void> atualizarMembro(String id, Map<String, dynamic> dados) async {
    try {
      await _client.from('usuarios').update(dados).eq('id', id);
    } on PostgrestException catch (e) {
      throw ServidorException('Erro ao atualizar dados: ${e.message}');
    }
  }
}