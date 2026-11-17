import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/errors/app_exception.dart';
import '../../../core/utils/executor_async.dart';
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
    carregando = true; 
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

  bool get isMesAnteriorAoAtual {
    final agora = DateTime.now();
    return mesAtual.isBefore(DateTime(agora.year, agora.month, 1));
  }

  bool get podeFecharFolha => isMesAnteriorAoAtual && !folhaFechada;

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

  // ───────────── Cálculos Delegados ao Service ─────────────

  int obterCargaHorariaDoDia(int dia) => _service.obterCargaHorariaDoDia(
        dia: dia,
        mesAtual: mesAtual,
        jornadasDoMes: jornadasDoMes,
        cargaHorariaSemanalPadrao: cargaHorariaSemanalPadrao,
      );

  int obterMinutosPrevistosDoDia(int dia) => _service.obterMinutosPrevistosDoDia(
        dia: dia,
        mesAtual: mesAtual,
        cargaHorariaDoDia: obterCargaHorariaDoDia(dia),
      );

  Duration calcularHorasDoDia(int dia) => Duration(
        minutes: _service.calcularMinutosTrabalhadosDoDia(pontosPorDia[dia] ?? []),
      );

  ({
    int minutosTrabalhados,
    int minutosAbonados,
    int minutosPrevistos,
    int saldoMinutos,
    bool isFimDeSemana,
    String? nomeFeriado,
    List<RegistroPontoModel> batidas,
  }) obterDadosDia(int dia) => _service.obterDadosDia(
        dia: dia,
        mesAtual: mesAtual,
        batidas: pontosPorDia[dia] ?? [],
        ocorrencias: ocorrenciasPorDia[dia] ?? [],
        minutosPrevistos: obterMinutosPrevistosDoDia(dia),
      );

  ({
    int minutosPrevistos,
    int minutosTrabalhados,
    int minutosAbonados,
    int saldoMinutos,
    int diasTrabalhados,
    int minutosCredito,
    int minutosDebito,
  }) calcularExtratoDetalhado() => _service.calcularExtratoDetalhado(
        totalDiasMes: totalDiasMes,
        mesAtual: mesAtual,
        pontosPorDia: pontosPorDia,
        ocorrenciasPorDia: ocorrenciasPorDia,
        jornadasDoMes: jornadasDoMes,
        cargaHorariaSemanalPadrao: cargaHorariaSemanalPadrao,
        folhaFechada: folhaFechada,
        fechamentoSalvo: fechamentoSalvo,
      );

  ({
    int trabHoras,
    int trabMin,
    int faltamHoras,
    int faltamMinRest,
    double progresso,
  }) calcularResumoMensal() => _service.calcularResumoMensal(calcularExtratoDetalhado());

  // ───────────── Fechamento ─────────────

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
          await _service.validarEInserirFechamento(novo, folhaFechada,ocorrenciasPorDia);
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