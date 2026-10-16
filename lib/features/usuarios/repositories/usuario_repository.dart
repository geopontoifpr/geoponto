import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/errors/app_exception.dart';
import '../models/usuario_model.dart';


class UsuarioRepository {
  final _client = Supabase.instance.client;

  Future<List<UsuarioModel>> listarUsuarios({
    required String empresaId,
    String? setorId, // Opcional: Se vier preenchido, filtra pelo setor
    String? ignorarUsuarioId, // Opcional: Se vier preenchido, remove este ID da lista (o próprio gestor)
  }) async {
    try {
      // Começa a montar a query base (trazendo todos da empresa e o nome do setor)
      var query = _client
          .from('usuarios')
          .select('*, setores!setor_id(nome)')
          .eq('empresa_id', empresaId);

      // Se passou um setor_id (Gestor), adiciona o filtro na query
      if (setorId != null && setorId.isNotEmpty) {
        query = query.eq('setor_id', setorId);
      }

      // Se passou um ID para ignorar, remove da lista
      if (ignorarUsuarioId != null && ignorarUsuarioId.isNotEmpty) {
        query = query.neq('id', ignorarUsuarioId);
      }

      // Executa a query final
      final response = await query;
      
      return (response as List).map((e) => UsuarioModel.fromMap(e)).toList();
    } catch (e) {
      throw ServidorException('Erro ao buscar a equipe: $e');
    }
  }

  Future<void> atualizarUsuario(String id, Map<String, dynamic> dados) async {
    try {
      // O banco dispara o Gatilho automaticamente nesse update!
      await _client.from('usuarios').update(dados).eq('id', id);
      
    } on PostgrestException catch (e) {
      // Se o Gatilho bloquear a edição/reativação:
      if (e.message.contains('GESTOR_DUPLICADO')) {
        throw ValidacaoException('O setor selecionado já possui um Gestor vinculado. Altere o gestor atual primeiro.');
      }
      
      // Tratamento de e-mail duplicado
      if (e.code == '23505') {
        final msgBanco = e.message.toLowerCase();
        if (msgBanco.contains('email')) {
          throw ValidacaoException('Este e-mail já está cadastrado no sistema.');
        } else {
          throw ValidacaoException('Este dado já existe no sistema.');
        }
      }
      
      throw ServidorException('Erro ao atualizar dados: ${e.message}');
    } catch (e) {
      throw ServidorException('Falha inesperada ao atualizar usuário.');
    }
  }
    
  Future<void> criarUsuario(Map<String, dynamic> dados) async {
    try {
      final response = await _client.rpc('criar_membro_equipe', params: {
        'p_email': dados['email'],
        'p_nome': dados['nome'],
        'p_tipo': dados['tipo_usuario'],
        'p_empresa_id': dados['empresa_id'],
        'p_setor_id': dados['setor_id'],
      });

      // Se o banco negou a criação (ex: E-mail duplicado)
      if (response != null && response['success'] == false) {
        // Lança a ValidacaoException para o texto aparecer amarelinho/vermelho na tela
        throw ValidacaoException(response['error']); 
      }
      
    } on PostgrestException catch (e) {
      throw ServidorException('Erro de permissão no banco: ${e.message}');
    } catch (e) {
      if (e is AppException) rethrow; // Deixa a nossa ValidacaoException passar reto!
      throw const ServidorException('Falha inesperada ao tentar salvar usuario.');
    }
  }

  Future<bool> verificarSeSetorTemGestor(String setorId, {String? ignorarId}) async {
    try {
      // SUA LÓGICA: Olha diretamente pra quem é o dono na tabela de setores
      final response = await _client
          .from('setores')
          .select('gestor_id')
          .eq('id', setorId)
          .single();
      
      final gestorIdNoBanco = response['gestor_id'];
      
      // Se tiver alguém ocupando a vaga, e NÃO for a pessoa que estamos editando
      if (gestorIdNoBanco != null && gestorIdNoBanco != ignorarId) {
        return true; 
      }
      
      return false; // Vaga livre
    } on PostgrestException catch (e) {
      // Se der erro porque ainda não existe, assumimos livre
      if (e.code == 'PGRST116') return false; 
      throw ServidorException('Erro ao verificar gestor: ${e.message}');
    }
  }
  
  // 1. Remove este usuário do cargo de gestor de qualquer setor que ele possua
  Future<void> removerGestorDosSetores(String usuarioId) async {
    try {
      await _client.from('setores').update({'gestor_id': null}).eq('gestor_id', usuarioId);
    } catch (e) {
      throw ServidorException('Erro ao remover vínculo antigo do gestor.');
    }
  }

  // 2. Define este usuário como o dono de um setor específico
  Future<void> vincularGestorAoSetor(String setorId, String usuarioId) async {
    try {
      await _client.from('setores').update({'gestor_id': usuarioId}).eq('id', setorId);
    } catch (e) {
      throw ServidorException('Erro ao vincular gestor ao setor.');
    }
  }
 Future<String?> obterIdPorEmail(String email) async {
    try {
      final Map<String, dynamic>? response = await _client
          .from('usuarios')
          .select('id')
          .eq('email', email)
          .maybeSingle();
          
      if (response == null) return null;
      return response['id'] as String?;
    } catch (e) {
      return null;
    }
  }
  
}