import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/errors/app_exception.dart';
import '../../../core/utils/executor_async.dart';
import '../../../core/utils/feriados_util.dart';
import '../../../core/utils/formatadores.dart';
import '../models/fechamento_mensal_model.dart';
import '../../ocorrencias/models/ocorrencia_model.dart';
import '../../ponto/models/registro_ponto_model.dart';
import '../services/frequencia_service.dart';

class FrequenciaController extends ChangeNotifier with ExecutorAsync {
  final String usuarioId;
  final FrequenciaService _service;

  FrequenciaController({
    required this.usuarioId,
    FrequenciaService? service,
  }) : _service = service ?? FrequenciaService() {
    final agora = DateTime.now();
    mesAtual = DateTime(agora.year, agora.month, 1);
    carregando = true; // a tela começa em "carregando"
  }

  late DateTime mesAtual;
  DateTime? dataCadastroUsuario;
  int cargaHorariaSemanalPadrao = 40;
  bool folhaFechada = false;
  FechamentoMensalModel? fechamentoSalvo;

  List<Map<String, dynamic>> jornadasDoMes = [];
  Map<int, List<RegistroPontoModel>> pontosPorDia = {};
  Map<int, List<OcorrenciaModel>> ocorrenciasPorDia = {};

  String get nomeMesAtual => Formatadores.meses[mesAtual.month - 1];
  int get totalDiasMes => DateTime(mesAtual.year, mesAtual.month + 1, 0).day;
  int get offsetSemana => DateTime(mesAtual.year, mesAtual.month, 1).weekday % 7;

  /// Somente meses anteriores ao atual podem ser fechados.
  bool get isMesAnteriorAoAtual {
    final agora = DateTime.now();
    return mesAtual.isBefore(DateTime(agora.year, agora.month, 1));
  }

  bool get podeFecharFolha => isMesAnteriorAoAtual && !folhaFechada;

  // ───────────── Carregamento ─────────────

  Future<void> carregarDadosMes() => executar(() async {
        dataCadastroUsuario ??= await _service.obterDataCadastroUsuario(usuarioId);
        cargaHorariaSemanalPadrao =
            await _service.obterCargaHorariaSemanal(usuarioId);

        jornadasDoMes = await _service.obterJornadasPorMes(
          usuarioId: usuarioId,
          ano: mesAtual.year,
          mes: mesAtual.month,
        );
        pontosPorDia = await _service.obterPontosAgrupadosPorDia(
          usuarioId: usuarioId,
          ano: mesAtual.year,
          mes: mesAtual.month,
        );
        ocorrenciasPorDia = await _service.obterOcorrenciasAgrupadasPorDia(
          usuarioId: usuarioId,
          ano: mesAtual.year,
          mes: mesAtual.month,
        );
        fechamentoSalvo = await _service.buscarFechamentoMensal(
          usuarioId: usuarioId,
          ano: mesAtual.year,
          mes: mesAtual.month,
        );
        folhaFechada = fechamentoSalvo?.fechada ?? false;
      }, erroPadrao: 'Não foi possível carregar os dados do mês.');

  void mudarMes(int delta) {
    mesAtual = DateTime(mesAtual.year, mesAtual.month + delta, 1);
    folhaFechada = false;
    fechamentoSalvo = null;
    carregarDadosMes();
  }

  // ───────────── Cálculos ─────────────

  /// Carga horária semanal vigente na data específica do dia.
  int obterCargaHorariaDoDia(int dia) {
    final dataTexto =
        '${mesAtual.year}-${mesAtual.month.toString().padLeft(2, '0')}-${dia.toString().padLeft(2, '0')}';

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

  int obterMinutosPrevistosDoDia(int dia) {
    final data = DateTime(mesAtual.year, mesAtual.month, dia);
    if (FeriadosUtil.isFimDeSemanaOuFeriado(data)) return 0;
    return ((obterCargaHorariaDoDia(dia) * 60) / 5).round();
  }

  Duration calcularHorasDoDia(int dia) => Duration(
        minutes: _service.calcularMinutosTrabalhadosDoDia(pontosPorDia[dia] ?? []),
      );

  /// Dados consolidados de um único dia.
  ({
    int minutosTrabalhados,
    int minutosAbonados,
    int minutosPrevistos,
    int saldoMinutos,
    bool isFimDeSemana,
    String? nomeFeriado,
    List<RegistroPontoModel> batidas,
  }) obterDadosDia(int dia) {
    final dt = DateTime(mesAtual.year, mesAtual.month, dia);
    final batidas = pontosPorDia[dia] ?? [];
    final ocorrencias = ocorrenciasPorDia[dia] ?? [];

    final trabalhados = _service.calcularMinutosTrabalhadosDoDia(batidas);
    final abonados = _service.calcularMinutosAbonadosDoDia(ocorrencias);
    final previstos = obterMinutosPrevistosDoDia(dia);

    return (
      minutosTrabalhados: trabalhados,
      minutosAbonados: abonados,
      minutosPrevistos: previstos,
      saldoMinutos: trabalhados + abonados - previstos,
      isFimDeSemana: FeriadosUtil.isFimDeSemanaOuFeriado(dt),
      nomeFeriado: FeriadosUtil.obterFeriado(dt),
      batidas: batidas,
    );
  }

  /// Cálculo mensal unificado em minutos.
  ({
    int minutosPrevistos,
    int minutosTrabalhados,
    int minutosAbonados,
    int saldoMinutos,
    int diasTrabalhados,
    int minutosCredito,
    int minutosDebito,
  }) calcularExtratoDetalhado() {
    int previstos = 0, trabalhados = 0, abonados = 0;
    int dias = 0, credito = 0, debito = 0;

    for (int d = 1; d <= totalDiasMes; d++) {
      final info = obterDadosDia(d);

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

    // Folha fechada: preserva os totais oficiais gravados no banco.
    final f = (folhaFechada && fechamentoSalvo != null) ? fechamentoSalvo! : null;

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

  /// Compatível com a HistoricoMensalScreen.
  ({
    int trabHoras,
    int trabMin,
    int faltamHoras,
    int faltamMinRest,
    double progresso,
  }) calcularResumoMensal() {
    final extrato = calcularExtratoDetalhado();
    final concluido = extrato.minutosTrabalhados + extrato.minutosAbonados;
    final faltam =
        (extrato.minutosPrevistos - concluido).clamp(0, extrato.minutosPrevistos);
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

  // ───────────── Fechamento ─────────────

  /// Não liga `carregando` (para a tela não virar spinner); só preenche o erro.
  Future<bool> fecharFolhaMes() => executar(() async {
        final extrato = calcularExtratoDetalhado();
        final novo = FechamentoMensalModel(
          usuarioId: usuarioId,
          mesReferencia: DateTime(mesAtual.year, mesAtual.month, 1),
          minutosPrevistos: extrato.minutosPrevistos,
          minutosTrabalhados: extrato.minutosTrabalhados,
          minutosAbonados: extrato.minutosAbonados,
          saldoMinutos: extrato.saldoMinutos,
          fechada: true,
        );

        try {
          await _service.validarEInserirFechamento(novo, folhaFechada);
        } on PostgrestException catch (e) {
          if (e.code == '23505') {
            folhaFechada = true;
            throw const ValidacaoException('Esta folha já foi fechada anteriormente.');
          }
          throw ServidorException('Erro no banco ao fechar folha: ${e.message}');
        }

        fechamentoSalvo = novo;
        folhaFechada = true;
      }, mostrarCarregando: false, erroPadrao: 'Erro ao salvar fechamento.');

  // ───────────── Calendário ─────────────

  StatusDiaCalendario avaliarStatusDia(int dia) => _service.avaliarStatusDia(
        dataDia: DateTime(mesAtual.year, mesAtual.month, dia),
        dataCadastroUsuario: dataCadastroUsuario ?? DateTime.now(),
        minutosPrevistosDia: obterMinutosPrevistosDoDia(dia),
        batidas: pontosPorDia[dia] ?? [],
        ocorrencias: ocorrenciasPorDia[dia] ?? [],
      );

  bool exibirAlertaExclamacao(int dia) {
    final temPendente = (ocorrenciasPorDia[dia] ?? []).any((o) => o.isPendente);
    return avaliarStatusDia(dia) == StatusDiaCalendario.vermelho || temPendente;
  }
}