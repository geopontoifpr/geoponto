import '../../../core/services/supabase_service.dart';
import '../models/jornada_trabalho_model.dart';
import '../models/jornada_usuario_model.dart';

class JornadaRepository {
  final _supabase = SupabaseService.instance.client;

  /// Busca todas as jornadas de trabalho disponíveis na tabela 'jornadas_trabalho'
  Future<List<JornadaTrabalhoModel>> listarJornadas() async {
    final response = await _supabase
        .from('jornadas_trabalho')
        .select()
        .order('carga_horaria_sem'); // Ordena da menor para a maior carga horária
        
    return response.map((e) => JornadaTrabalhoModel.fromMap(e)).toList();
  }

  /// Busca a jornada ATUAL do usuário (aquela que não tem data de fim, ou seja, ainda está vigente)
  Future<JornadaUsuarioModel?> buscarJornadaUsuario(String usuarioId) async {
    final response = await _supabase
        .from('jornadas_usuarios')
        .select()
        .eq('usuario_id', usuarioId)
        .isFilter('data_fim_vigencia', null) // Garante que busca apenas a jornada ativa
        .order('criado_em', ascending: false)
        .limit(1)
        .maybeSingle();
        
    if (response == null) return null;
    return JornadaUsuarioModel.fromMap(response);
  }

  /// Salva uma nova jornada para o usuário. 
  /// Se ele já tiver uma ativa diferente, encerra a atual antes de criar a nova.
  Future<void> salvarJornadaUsuario({
    required String usuarioId, 
    required String jornadaId,
    required DateTime dataInicioVigencia,
  }) async {
    // 1. Busca a jornada ativa atual
    final jornadaAtiva = await buscarJornadaUsuario(usuarioId);

    // Se já existe uma jornada ativa...
    if (jornadaAtiva != null) {
      // Se for exatamente a mesma jornada, não faz nada (evita duplicação)
      if (jornadaAtiva.jornadaId == jornadaId) return;

      // Se for uma jornada diferente, "encerra" a antiga colocando a data de fim como ontem ou hoje
      await _supabase.from('jornadas_usuarios').update({
        'data_fim_vigencia': DateTime.now().toIso8601String().split('T')[0],
        'atualizado_em': DateTime.now().toIso8601String(),
      }).eq('id', jornadaAtiva.id);
    }

    // 2. Insere o novo vínculo de jornada
    await _supabase.from('jornadas_usuarios').insert({
      'usuario_id': usuarioId,
      'jornada_id': jornadaId,
      'data_inicio_vigencia': dataInicioVigencia.toIso8601String().split('T')[0],
    });
  }

/// Busca o histórico de jornadas que tiveram vigência durante o mês.
Future<List<JornadaUsuarioModel>> listarHistoricoJornadasPorMes({
    required String usuarioId,
    required DateTime inicioMes,
    required DateTime fimMes,
  }) async {
    final inicio = inicioMes.toIso8601String().split('T')[0];
    final fim = fimMes.toIso8601String().split('T')[0];

    final response = await _supabase
        .from('jornadas_usuarios')
        .select()
        .eq('usuario_id', usuarioId)
        .lte('data_inicio_vigencia', fim)
        .or('data_fim_vigencia.is.null,data_fim_vigencia.gte.$inicio')
        .order('data_inicio_vigencia', ascending: true);

    return (response as List)
        .map(
          (item) => JornadaUsuarioModel.fromMap(
            Map<String, dynamic>.from(item),
          ),
        )
        .toList();
  }

}