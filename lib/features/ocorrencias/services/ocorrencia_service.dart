import '../../../core/errors/app_exception.dart';
import '../models/ocorrencia_model.dart';
import '../repositories/ocorrencia_repository.dart';

class OcorrenciaService {
  final OcorrenciaRepository _repository;

  OcorrenciaService({OcorrenciaRepository? repository})
      : _repository = repository ?? OcorrenciaRepository();

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

  Future<List<OcorrenciaModel>> listarPorGestor(String gestorId) async {
    return await _repository.listarPorGestor(gestorId);
  }

  void _validarPrazo72Horas(DateTime dataReferencia) {
    final agora = DateTime.now();
    final hojeFimDoDia = DateTime(agora.year, agora.month, agora.day, 23, 59, 59);

    if (dataReferencia.isAfter(hojeFimDoDia)) {
      throw const ValidacaoException(
        'Não é permitido registrar ocorrências em datas futuras.',
      );
    }

    // Verifica se já passaram mais de 72 horas desde o fim do dia da ocorrência
    final fimDoDiaReferencia = DateTime(
      dataReferencia.year,
      dataReferencia.month,
      dataReferencia.day,
      23,
      59,
      59,
    );

    if (agora.difference(fimDoDiaReferencia).inHours > 72) {
      throw const ValidacaoException(
        'O prazo de 72 horas para registrar ou alterar ocorrências desta data já expirou.',
      );
    }
  }

  Future<void> salvarOcorrencia({
    String? idEdicao,
    required String usuarioId,
    required DateTime dataReferencia,
    required TipoOcorrenciaEnum? tipoOcorrencia,
    required String justificativa,
    required int minutosSolicitados,
  }) async {
    if (tipoOcorrencia == null) {
      throw const ValidacaoException('Selecione o tipo de ocorrência.');
    }

    final justificativaLimpa = justificativa.trim();
    if (justificativaLimpa.isEmpty) {
      throw const ValidacaoException('Descreva a justificativa da ocorrência.');
    }

    if (minutosSolicitados <= 0 || minutosSolicitados > 720) {
      throw const ValidacaoException(
        'Informe uma quantidade válida de minutos para abono (entre 1 e 720 min).',
      );
    }

    _validarPrazo72Horas(dataReferencia);

    final horarioTime = OcorrenciaModel.formatarMinutosParaTime(minutosSolicitados);

    if (idEdicao != null && idEdicao.isNotEmpty) {
      // Edição da ocorrência já criada no dia
      await _repository.atualizarOcorrencia(
        id: idEdicao,
        tipoOcorrencia: tipoOcorrencia,
        justificativa: justificativaLimpa,
        horarioProposto: horarioTime,
      );
    } else {
      // Regra: Funcionário não pode criar 2 ocorrências no mesmo dia
      final existente = await _repository.buscarPorDia(
        usuarioId: usuarioId,
        data: dataReferencia,
      );
      if (existente != null) {
        throw const ValidacaoException(
          'Já existe uma ocorrência registrada neste dia. Edite ou exclua a ocorrência existente.',
        );
      }

      final gestorId = await _repository.obterGestorResponsavelId(usuarioId);
      final novaOcorrencia = OcorrenciaModel(
        usuarioId: usuarioId,
        gestorId: gestorId,
        dataInicio: dataReferencia,
        dataFim: dataReferencia,
        tipoOcorrencia: tipoOcorrencia,
        justificativa: justificativaLimpa,
        horarioProposto: horarioTime,
        aprovada: false,
      );

      await _repository.inserirOcorrencia(novaOcorrencia);
    }
  }

  Future<void> excluirOcorrencia(OcorrenciaModel ocorrencia) async {
    if (ocorrencia.id == null) return;
    if (ocorrencia.foiAvaliada) {
      throw const ValidacaoException(
        'Não é possível excluir uma ocorrência que já foi avaliada pelo gestor.',
      );
    }
    await _repository.deletarOcorrencia(ocorrencia.id!);
  }

  Future<void> avaliarOcorrencia({
    required OcorrenciaModel ocorrencia,
    required bool aprovar,
    String? observacaoGestor,
  }) async {
    if (ocorrencia.id == null) {
      throw const ValidacaoException('Ocorrência inválida.');
    }

    // Se aprovar, popula minutos_abonados com os minutos propostos em horario_proposto.
    // Se recusar, grava 0 em minutos_abonados para marcar como avaliada/recusada.
    final minutosParaAbonar = aprovar ? ocorrencia.minutosPropostos : 0;

    await _repository.avaliarOcorrencia(
      id: ocorrencia.id!,
      aprovada: aprovar,
      minutosAbonados: minutosParaAbonar,
      observacaoGestor: observacaoGestor?.trim().isEmpty == true
          ? null
          : observacaoGestor?.trim(),
    );
  }
}