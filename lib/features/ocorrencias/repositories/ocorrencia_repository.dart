import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/services/supabase_service.dart';
import '../models/ocorrencia_model.dart';

class OcorrenciaRepository {
  final SupabaseClient _client;

  OcorrenciaRepository({SupabaseClient? client})
      : _client = client ?? SupabaseService.instance.client;

  /// Busca todas as ocorrências do usuário dentro do mês selecionado
  Future<List<OcorrenciaModel>> listarPorMes({
    required String usuarioId,
    required int ano,
    required int mes,
  }) async {
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
  }

  /// Descobre automaticamente o gestor_id responsável pelo colaborador
  Future<String> obterGestorResponsavelId(String usuarioId) async {
    try {
      // 1. Tenta achar o setor do usuário e pegar o gestor daquele setor
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

      // 2. Fallback: busca qualquer usuário com perfil de gestor ou admin
      final gestorResp = await _client
          .from('usuarios')
          .select('id')
          .inFilter('perfil', ['gestor', 'admin'])
          .limit(1)
          .maybeSingle();

      if (gestorResp != null && gestorResp['id'] != null) {
        return gestorResp['id'].toString();
      }
    } catch (_) {
      // Se falhar por RLS ou ausência de tabela, usa o próprio ID como fallback seguro
    }
    return usuarioId;
  }

  /// Registra uma nova ocorrência no banco
  Future<void> registrarOcorrencia({
    required String usuarioId,
    required DateTime dataReferencia,
    required String tipoOcorrencia,
    required String assunto,
    required String observacoes,
  }) async {
    final gestorId = await obterGestorResponsavelId(usuarioId);
    final justificativaCompleta =
        assunto.trim().isNotEmpty ? '[$assunto] $observacoes' : observacoes;

    final novaOcorrencia = OcorrenciaModel(
      usuarioId: usuarioId,
      gestorId: gestorId,
      dataInicio: dataReferencia,
      dataFim: dataReferencia,
      tipoOcorrencia: tipoOcorrencia,
      justificativa: justificativaCompleta,
      aprovada: false,
    );

    await _client.from('ocorrencias').insert(novaOcorrencia.toInsertMap());
  }
}