import '../../../core/services/supabase_service.dart';
import '../models/registro_ponto_model.dart';

class PontoRepository {
  final SupabaseService _supabaseService;

  PontoRepository({SupabaseService? supabaseService})
      : _supabaseService = supabaseService ?? SupabaseService.instance;

  String? get usuarioAutenticadoId => _supabaseService.usuarioAtual?.id;

  Future<Map<String, dynamic>> buscarDadosEmpresa() async {
    return await _supabaseService.client
        .from('empresas')
        .select('nome, latitude_ponto, longitude_ponto, raio_permitido_m')
        .limit(1)
        .single();
  }

  Future<List<RegistroPontoModel>> buscarRegistrosDoDia({required String usuarioId}) async {
    final agora = DateTime.now();
    final inicioDia = DateTime(agora.year, agora.month, agora.day);
    final fimDia = inicioDia.add(const Duration(days: 1));

    final resposta = await _supabaseService.client
        .from('registros_ponto')
        .select()
        .eq('usuario_id', usuarioId)
        .gte('criado_em', inicioDia.toUtc().toIso8601String())
        .lt('criado_em', fimDia.toUtc().toIso8601String())
        .order('criado_em', ascending: true);

    return (resposta as List)
        .map((registro) => RegistroPontoModel.fromMap(
              Map<String, dynamic>.from(registro as Map),
            ))
        .toList();
  }

  Future<RegistroPontoModel> inserirRegistro({
    required String usuarioId,
    required String tipoRegistro,
    required double latitude,
    required double longitude,
  }) async {
    final resposta = await _supabaseService.client
        .from('registros_ponto')
        .insert({
          'usuario_id': usuarioId,
          'tipo_registro_ponto': tipoRegistro,
          'latitude_disp': latitude,
          'longitude_disp': longitude,
        })
        .select()
        .single();

    return RegistroPontoModel.fromMap(Map<String, dynamic>.from(resposta as Map));
  }
}