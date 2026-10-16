import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/services/supabase_service.dart';
import '../models/registro_ponto_model.dart';

class FrequenciaRepository {
  final SupabaseClient _client;

  FrequenciaRepository({SupabaseClient? client})
      : _client = client ?? SupabaseService.instance.client;

  /// Busca todas as batidas de ponto do colaborador no mês
  Future<List<RegistroPontoModel>> listarPontosPorMes({
    required String usuarioId,
    required int ano,
    required int mes,
  }) async {
    final inicioUtc = DateTime(ano, mes, 1, 0, 0, 0).toUtc().toIso8601String();
    final fimUtc = DateTime(ano, mes + 1, 0, 23, 59, 59).toUtc().toIso8601String();

    final response = await _client
        .from('registros_ponto')
        .select()
        .eq('usuario_id', usuarioId)
        .gte('criado_em', inicioUtc)
        .lte('criado_em', fimUtc)
        .order('criado_em', ascending: true);

    return (response as List)
        .map((item) => RegistroPontoModel.fromMap(item as Map<String, dynamic>))
        .toList();
  }

  /// Busca a data exata em que o usuário foi cadastrado no banco (criado_em)
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
    // Fallback caso não consiga ler: primeiro dia do mês atual
    final agora = DateTime.now();
    return DateTime(agora.year, agora.month, 1);
  }

  /// Busca a carga horária semanal na tabela jornadas_usuarios -> jornadas_trabalho
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
    return 40; // Fallback padrão: 40h semanais (8h por dia útil)
  }
}