import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/services/supabase_service.dart';
import '../models/registro_ponto_model.dart';
import '../../gestor/models/fechamento_mensal_model.dart';

class FrequenciaRepository {
  final SupabaseClient _client;

  /// Caso a tabela registros_ponto use outro nome para a data efetiva da batida
  /// (ex: 'data_hora_ponto' ou 'data_hora'), altere apenas esta constante:
  static const String colunaDataPonto = 'criado_em';

  FrequenciaRepository({SupabaseClient? client})
      : _client = client ?? SupabaseService.instance.client;

  Future<List<RegistroPontoModel>> listarPontosPorMes({
    required String usuarioId,
    required int ano,
    required int mes,
  }) async {
    final inicioUtc = DateTime(ano, mes, 1).toUtc().toIso8601String();
    final proximoMesUtc = DateTime(ano, mes + 1, 1).toUtc().toIso8601String();

    final response = await _client
        .from('registros_ponto')
        .select()
        .eq('usuario_id', usuarioId)
        .gte(colunaDataPonto, inicioUtc)
        .lt(colunaDataPonto, proximoMesUtc)
        .order(colunaDataPonto, ascending: true);

    return (response as List)
        .map((item) => RegistroPontoModel.fromMap(Map<String, dynamic>.from(item)))
        .toList();
  }

  Future<DateTime> obterDataCadastroUsuario(String usuarioId) async {
    try {
      final response = await _client
          .from('usuarios')
          .select('criado_em')
          .eq('id', usuarioId)
          .maybeSingle();

      if (response != null && response['criado_em'] != null) {
        return DateTime.parse(response['criado_em'].toString()).toLocal();
      }
    } catch (_) {}
    final agora = DateTime.now();
    return DateTime(agora.year, agora.month, 1);
  }

  Future<int> obterCargaHorariaSemanal(String usuarioId) async {
    try {
      final vinculo = await _client
          .from('jornadas_usuarios')
          .select('jornada_id')
          .eq('usuario_id', usuarioId)
          .order('criado_em', ascending: false)
          .limit(1)
          .maybeSingle();

      if (vinculo != null && vinculo['jornada_id'] != null) {
        final jornada = await _client
            .from('jornadas_trabalho')
            .select('carga_horaria_sem')
            .eq('id', vinculo['jornada_id'])
            .maybeSingle();

        if (jornada != null && jornada['carga_horaria_sem'] != null) {
          return (jornada['carga_horaria_sem'] as num).toInt();
        }
      }
    } catch (_) {}
    return 40;
  }

  Future<List<Map<String, dynamic>>> listarJornadasPorMes({
    required String usuarioId,
    required int ano,
    required int mes,
  }) async {
    try {
      final inicioMes = DateTime(ano, mes, 1);
      final fimMes = DateTime(ano, mes + 1, 0);

      final inicio =
          '${inicioMes.year}-${inicioMes.month.toString().padLeft(2, '0')}-01';
      final fim =
          '${fimMes.year}-${fimMes.month.toString().padLeft(2, '0')}-${fimMes.day.toString().padLeft(2, '0')}';

      final response = await _client
          .from('jornadas_usuarios')
          .select(
            'jornada_id, data_inicio_vigencia, data_fim_vigencia, '
            'jornadas_trabalho(carga_horaria_sem)',
          )
          .eq('usuario_id', usuarioId)
          .lte('data_inicio_vigencia', fim)
          .or('data_fim_vigencia.is.null,data_fim_vigencia.gte.$inicio')
          .order('data_inicio_vigencia', ascending: true);

      return (response as List)
          .map((item) => Map<String, dynamic>.from(item))
          .toList();
    } catch (_) {
      return [];
    }
  }

  Future<FechamentoMensalModel?> buscarFechamentoMensal({
    required String usuarioId,
    required int ano,
    required int mes,
  }) async {
    final mesRefStr = "$ano-${mes.toString().padLeft(2, '0')}-01";
    final response = await _client
        .from('fechamentos_mensais')
        .select()
        .eq('usuario_id', usuarioId)
        .eq('mes_referencia', mesRefStr)
        .maybeSingle();

    if (response != null) {
      return FechamentoMensalModel.fromMap(Map<String, dynamic>.from(response));
    }
    return null;
  }

  /// Usa INSERT simples para respeitar a constraint UNIQUE (usuario_id, mes_referencia)
  Future<void> inserirFechamentoMensal(FechamentoMensalModel fechamento) async {
    await _client.from('fechamentos_mensais').insert(fechamento.toMap());
  }
}