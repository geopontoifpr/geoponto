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
    carregarDadosMes();
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
    final temOcorrenciaPendente = ocorrencias.any((o) => !o.aprovada);
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
}