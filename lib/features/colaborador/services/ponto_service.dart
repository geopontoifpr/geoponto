import '../models/registro_ponto_model.dart';
import '../repositories/ponto_repository.dart';
import '../repositories/frequencia_repository.dart';

class PontoService {
  final PontoRepository _repository;
  final FrequenciaRepository _frequenciaRepo;

  PontoService({
    PontoRepository? repository,
    FrequenciaRepository? frequenciaRepo,
  })  : _repository = repository ?? PontoRepository(),
        _frequenciaRepo = frequenciaRepo ?? FrequenciaRepository();

  Future<Map<String, dynamic>> obterDadosEmpresaValidados() async {
    final respostaEmpresa = await _repository.buscarDadosEmpresa();

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

  Future<List<RegistroPontoModel>> buscarRegistrosDoDia(String usuarioId) async {
    return await _repository.buscarRegistrosDoDia(usuarioId: usuarioId);
  }

  String obterProximoTipo(List<RegistroPontoModel> registros) {
    if (registros.length >= 4) {
      throw StateError('O limite de 4 registros de ponto por dia foi atingido.');
    }
    const tiposDoBanco = ['entrada_1', 'saida_1', 'entrada_2', 'saida_2'];
    return tiposDoBanco[registros.length];
  }

  String obterTextoBotao(List<RegistroPontoModel> registros) {
    if (registros.length >= 4) return 'Limite diário atingido';
    const textosDosBotoes = [
      'Registrar Entrada 1',
      'Registrar Saída para Almoço',
      'Registrar Retorno do Almoço',
      'Registrar Fim do Expediente',
    ];
    return textosDosBotoes[registros.length];
  }

  Future<RegistroPontoModel> registrarPonto({
    required String usuarioId,
    required double latitude,
    required double longitude,
  }) async {
    final authId = _repository.usuarioAutenticadoId;
    if (authId == null) throw StateError('Usuário não autenticado.');
    if (authId != usuarioId) {
      throw StateError('Não é permitido registrar ponto para outro usuário.');
    }

    // Checa se a folha do mês atual já está fechada
    final agora = DateTime.now();
    final fechamento = await _frequenciaRepo.buscarFechamentoMensal(
      usuarioId: usuarioId,
      ano: agora.year,
      mes: agora.month,
    );

    if (fechamento != null && fechamento.fechada) {
      throw StateError('A folha deste mês já está fechada. Não é possível registrar novos pontos.');
    }

    final registros = await _repository.buscarRegistrosDoDia(usuarioId: usuarioId);
    if (registros.length >= 4) {
      throw StateError('O limite de 4 registros de ponto por dia foi atingido.');
    }

    // === INÍCIO DAS VALIDAÇÕES DE INTERVALO DE TEMPO ===
    if (registros.isNotEmpty) {
      // Pega o horário da última batida de ponto de hoje
      // Se o seu model usar outro nome em vez de 'dataHora' (ex: criadoEm), altere aqui:
      final ultimoRegistro = registros.last.dataHoraPonto; 
      final diferencaTempo = agora.difference(ultimoRegistro);

      // Regra 1: Intervalo Intrajornada (Retorno do almoço)
      // Se já tem 2 registros (Entrada e Saída Almoço), o próximo é o Retorno (Entrada 2)
      if (registros.length == 2) {
        if (diferencaTempo.inMinutes < 60) {
          final minutosRestantes = 60 - diferencaTempo.inMinutes;
          throw StateError(
            'Intervalo intrajornada incompleto. '
            'Aguarde mais $minutosRestantes minuto(s) para registrar o retorno do almoço.'
          );
        }
      } 
      // Regra 2: Trava anti-spam / anti-duplicidade para as demais batidas (ex: 5 minutos)
      else {
        if (diferencaTempo.inMinutes < 5) {
          final minutosRestantes = 5 - diferencaTempo.inMinutes;
          throw StateError(
            'Muito cedo para um novo registro. '
            'Aguarde $minutosRestantes minuto(s) antes de bater o ponto novamente.'
          );
        }
      }
    }
    // === FIM DAS VALIDAÇÕES ===

    final proximoTipo = obterProximoTipo(registros);

    return await _repository.inserirRegistro(
      usuarioId: usuarioId,
      tipoRegistro: proximoTipo,
      latitude: latitude,
      longitude: longitude,
    );
  }
}