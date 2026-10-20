import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/errors/app_exception.dart';
import '../../../core/services/supabase_service.dart';
import '../models/ocorrencia_model.dart';

class OcorrenciaRepository {
  final SupabaseClient _client;

  OcorrenciaRepository({SupabaseClient? client})
      : _client = client ?? SupabaseService.instance.client;

  Future<List<OcorrenciaModel>> listarPorMes({
    required String usuarioId,
    required int ano,
    required int mes,
  }) async {
    try {
      final inicioMes = DateTime(ano, mes, 1);
      final fimMes = DateTime(ano, mes + 1, 0);

      String fmt(DateTime d) =>
          '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

      final response = await _client
          .from('ocorrencias')
          .select()
          .eq('usuario_id', usuarioId)
          .gte('data_inicio', fmt(inicioMes))
          .lte('data_inicio', fmt(fimMes))
          .order('data_inicio', ascending: true);

      return (response as List)
          .map((item) => OcorrenciaModel.fromMap(item as Map<String, dynamic>))
          .toList();
    } on PostgrestException catch (e) {
      throw ServidorException('Erro ao listar ocorrências: ${e.message}');
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
      throw ServidorException('Erro ao salvar ocorrência: ${e.message}');
    }
  }
}