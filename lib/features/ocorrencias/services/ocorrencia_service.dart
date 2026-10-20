import '../../../core/errors/app_exception.dart';
import '../models/ocorrencia_model.dart';
import '../repositories/ocorrencia_repository.dart';

class OcorrenciaService {
  final OcorrenciaRepository _repository;

  OcorrenciaService({OcorrenciaRepository? repository})
      : _repository = repository ?? OcorrenciaRepository();

  static const Map<String, String> tiposOcorrencia = {
    'esquecimento': 'Esquecimento de marcação',
    'atraso': 'Atraso',
    'falta': 'Falta justificada',
    'saida_antecipada': 'Saída antecipada',
    'erro_registro': 'Erro no registro',
    'abono': 'Pedido de abono / Atestado',
  };

  Future<List<OcorrenciaModel>> listarPorMes({
    required String usuarioId,
    required int ano,
    required int mes,
  }) async {
    return await _repository.listarPorMes(
      usuarioId: usuarioId,
      ano: ano,
      mes: mes,
    );
  }

  Future<void> registrarOcorrencia({
    required String usuarioId,
    required DateTime dataReferencia,
    required String? tipoOcorrencia,
    required String assunto,
    required String observacoes,
  }) async {
    if (tipoOcorrencia == null || tipoOcorrencia.trim().isEmpty) {
      throw const ValidacaoException('Selecione o tipo de ocorrência.');
    }

    final assuntoLimpo = assunto.trim();
    final obsLimpa = observacoes.trim();

    if (assuntoLimpo.isEmpty && obsLimpa.isEmpty) {
      throw const ValidacaoException('Informe o assunto ou descreva a ocorrência.');
    }

    final gestorId = await _repository.obterGestorResponsavelId(usuarioId);
    final justificativaCompleta =
        assuntoLimpo.isNotEmpty ? '[$assuntoLimpo] $obsLimpa' : obsLimpa;

    final novaOcorrencia = OcorrenciaModel(
      usuarioId: usuarioId,
      gestorId: gestorId,
      dataInicio: dataReferencia,
      dataFim: dataReferencia,
      tipoOcorrencia: tipoOcorrencia,
      justificativa: justificativaCompleta,
      aprovada: false,
    );

    await _repository.inserirOcorrencia(novaOcorrencia);
  }
}