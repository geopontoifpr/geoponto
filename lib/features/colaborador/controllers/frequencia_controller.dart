import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../ocorrencias/models/ocorrencia_model.dart';
import '../models/registro_ponto_model.dart';
import '../services/frequencia_service.dart';
import '../../gestor/models/fechamento_mensal_model.dart';
import '../../../core/utils/feriados_util.dart';


class FrequenciaController extends ChangeNotifier {
  final String usuarioId;
  final FrequenciaService _service;

  FrequenciaController({
    required this.usuarioId,
    FrequenciaService? service,
  }) : _service = service ?? FrequenciaService() {
    final agora = DateTime.now();
    mesAtual = DateTime(agora.year, agora.month, 1);
  }

  static const List<String> nomesMeses = [
    'Janeiro', 'Fevereiro', 'Março', 'Abril', 'Maio', 'Junho',
    'Julho', 'Agosto', 'Setembro', 'Outubro', 'Novembro', 'Dezembro'
  ];

  late DateTime mesAtual;
  DateTime? dataCadastroUsuario;
  int cargaHorariaSemanalPadrao = 40;
  bool carregando = true;
  bool folhaFechada = false;
  FechamentoMensalModel? fechamentoSalvo;
  String? erroMensagem;

  List<Map<String, dynamic>> jornadasDoMes = [];
  Map<int, List<RegistroPontoModel>> pontosPorDia = {};
  Map<int, List<OcorrenciaModel>> ocorrenciasPorDia = {};

  String get nomeMesAtual => nomesMeses[mesAtual.month - 1];
  int get totalDiasMes => DateTime(mesAtual.year, mesAtual.month + 1, 0).day;
  int get offsetSemana => DateTime(mesAtual.year, mesAtual.month, 1).weekday % 7;

  /// Requisito 11: Somente meses anteriores ao atual e ainda não fechados
  bool get isMesAnteriorAoAtual {
    final agora = DateTime.now();
    final inicioMesAtual = DateTime(agora.year, agora.month, 1);
    return mesAtual.isBefore(inicioMesAtual);
  }

  bool get podeFecharFolha => isMesAnteriorAoAtual && !folhaFechada;

  Future<void> carregarDadosMes() async {
    carregando = true;
    erroMensagem = null;
    notifyListeners();

    try {
      dataCadastroUsuario ??= await _service.obterDataCadastroUsuario(usuarioId);
      cargaHorariaSemanalPadrao = await _service.obterCargaHorariaSemanal(usuarioId);

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
    } catch (e) {
      erroMensagem = 'Não foi possível carregar os dados do mês: $e';
    } finally {
      carregando = false;
      notifyListeners();
    }
  }

  void mudarMes(int delta) {
    mesAtual = DateTime(mesAtual.year, mesAtual.month + delta, 1);
    folhaFechada = false;
    fechamentoSalvo = null;
    carregarDadosMes();
  }

  /// Requisito 10: Busca a carga horária vigente na data específica do dia
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
    // Zera os minutos previstos se for sábado, domingo ou feriado
    if (FeriadosUtil.isFimDeSemanaOuFeriado(data)) {
      return 0;
    }
    return ((obterCargaHorariaDoDia(dia) * 60) / 5).round();
  }

  /// Mantido com retorno Duration para compatibilidade com HistoricoMensalScreen
  Duration calcularHorasDoDia(int dia) {
    final min = _service.calcularMinutosTrabalhadosDoDia(pontosPorDia[dia] ?? []);
    return Duration(minutes: min);
  }

  /// Requisito 3 e 9: Dados consolidados de um único dia
  ({
    int minutosTrabalhados,
    int minutosAbonados,
    int minutosPrevistos,
    int saldoMinutos,
    bool isFimDeSemana,
    String? nomeFeriado, // <--- ADICIONADO AQUI NO TIPO DE RETORNO
    List<RegistroPontoModel> batidas,
  }) obterDadosDia(int dia) {
    final dt = DateTime(mesAtual.year, mesAtual.month, dia);
    final isFimDeSemana = FeriadosUtil.isFimDeSemanaOuFeriado(dt);
    final nomeFeriado = FeriadosUtil.obterFeriado(dt);   
    final batidas = pontosPorDia[dia] ?? [];
    final ocorrencias = ocorrenciasPorDia[dia] ?? [];

    final trabalhados = _service.calcularMinutosTrabalhadosDoDia(batidas);
    final abonados = _service.calcularMinutosAbonadosDoDia(ocorrencias);
    final previstos = obterMinutosPrevistosDoDia(dia);
    final saldo = trabalhados + abonados - previstos;

    return (
      minutosTrabalhados: trabalhados,
      minutosAbonados: abonados,
      minutosPrevistos: previstos,
      saldoMinutos: saldo,
      isFimDeSemana: isFimDeSemana,
      nomeFeriado: nomeFeriado, // <--- ADICIONADO AQUI NO RETURN
      batidas: batidas,
    );
  }

  /// Requisitos 4, 7, 8, 9 e 14: Cálculo mensal unificado em minutos
  ({
    int minutosPrevistos,
    int minutosTrabalhados,
    int minutosAbonados,
    int saldoMinutos,
    int diasTrabalhados,
    int minutosCredito,
    int minutosDebito,
  }) calcularExtratoDetalhado() {
    int minutosPrevistos = 0;
    int minutosTrabalhados = 0;
    int minutosAbonados = 0;
    int diasTrabalhados = 0;
    int minutosCredito = 0;
    int minutosDebito = 0;

    for (int d = 1; d <= totalDiasMes; d++) {
      final infoDia = obterDadosDia(d);

      minutosPrevistos += infoDia.minutosPrevistos;
      minutosTrabalhados += infoDia.minutosTrabalhados;
      minutosAbonados += infoDia.minutosAbonados;

      if (infoDia.minutosTrabalhados > 0 || infoDia.batidas.isNotEmpty) {
        diasTrabalhados++;
      }

      if (infoDia.saldoMinutos > 0) {
        minutosCredito += infoDia.saldoMinutos;
      } else if (infoDia.saldoMinutos < 0) {
        minutosDebito += infoDia.saldoMinutos.abs();
      }
    }

    // Se a folha já estiver fechada no banco, preserva os totais oficiais gravados
    if (folhaFechada && fechamentoSalvo != null) {
      return (
        minutosPrevistos: fechamentoSalvo!.minutosPrevistos,
        minutosTrabalhados: fechamentoSalvo!.minutosTrabalhados,
        minutosAbonados: fechamentoSalvo!.minutosAbonados,
        saldoMinutos: fechamentoSalvo!.saldoMinutos,
        diasTrabalhados: diasTrabalhados,
        minutosCredito: minutosCredito,
        minutosDebito: minutosDebito,
      );
    }

    final saldoMinutos =
        minutosTrabalhados + minutosAbonados - minutosPrevistos;

    return (
      minutosPrevistos: minutosPrevistos,
      minutosTrabalhados: minutosTrabalhados,
      minutosAbonados: minutosAbonados,
      saldoMinutos: saldoMinutos,
      diasTrabalhados: diasTrabalhados,
      minutosCredito: minutosCredito,
      minutosDebito: minutosDebito,
    );
  }

  /// Requisitos 11, 12, 13 e 16: Fechamento de folha com validação e bloqueio de duplicidade
  Future<bool> fecharFolhaMes() async {
    if (!isMesAnteriorAoAtual) {
      erroMensagem = 'Apenas meses anteriores ao mês atual podem ser fechados.';
      notifyListeners();
      return false;
    }
    if (folhaFechada) {
      erroMensagem = 'Esta folha mensal já se encontra fechada.';
      notifyListeners();
      return false;
    }

    try {
      final extrato = calcularExtratoDetalhado();
      final novoFechamento = FechamentoMensalModel(
        usuarioId: usuarioId,
        mesReferencia: DateTime(mesAtual.year, mesAtual.month, 1),
        minutosPrevistos: extrato.minutosPrevistos,
        minutosTrabalhados: extrato.minutosTrabalhados,
        minutosAbonados: extrato.minutosAbonados,
        saldoMinutos: extrato.saldoMinutos,
        fechada: true,
      );

      await _service.inserirFechamentoMensal(novoFechamento);
      fechamentoSalvo = novoFechamento;
      folhaFechada = true;
      erroMensagem = null;
      notifyListeners();
      return true;
    } on PostgrestException catch (e) {
      if (e.code == '23505') {
        erroMensagem = 'Esta folha já foi fechada anteriormente.';
        folhaFechada = true;
      } else {
        erroMensagem = 'Erro no banco ao fechar folha: ${e.message}';
      }
      notifyListeners();
      return false;
    } catch (e) {
      erroMensagem = 'Erro ao fechar folha: $e';
      notifyListeners();
      return false;
    }
  }

  /// Mantido para compatibilidade com HistoricoMensalScreen (visão do colaborador)
  ({
    int trabHoras,
    int trabMin,
    int faltamHoras,
    int faltamMinRest,
    double progresso,
  }) calcularResumoMensal() {
    final extrato = calcularExtratoDetalhado();
    final totalConcluido = extrato.minutosTrabalhados + extrato.minutosAbonados;
    final faltamMinutos = (extrato.minutosPrevistos - totalConcluido)
        .clamp(0, extrato.minutosPrevistos);

    final progresso = extrato.minutosPrevistos > 0
        ? (totalConcluido / extrato.minutosPrevistos).clamp(0.0, 1.0)
        : 0.0;

    return (
      trabHoras: extrato.minutosTrabalhados ~/ 60,
      trabMin: extrato.minutosTrabalhados % 60,
      faltamHoras: faltamMinutos ~/ 60,
      faltamMinRest: faltamMinutos % 60,
      progresso: progresso,
    );
  }

  StatusDiaCalendario avaliarStatusDia(int dia) {
    final hoje = DateTime.now();
    return _service.avaliarStatusDia(
      dataDia: DateTime(mesAtual.year, mesAtual.month, dia),
      dataCadastroUsuario: dataCadastroUsuario ?? hoje,
      minutosPrevistosDia: obterMinutosPrevistosDoDia(dia),
      batidas: pontosPorDia[dia] ?? [],
      ocorrencias: ocorrenciasPorDia[dia] ?? [],
    );
  }

  bool exibirAlertaExclamacao(int dia) {
    final status = avaliarStatusDia(dia);
    final ocorrencias = ocorrenciasPorDia[dia] ?? [];
    final temOcorrenciaPendente = ocorrencias.any((o) => o.isPendente);
    return status == StatusDiaCalendario.vermelho || temOcorrenciaPendente;
  }
}