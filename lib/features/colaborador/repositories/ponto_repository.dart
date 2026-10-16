import '../../../core/services/supabase_service.dart';
import '../models/registro_ponto_model.dart';

class PontoRepository {
  final SupabaseService _supabaseService;

  PontoRepository({SupabaseService? supabaseService})
      : _supabaseService = supabaseService ?? SupabaseService.instance;

  Future<Map<String, dynamic>> buscarDadosEmpresa() async {
    // Vai direto na tabela empresas e pega a primeira/única linha que existe
    final respostaEmpresa = await _supabaseService.client
        .from('empresas')
        .select('nome, latitude_ponto, longitude_ponto, raio_permitido_m')
        .limit(1)
        .single();

    final latitude = (respostaEmpresa['latitude_ponto'] as num?)?.toDouble();
    final longitude = (respostaEmpresa['longitude_ponto'] as num?)?.toDouble();
    final raio = (respostaEmpresa['raio_permitido_m'] as num?)?.toDouble();

    if (latitude == null || longitude == null || raio == null || raio <= 0) {
      throw StateError('A empresa não possui coordenadas ou raio válido configurado.');
    }

    return {
      'nome_empresa': respostaEmpresa['nome']?.toString() ?? 'Empresa',
      'latitude_empresa': latitude,
      'longitude_empresa': longitude,
      'raio_permitido_m': raio,
    };
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

  String obterProximoTipo(List<RegistroPontoModel> registros) {
    if (registros.length >= 4) {
      throw StateError('O limite de 4 registros de ponto por dia foi atingido.');
    }
    
    // Aqui você coloca os valores EXATOS como estão cadastrados no ENUM do banco Postgres
    // Pode ser ['entry1', 'exit1', 'entry2', 'exit2'] se for assim que está no seu banco.
    const tiposDoBanco = [
      'entrada_1', 
      'saida_1',   
      'entrada_2', 
      'saida_2'    
    ];
    
    return tiposDoBanco[registros.length];
  }

  Future<RegistroPontoModel> registrarPonto({
    required String usuarioId,
    required String tipoRegistro,
    required double latitude,
    required double longitude,
  }) async {
    final usuario = _supabaseService.usuarioAtual;
    if (usuario == null) throw StateError('Usuário não autenticado.');
    if (usuario.id != usuarioId) {
      throw StateError('Não é permitido registrar ponto para outro usuário.');
    }

    final registros = await buscarRegistrosDoDia(usuarioId: usuarioId);
    if (registros.length >= 4) {
      throw StateError('O limite de 4 registros de ponto por dia foi atingido.');
    }
    if (tipoRegistro != obterProximoTipo(registros)) {
      throw StateError('Tipo de registro inválido. Atualize os registros e tente novamente.');
    }

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
