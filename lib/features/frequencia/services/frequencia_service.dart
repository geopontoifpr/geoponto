import '../../../core/utils/feriados_util.dart';
import '../../ocorrencias/models/ocorrencia_model.dart';
import '../../ocorrencias/repositories/ocorrencia_repository.dart';
import '../../ponto/models/registro_ponto_model.dart';
import '../repositories/frequencia_repository.dart';
import '../models/fechamento_mensal_model.dart';

enum StatusDiaCalendario { neutro, verde, laranja, vermelho }

class FrequenciaService {
  final FrequenciaRepository _frequenciaRepo;
  final OcorrenciaRepository _ocorrenciaRepo;

  FrequenciaService({
    FrequenciaRepository? frequenciaRepo,
    OcorrenciaRepository? ocorrenciaRepo,
  })  : _frequenciaRepo = frequenciaRepo ?? FrequenciaRepository(),
        _ocorrenciaRepo = ocorrenciaRepo ?? OcorrenciaRepository();

  Future<DateTime> obterDataCadastroUsuario(String usuarioId) async {
    final data = await _frequenciaRepo.obterDataCadastroUsuario(usuarioId);
    if (data != null) return data;
    
    // Regra de negócio: se o banco falhar em informar, assumimos o início do mês atual.
    final agora = DateTime.now();
    return DateTime(agora.year, agora.month, 1);
  }

  Future<int> obterCargaHorariaSemanal(String usuarioId) async {
    // Regra de negócio: se não houver carga cadastrada, assume 40 horas semanais.
    return await _frequenciaRepo.obterCargaHorariaSemanal(usuarioId) ?? 40;
  }

  Future<List<Map<String, dynamic>>> obterJornadasPorMes({
    required String usuarioId,
    required int ano,
    required int mes,
  }) =>
      _frequenciaRepo.listarJornadasPorMes(
        usuarioId: usuarioId,
        ano: ano,
        mes: mes,
      );

  Future<FechamentoMensalModel?> buscarFechamentoMensal({
    required String usuarioId,
    required int ano,
    required int mes,
  }) =>
      _frequenciaRepo.buscarFechamentoMensal(
        usuarioId: usuarioId,
        ano: ano,
        mes: mes,
      );

  Future<void> inserirFechamentoMensal(FechamentoMensalModel fechamento) =>
      _frequenciaRepo.inserirFechamentoMensal(fechamento);

  Future<void> validarEInserirFechamento(
    FechamentoMensalModel fechamento,
    bool folhaJaFechada,
    Map<int, List<OcorrenciaModel>> ocorrenciasPorDia,
  ) async {
    final agora = DateTime.now();
    final inicioMesAtual = DateTime(agora.year, agora.month, 1);
    final inicioMesFechamento = DateTime(
      fechamento.mesReferencia.year,
      fechamento.mesReferencia.month,
      1,
    );

    if (!inicioMesFechamento.isBefore(inicioMesAtual)) {
      throw Exception(
        'Apenas meses anteriores ao mês atual podem ser fechados.',
      );
    }

    if (folhaJaFechada) {
      throw Exception('Esta folha mensal já se encontra fechada.');
    }

    // --- NOVA REGRA: Bloqueia se houver ocorrência pendente ---
    final temOcorrenciaPendente = ocorrenciasPorDia.values
        .expand((lista) => lista)
        .any((ocorrencia) => ocorrencia.isPendente);

    if (temOcorrenciaPendente) {
      throw Exception(
        'Não é possível fechar a folha: existem ocorrências pendentes de análise para este mês.',
      );
    }

    final idUsuarioLogado = _frequenciaRepo.obterIdUsuarioLogado();
    if (idUsuarioLogado == fechamento.usuarioId) {
      throw Exception('O gestor não pode fechar a própria folha.');
    }

    await _frequenciaRepo.inserirFechamentoMensal(fechamento);
  }

  Future<Map<int, List<RegistroPontoModel>>> obterPontosAgrupadosPorDia({
    required String usuarioId,
    required int ano,
    required int mes,
  }) async {
    final pontos = await _frequenciaRepo.listarPontosPorMes(
      usuarioId: usuarioId,
      ano: ano,
      mes: mes,
    );

    final mapPontos = <int, List<RegistroPontoModel>>{};
    for (final p in pontos) {
      final dataLocal = p.dataHoraPonto.toLocal();
      if (dataLocal.year == ano && dataLocal.month == mes) {
        mapPontos.putIfAbsent(dataLocal.day, () => []).add(p);
      }
    }

    for (final lista in mapPontos.values) {
      lista.sort((a, b) => a.dataHoraPonto.compareTo(b.dataHoraPonto));
    }

    return mapPontos;
  }

  Future<Map<int, List<OcorrenciaModel>>> obterOcorrenciasAgrupadasPorDia({
    required String usuarioId,
    required int ano,
    required int mes,
  }) async {
    final ocorrencias = await _ocorrenciaRepo.listarPorMes(
      usuarioId: usuarioId,
      ano: ano,
      mes: mes,
    );
    final mapOcorrencias = <int, List<OcorrenciaModel>>{};
    for (final oc in ocorrencias) {
      final dia = oc.dataInicio.toLocal().day;
      mapOcorrencias.putIfAbsent(dia, () => []).add(oc);
    }
    return mapOcorrencias;
  }

  int calcularMinutosTrabalhadosDoDia(List<RegistroPontoModel> batidasDoDia) {
    if (batidasDoDia.length < 2) return 0;

    final batidas = List<RegistroPontoModel>.from(batidasDoDia)
      ..sort((a, b) => a.dataHoraPonto.compareTo(b.dataHoraPonto));

    int totalMinutos = 0;
    for (int i = 0; i + 1 < batidas.length; i += 2) {
      final diff = batidas[i + 1].dataHoraPonto.difference(batidas[i].dataHoraPonto);
      if (!diff.isNegative) {
        totalMinutos += diff.inMinutes;
      }
    }
    return totalMinutos;
  }

  int calcularMinutosAbonadosDoDia(List<OcorrenciaModel> ocorrenciasDoDia) {
    int totalAbonado = 0;
    for (final oc in ocorrenciasDoDia) {
      if (oc.aprovada && oc.minutosAbonados != null) {
        totalAbonado += oc.minutosAbonados!;
      }
    }
    return totalAbonado;
  }

  // ───────────── Lógica de Negócios Transferida do Controller ─────────────

  int obterCargaHorariaDoDia({
    required int dia,
    required DateTime mesAtual,
    required List<Map<String, dynamic>> jornadasDoMes,
    required int cargaHorariaSemanalPadrao,
  }) {
    final dataTexto = '${mesAtual.year}-${mesAtual.month.toString().padLeft(2, '0')}-${dia.toString().padLeft(2, '0')}';

    for (final vinculo in jornadasDoMes.reversed) {
      final inicio = vinculo['data_inicio_vigencia']?.toString().split('T').first;
      final fim = vinculo['data_fim_vigencia']?.toString().split('T').first;

      if (inicio == null || inicio.compareTo(dataTexto) > 0) continue;
      if (fim != null && fim.compareTo(dataTexto) < 0) continue;

      final jornada = vinculo['jornadas_trabalho'];
      if (jornada is Map && jornada['carga_horaria_sem'] != null) {
        return (jornada['carga_horaria_sem'] as num).toInt();
      }
    }
    return cargaHorariaSemanalPadrao;
  }

  int obterMinutosPrevistosDoDia({
    required int dia,
    required DateTime mesAtual,
    required int cargaHorariaDoDia,
  }) {
    final data = DateTime(mesAtual.year, mesAtual.month, dia);
    if (FeriadosUtil.isFimDeSemanaOuFeriado(data)) return 0;
    return ((cargaHorariaDoDia * 60) / 5).round();
  }

  ({
    int minutosTrabalhados,
    int minutosAbonados,
    int minutosPrevistos,
    int saldoMinutos,
    bool isFimDeSemana,
    String? nomeFeriado,
    List<RegistroPontoModel> batidas,
  }) obterDadosDia({
    required int dia,
    required DateTime mesAtual,
    required List<RegistroPontoModel> batidas,
    required List<OcorrenciaModel> ocorrencias,
    required int minutosPrevistos,
  }) {
    final dt = DateTime(mesAtual.year, mesAtual.month, dia);
    final trabalhados = calcularMinutosTrabalhadosDoDia(batidas);
    final abonados = calcularMinutosAbonadosDoDia(ocorrencias);

    return (
      minutosTrabalhados: trabalhados,
      minutosAbonados: abonados,
      minutosPrevistos: minutosPrevistos,
      saldoMinutos: trabalhados + abonados - minutosPrevistos,
      isFimDeSemana: FeriadosUtil.isFimDeSemanaOuFeriado(dt),
      nomeFeriado: FeriadosUtil.obterFeriado(dt),
      batidas: batidas,
    );
  }

  ({
    int minutosPrevistos,
    int minutosTrabalhados,
    int minutosAbonados,
    int saldoMinutos,
    int diasTrabalhados,
    int minutosCredito,
    int minutosDebito,
  }) calcularExtratoDetalhado({
    required int totalDiasMes,
    required DateTime mesAtual,
    required Map<int, List<RegistroPontoModel>> pontosPorDia,
    required Map<int, List<OcorrenciaModel>> ocorrenciasPorDia,
    required List<Map<String, dynamic>> jornadasDoMes,
    required int cargaHorariaSemanalPadrao,
    required bool folhaFechada,
    required FechamentoMensalModel? fechamentoSalvo,
  }) {
    int previstos = 0, trabalhados = 0, abonados = 0;
    int dias = 0, credito = 0, debito = 0;

    for (int d = 1; d <= totalDiasMes; d++) {
      final cargaDia = obterCargaHorariaDoDia(
        dia: d, 
        mesAtual: mesAtual, 
        jornadasDoMes: jornadasDoMes, 
        cargaHorariaSemanalPadrao: cargaHorariaSemanalPadrao
      );
      
      final minPrevistos = obterMinutosPrevistosDoDia(
        dia: d, 
        mesAtual: mesAtual, 
        cargaHorariaDoDia: cargaDia
      );

      final info = obterDadosDia(
        dia: d,
        mesAtual: mesAtual,
        batidas: pontosPorDia[d] ?? [],
        ocorrencias: ocorrenciasPorDia[d] ?? [],
        minutosPrevistos: minPrevistos,
      );

      previstos += info.minutosPrevistos;
      trabalhados += info.minutosTrabalhados;
      abonados += info.minutosAbonados;

      if (info.minutosTrabalhados > 0 || info.batidas.isNotEmpty) dias++;

      if (info.saldoMinutos > 0) {
        credito += info.saldoMinutos;
      } else if (info.saldoMinutos < 0) {
        debito += info.saldoMinutos.abs();
      }
    }

    final f = (folhaFechada && fechamentoSalvo != null) ? fechamentoSalvo : null;

    return (
      minutosPrevistos: f?.minutosPrevistos ?? previstos,
      minutosTrabalhados: f?.minutosTrabalhados ?? trabalhados,
      minutosAbonados: f?.minutosAbonados ?? abonados,
      saldoMinutos: f?.saldoMinutos ?? (trabalhados + abonados - previstos),
      diasTrabalhados: dias,
      minutosCredito: credito,
      minutosDebito: debito,
    );
  }

  ({
    int trabHoras,
    int trabMin,
    int faltamHoras,
    int faltamMinRest,
    double progresso,
  }) calcularResumoMensal(
    ({
      int minutosPrevistos,
      int minutosTrabalhados,
      int minutosAbonados,
      int saldoMinutos,
      int diasTrabalhados,
      int minutosCredito,
      int minutosDebito,
    }) extrato,
  ) {
    final concluido = extrato.minutosTrabalhados + extrato.minutosAbonados;
    final faltam = (extrato.minutosPrevistos - concluido).clamp(0, extrato.minutosPrevistos);
    final progresso = extrato.minutosPrevistos > 0
        ? (concluido / extrato.minutosPrevistos).clamp(0.0, 1.0)
        : 0.0;

    return (
      trabHoras: extrato.minutosTrabalhados ~/ 60,
      trabMin: extrato.minutosTrabalhados % 60,
      faltamHoras: faltam ~/ 60,
      faltamMinRest: faltam % 60,
      progresso: progresso,
    );
  }

  StatusDiaCalendario avaliarStatusDia({
    required DateTime dataDia,
    required DateTime dataCadastroUsuario,
    required int minutosPrevistosDia,
    required List<RegistroPontoModel> batidas,
    required List<OcorrenciaModel> ocorrencias,
  }) {
    final hoje = DateTime.now();
    final hojeSemHora = DateTime(hoje.year, hoje.month, hoje.day);
    final cadastroSemHora = DateTime(
      dataCadastroUsuario.year,
      dataCadastroUsuario.month,
      dataCadastroUsuario.day,
    );

    final isFimDeSemana = dataDia.weekday == DateTime.saturday ||
        dataDia.weekday == DateTime.sunday;

    if (dataDia.isAfter(hojeSemHora)) return StatusDiaCalendario.neutro;
    if (dataDia.isBefore(cadastroSemHora) && batidas.isEmpty) {
      return StatusDiaCalendario.neutro;
    }
    if (isFimDeSemana && batidas.isEmpty) {
      return StatusDiaCalendario.neutro;
    }

    final trabMin = calcularMinutosTrabalhadosDoDia(batidas);
    final abonMin = calcularMinutosAbonadosDoDia(ocorrencias);

    if (batidas.isEmpty) {
      if (abonMin > 0 || ocorrencias.any((o) => o.aprovada)) {
        return StatusDiaCalendario.verde;
      }
      if (dataDia.isAtSameMomentAs(hojeSemHora)) {
        return StatusDiaCalendario.neutro;
      }
      return StatusDiaCalendario.vermelho;
    }

    if (batidas.length.isOdd) {
      return StatusDiaCalendario.laranja;
    }

    if ((trabMin + abonMin) >= (minutosPrevistosDia - 15)) {
      return StatusDiaCalendario.verde;
    }
    return StatusDiaCalendario.laranja;
  }
}