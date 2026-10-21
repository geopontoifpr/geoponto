import 'package:flutter/foundation.dart';
import '../../ocorrencias/models/ocorrencia_model.dart';
import '../models/registro_ponto_model.dart';
import '../services/frequencia_service.dart';

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
  int cargaHorariaSemanal = 40;
  bool carregando = true;
  bool folhaFechada = false;
  String? erroMensagem;

  Map<int, List<RegistroPontoModel>> pontosPorDia = {};
  Map<int, List<OcorrenciaModel>> ocorrenciasPorDia = {};

  String get nomeMesAtual => nomesMeses[mesAtual.month - 1];
  int get totalDiasMes => DateTime(mesAtual.year, mesAtual.month + 1, 0).day;
  int get offsetSemana => DateTime(mesAtual.year, mesAtual.month, 1).weekday % 7;

  Future<void> carregarDadosMes() async {
    carregando = true;
    erroMensagem = null;
    notifyListeners();

    try {
      dataCadastroUsuario ??= await _service.obterDataCadastroUsuario(usuarioId);
      cargaHorariaSemanal = await _service.obterCargaHorariaSemanal(usuarioId);

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
    } catch (e) {
      erroMensagem = 'Erro ao carregar histórico: $e';
    } finally {
      carregando = false;
      notifyListeners();
    }
  }

  void mudarMes(int delta) {
    mesAtual = DateTime(mesAtual.year, mesAtual.month + delta, 1);
    folhaFechada = false;
    carregarDadosMes();
  }

  void fecharFolhaMes() {
    folhaFechada = true;
    notifyListeners();
  }

  Duration calcularHorasDoDia(int dia) {
    return _service.calcularHorasDoDia(
      batidasDoDia: pontosPorDia[dia] ?? [],
      ocorrenciasDoDia: ocorrenciasPorDia[dia] ?? [],
    );
  }

  StatusDiaCalendario avaliarStatusDia(int dia) {
    final hoje = DateTime.now();
    return _service.avaliarStatusDia(
      dataDia: DateTime(mesAtual.year, mesAtual.month, dia),
      dataCadastroUsuario: dataCadastroUsuario ?? hoje,
      cargaHorariaSemanal: cargaHorariaSemanal,
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

  ({
    int trabHoras,
    int trabMin,
    int faltamHoras,
    int faltamMinRest,
    double progresso,
  }) calcularResumoMensal() {
    Duration totalTrabalhadoMes = Duration.zero;
    int diasUteisNoMes = 0;

    for (int d = 1; d <= totalDiasMes; d++) {
      totalTrabalhadoMes += calcularHorasDoDia(d);
      final dt = DateTime(mesAtual.year, mesAtual.month, d);
      if (dt.weekday != DateTime.saturday && dt.weekday != DateTime.sunday) {
        diasUteisNoMes++;
      }
    }

    final horasDiarias = cargaHorariaSemanal / 5.0;
    final metaMensalMinutos = (diasUteisNoMes * horasDiarias * 60).round();
    final faltamMinutos =
        (metaMensalMinutos - totalTrabalhadoMes.inMinutes).clamp(0, metaMensalMinutos);

    final progresso = metaMensalMinutos > 0
        ? (totalTrabalhadoMes.inMinutes / metaMensalMinutos).clamp(0.0, 1.0)
        : 0.0;

    return (
      trabHoras: totalTrabalhadoMes.inHours,
      trabMin: totalTrabalhadoMes.inMinutes % 60,
      faltamHoras: faltamMinutos ~/ 60,
      faltamMinRest: faltamMinutos % 60,
      progresso: progresso,
    );
  }

  ({
    int horasPrevistas,
    Duration totalTrabalhado,
    int saldoMinutos,
    int diasTrabalhados,
    int minutosCredito,
    int minutosDebito,
  }) calcularExtratoDetalhado() {
    final hoje = DateTime.now();
    final hojeSemHora = DateTime(hoje.year, hoje.month, hoje.day);
    final metaDiariaMinutos = (cargaHorariaSemanal / 5.0 * 60.0).round();

    int diasUteisNoMes = 0;
    int diasTrabalhados = 0;
    int minutosCredito = 0;
    int minutosDebito = 0;
    Duration totalTrabalhado = Duration.zero;

    for (int d = 1; d <= totalDiasMes; d++) {
      final dt = DateTime(mesAtual.year, mesAtual.month, d);
      final isDiaUtil =
          dt.weekday != DateTime.saturday && dt.weekday != DateTime.sunday;

      if (isDiaUtil) {
        diasUteisNoMes++;
      }

      final duracaoDia = calcularHorasDoDia(d);
      final minDia = duracaoDia.inMinutes;
      totalTrabalhado += duracaoDia;

      if (minDia > 0 || (pontosPorDia[d]?.isNotEmpty ?? false)) {
        diasTrabalhados++;
      }

      if (!dt.isAfter(hojeSemHora)) {
        if (isDiaUtil) {
          final diff = minDia - metaDiariaMinutos;
          if (diff > 0) {
            minutosCredito += diff;
          } else if (diff < 0 && minDia > 0) {
            minutosDebito += diff.abs();
          }
        } else if (minDia > 0) {
          minutosCredito += minDia;
        }
      }
    }

    final horasPrevistas = (diasUteisNoMes * (cargaHorariaSemanal / 5.0)).round();
    final saldoMinutos = minutosCredito - minutosDebito;

    return (
      horasPrevistas: horasPrevistas,
      totalTrabalhado: totalTrabalhado,
      saldoMinutos: saldoMinutos,
      diasTrabalhados: diasTrabalhados,
      minutosCredito: minutosCredito,
      minutosDebito: minutosDebito,
    );
  }
}