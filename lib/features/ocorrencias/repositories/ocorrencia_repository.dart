import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/errors/app_exception.dart';
import '../../../core/services/supabase_service.dart';
import '../../usuarios/models/usuario_model.dart';
import '../models/ocorrencia_model.dart';

class OcorrenciaRepository {
  final SupabaseClient _client;

  OcorrenciaRepository({SupabaseClient? client})
      : _client = client ?? SupabaseService.instance.client;

  String _fmtData(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  DateTime _inicioMes(int ano, int mes) => DateTime(ano, mes, 1);

  DateTime _inicioProximoMes(int ano, int mes) => DateTime(ano, mes + 1, 1);

  Future<UsuarioModel?> obterUsuario(String usuarioId) async {
    try {
      final response = await _client
          .from('usuarios')
          .select('id, empresa_id, setor_id, nome, email, tipo_usuario, ativo, primeiro_acesso')
          .eq('id', usuarioId)
          .maybeSingle();
      if (response == null) return null;
      return UsuarioModel.fromMap(response);
    } on PostgrestException catch (e) {
      throw ServidorException('Erro ao consultar o usuário autenticado: ${e.message}');
    }
  }

  Future<List<UsuarioModel>> listarUsuariosPorTipo({
    required String tipoUsuario,
  }) async {
    try {
      final response = await _client
          .from('usuarios')
          .select('id, empresa_id, setor_id, nome, email, tipo_usuario, ativo, primeiro_acesso')
          .eq('tipo_usuario', tipoUsuario)
          .order('nome');
      return (response as List)
          .map((item) => UsuarioModel.fromMap(item as Map<String, dynamic>))
          .toList();
    } on PostgrestException catch (e) {
      throw ServidorException('Erro ao listar usuários: ${e.message}');
    }
  }

  Future<List<UsuarioModel>> listarFuncionariosPorSetor(String setorId) async {
    try {
      final response = await _client
          .from('usuarios')
          .select('id, empresa_id, setor_id, nome, email, tipo_usuario, ativo, primeiro_acesso')
          .eq('setor_id', setorId)
          .eq('tipo_usuario', 'FUNCIONARIO')
          .order('nome');
      return (response as List)
          .map((item) => UsuarioModel.fromMap(item as Map<String, dynamic>))
          .toList();
    } on PostgrestException catch (e) {
      throw ServidorException('Erro ao listar os colaboradores do setor: ${e.message}');
    }
  }

  Future<String?> obterSetorResponsavelDoGestor(String gestorId) async {
    try {
      final response = await _client
          .from('setores')
          .select('id')
          .eq('gestor_id', gestorId)
          .maybeSingle();
      return response?['id']?.toString();
    } on PostgrestException catch (e) {
      throw ServidorException('Erro ao identificar o setor do gestor: ${e.message}');
    }
  }

  Future<Set<String>> listarUsuariosComFechamentoFechado({
    required List<String> usuariosIds,
    required int ano,
    required int mes,
  }) async {
    if (usuariosIds.isEmpty) return <String>{};
    final mesReferencia =
        '${ano}-${mes.toString().padLeft(2, '0')}-01';
    try {
      final response = await _client
          .from('fechamentos_mensais')
          .select('usuario_id')
          .inFilter('usuario_id', usuariosIds)
          .eq('mes_referencia', mesReferencia)
          .eq('fechada', true);
      return (response as List)
          .map((item) => item['usuario_id'].toString())
          .toSet();
    } on PostgrestException catch (e) {
      throw ServidorException('Erro ao verificar o fechamento mensal: ${e.message}');
    }
  }

  Future<bool> mesEstaFechado({
    required String usuarioId,
    required int ano,
    required int mes,
  }) async {
    final fechados = await listarUsuariosComFechamentoFechado(
      usuariosIds: [usuarioId],
      ano: ano,
      mes: mes,
    );
    return fechados.contains(usuarioId);
  }

  Future<List<OcorrenciaModel>> listarPorMes({
    required String usuarioId,
    required int ano,
    required int mes,
  }) async {
    try {
      final response = await _client
          .from('ocorrencias')
          .select()
          .eq('usuario_id', usuarioId)
          .gte('data_inicio', _fmtData(_inicioMes(ano, mes)))
          .lt('data_inicio', _fmtData(_inicioProximoMes(ano, mes)))
          .order('data_inicio', ascending: true);

      return (response as List)
          .map((item) => OcorrenciaModel.fromMap(item as Map<String, dynamic>))
          .toList();
    } on PostgrestException catch (e) {
      throw ServidorException('Erro ao listar ocorrências: ${e.message}');
    }
  }

  Future<List<OcorrenciaModel>> listarPorUsuariosNoMes({
    required List<String> usuariosIds,
    required int ano,
    required int mes,
  }) async {
    if (usuariosIds.isEmpty) return [];
    try {
      final response = await _client
          .from('ocorrencias')
          .select()
          .inFilter('usuario_id', usuariosIds)
          .gte('data_inicio', _fmtData(_inicioMes(ano, mes)))
          .lt('data_inicio', _fmtData(_inicioProximoMes(ano, mes)))
          .order('data_inicio', ascending: false);

      return (response as List)
          .map((item) => OcorrenciaModel.fromMap(item as Map<String, dynamic>))
          .toList();
    } on PostgrestException catch (e) {
      throw ServidorException('Erro ao listar ocorrências das pessoas selecionadas: ${e.message}');
    }
  }

  Future<OcorrenciaModel?> obterPorId(String id) async {
    try {
      final response = await _client
          .from('ocorrencias')
          .select()
          .eq('id', id)
          .maybeSingle();
      if (response == null) return null;
      return OcorrenciaModel.fromMap(response);
    } on PostgrestException catch (e) {
      throw ServidorException('Erro ao consultar ocorrência: ${e.message}');
    }
  }

  Future<OcorrenciaModel?> buscarPorDia({
    required String usuarioId,
    required DateTime data,
  }) async {
    try {
      final response = await _client
          .from('ocorrencias')
          .select()
          .eq('usuario_id', usuarioId)
          .eq('data_inicio', _fmtData(data))
          .limit(1)
          .maybeSingle();

      if (response == null) return null;
      return OcorrenciaModel.fromMap(response);
    } on PostgrestException catch (e) {
      throw ServidorException('Erro ao verificar ocorrência do dia: ${e.message}');
    }
  }

  Future<List<OcorrenciaModel>> listarPorGestor(String gestorId) async {
    final agora = DateTime.now();
    try {
      final response = await _client
          .from('ocorrencias')
          .select()
          .eq('gestor_id', gestorId)
          .gte('data_inicio', _fmtData(_inicioMes(agora.year, agora.month)))
          .lt('data_inicio', _fmtData(_inicioProximoMes(agora.year, agora.month)))
          .order('data_inicio', ascending: false);

      return (response as List)
          .map((item) => OcorrenciaModel.fromMap(item as Map<String, dynamic>))
          .toList();
    } on PostgrestException catch (e) {
      throw ServidorException('Erro ao listar ocorrências da equipe: ${e.message}');
    }
  }

  Future<String> obterGestorResponsavelId(String usuarioId) async {
    try {
      final userResp = await _client
          .from('usuarios')
          .select('setor_id, tipo_usuario')
          .eq('id', usuarioId)
          .maybeSingle();

      if (userResp == null) {
        throw const ValidacaoException('Não foi possível identificar o usuário da ocorrência.');
      }

      if (userResp['tipo_usuario'] == 'GESTOR') {
        final administrador = await _client
            .from('usuarios')
            .select('id')
            .eq('tipo_usuario', 'ADMINISTRADOR')
            .limit(1)
            .maybeSingle();
        final administradorId = administrador?['id']?.toString();
        if (administradorId != null && administradorId.isNotEmpty) {
          return administradorId;
        }
        throw const ValidacaoException(
          'Não foi possível identificar o administrador responsável pelas ocorrências do gestor.',
        );
      }

      if (userResp['tipo_usuario'] == 'ADMINISTRADOR') {
        throw const ValidacaoException(
          'O administrador não possui um responsável definido para suas próprias ocorrências.',
        );
      }

      if (userResp['setor_id'] != null) {
        final setorResp = await _client
            .from('setores')
            .select('gestor_id')
            .eq('id', userResp['setor_id'])
            .maybeSingle();

        final gestorId = setorResp?['gestor_id']?.toString();
        if (gestorId != null && gestorId.isNotEmpty) return gestorId;
      }

      throw const ValidacaoException(
        'O usuário não possui um gestor responsável vinculado ao seu setor.',
      );
    } on PostgrestException catch (e) {
      throw ServidorException('Erro ao identificar o gestor responsável: ${e.message}');
    }
  }

  Future<void> avaliarOcorrencia({
    required String ocorrenciaId,
    required bool aprovar,
    required int minutosAbonados,
    String? observacao,
  }) async {
    try {
      final response = await _client
          .from('ocorrencias')
          .update({
            'aprovada': aprovar,
            'minutos_abonados': minutosAbonados,
            'observacao_gestor': observacao,
            'atualizado_em': DateTime.now().toUtc().toIso8601String(),
          })
          .eq('id', ocorrenciaId)
          .isFilter('minutos_abonados', null)
          .eq('aprovada', false)
          .select('id');

      if ((response as List).isEmpty) {
        throw const ValidacaoException(
          'A ocorrência já foi avaliada ou você não possui permissão para avaliá-la.',
        );
      }
    } on PostgrestException catch (e) {
      throw ServidorException('Não foi possível avaliar a ocorrência: ${e.message}');
    }
  }

  Future<void> reabrirOcorrencia(String ocorrenciaId) async {
    try {
      final response = await _client
          .from('ocorrencias')
          .update({
            'aprovada': false,
            'minutos_abonados': null,
            'observacao_gestor': null,
            'atualizado_em': DateTime.now().toUtc().toIso8601String(),
          })
          .eq('id', ocorrenciaId)
          .not('minutos_abonados', 'is', null)
          .select('id');
      if ((response as List).isEmpty) {
        throw const ValidacaoException(
          'A ocorrência não está concluída ou você não possui permissão para reabri-la.',
        );
      }
    } on PostgrestException catch (e) {
      throw ServidorException('Não foi possível reabrir a ocorrência: ${e.message}');
    }
  }

  Future<void> inserirOcorrencia(OcorrenciaModel ocorrencia) async {
    try {
      await _client.from('ocorrencias').insert(ocorrencia.toInsertMap());
    } on PostgrestException catch (e) {
      throw ServidorException('Erro ao criar ocorrência: ${e.message}');
    }
  }

  Future<void> atualizarOcorrencia({
    required String id,
    required DateTime dataReferencia,
    required TipoOcorrenciaEnum tipoOcorrencia,
    required String justificativa,
    required String? horarioProposto,
  }) async {
    try {
      final response = await _client
          .from('ocorrencias')
          .update({
            'data_inicio': _fmtData(dataReferencia),
            'data_fim': _fmtData(dataReferencia),
            'tipo_ocorrencia': tipoOcorrencia.valorBanco,
            'justificativa': justificativa,
            'horario_proposto': horarioProposto,
            'atualizado_em': DateTime.now().toUtc().toIso8601String(),
          })
          .eq('id', id)
          .isFilter('minutos_abonados', null)
          .eq('aprovada', false)
          .select('id');
      if ((response as List).isEmpty) {
        throw const ValidacaoException(
          'A ocorrência já foi avaliada ou não pode mais ser editada.',
        );
      }
    } on PostgrestException catch (e) {
      throw ServidorException('Erro ao atualizar ocorrência: ${e.message}');
    }
  }

  Future<void> deletarOcorrencia(String id) async {
    try {
      final response = await _client
          .from('ocorrencias')
          .delete()
          .eq('id', id)
          .isFilter('minutos_abonados', null)
          .select('id');
      if ((response as List).isEmpty) {
        throw const ValidacaoException(
          'A ocorrência já foi avaliada ou não pode mais ser excluída.',
        );
      }
    } on PostgrestException catch (e) {
      throw ServidorException('Erro ao excluir ocorrência: ${e.message}');
    }
  }

}
