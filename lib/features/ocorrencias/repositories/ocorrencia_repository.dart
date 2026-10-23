import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/errors/app_exception.dart';
import '../../../core/services/supabase_service.dart';
import '../models/ocorrencia_model.dart';

class OcorrenciaRepository {
  final SupabaseClient _client;

  OcorrenciaRepository({SupabaseClient? client})
      : _client = client ?? SupabaseService.instance.client;

  String _fmtData(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  Future<List<OcorrenciaModel>> listarPorMes({
    required String usuarioId,
    required int ano,
    required int mes,
  }) async {
    try {
      final inicioMes = DateTime(ano, mes, 1);
      final fimMes = DateTime(ano, mes + 1, 0);

      final response = await _client
          .from('ocorrencias')
          .select()
          .eq('usuario_id', usuarioId)
          .gte('data_inicio', _fmtData(inicioMes))
          .lte('data_inicio', _fmtData(fimMes))
          .order('data_inicio', ascending: true);

      return (response as List)
          .map((item) => OcorrenciaModel.fromMap(item as Map<String, dynamic>))
          .toList();
    } on PostgrestException catch (e) {
      throw ServidorException('Erro ao listar ocorrências: ${e.message}');
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
    try {
      final response = await _client
          .from('ocorrencias')
          .select('*, usuarios!usuario_id(nome)')
          .eq('gestor_id', gestorId)
          .order('data_inicio', ascending: false);

      return (response as List)
          .map((item) => OcorrenciaModel.fromMap(item as Map<String, dynamic>))
          .toList();
    } on PostgrestException catch (_) {
      // Fallback caso a foreign key usuarios!usuario_id tenha outro nome no banco
      final response = await _client
          .from('ocorrencias')
          .select()
          .eq('gestor_id', gestorId)
          .order('data_inicio', ascending: false);

      return (response as List)
          .map((item) => OcorrenciaModel.fromMap(item as Map<String, dynamic>))
          .toList();
    }
  }

  Future<String> obterGestorResponsavelId(String usuarioId) async {
    try {
      final userResp = await _client
          .from('usuarios')
          .select('setor_id')
          .eq('id', usuarioId)
          .maybeSingle();

      if (userResp != null && userResp['setor_id'] != null) {
        final setorResp = await _client
            .from('setores')
            .select('gestor_id')
            .eq('id', userResp['setor_id'])
            .maybeSingle();

        if (setorResp != null && setorResp['gestor_id'] != null) {
          return setorResp['gestor_id'].toString();
        }
      }

      final gestorResp = await _client
          .from('usuarios')
          .select('id')
          .inFilter('tipo_usuario', ['GESTOR', 'ADMINISTRADOR'])
          .limit(1)
          .maybeSingle();

      if (gestorResp != null && gestorResp['id'] != null) {
        return gestorResp['id'].toString();
      }
    } catch (_) {}
    return usuarioId;
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
    required TipoOcorrenciaEnum tipoOcorrencia,
    required String justificativa,
    required String? horarioProposto,
  }) async {
    try {
      await _client.from('ocorrencias').update({
        'tipo_ocorrencia': tipoOcorrencia.valorBanco,
        'justificativa': justificativa,
        'horario_proposto': horarioProposto,
      }).eq('id', id);
    } on PostgrestException catch (e) {
      throw ServidorException('Erro ao atualizar ocorrência: ${e.message}');
    }
  }

  Future<void> deletarOcorrencia(String id) async {
    try {
      await _client.from('ocorrencias').delete().eq('id', id);
    } on PostgrestException catch (e) {
      throw ServidorException('Erro ao excluir ocorrência: ${e.message}');
    }
  }

  Future<void> avaliarOcorrencia({
    required String id,
    required bool aprovada,
    required int minutosAbonados,
    String? observacaoGestor,
  }) async {
    try {
      await _client.from('ocorrencias').update({
        'aprovada': aprovada,
        'minutos_abonados': minutosAbonados,
        'observacao_gestor': observacaoGestor,
      }).eq('id', id);
    } on PostgrestException catch (e) {
      throw ServidorException('Erro ao avaliar ocorrência: ${e.message}');
    }
  }
}