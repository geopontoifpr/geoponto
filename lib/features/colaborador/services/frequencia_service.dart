import '../../ocorrencias/models/ocorrencia_model.dart';
import '../../ocorrencias/repositories/ocorrencia_repository.dart';
import '../models/registro_ponto_model.dart';
import '../repositories/frequencia_repository.dart';
import '../../gestor/models/fechamento_mensal_model.dart';

enum StatusDiaCalendario { neutro, verde, laranja, vermelho }

class FrequenciaService {
  final FrequenciaRepository _frequenciaRepo;
  final OcorrenciaRepository _ocorrenciaRepo;

  FrequenciaService({
    FrequenciaRepository? frequenciaRepo,
    OcorrenciaRepository? ocorrenciaRepo,
  })  : _frequenciaRepo = frequenciaRepo ?? FrequenciaRepository(),
        _ocorrenciaRepo = ocorrenciaRepo ?? OcorrenciaRepository();

  Future<DateTime> obterDataCadastroUsuario(String usuarioId) =>
      _frequenciaRepo.obterDataCadastroUsuario(usuarioId);

  Future<int> obterCargaHorariaSemanal(String usuarioId) =>
      _frequenciaRepo.obterCargaHorariaSemanal(usuarioId);

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

  /// Agrupa por dia local da batida e garante ordem cronológica (Requisitos 2 e 6)
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

  /// Calcula minutos trabalhados APENAS a partir de pares de batidas (Requisito 7)
  int calcularMinutosTrabalhadosDoDia(List<RegistroPontoModel> batidasDoDia) {
    if (batidasDoDia.length < 2) return 0;

    final batidas = List<RegistroPontoModel>.from(batidasDoDia)
      ..sort((a, b) => a.dataHoraPonto.compareTo(b.dataHoraPonto));

    int totalMinutos = 0;
    for (int i = 0; i + 1 < batidas.length; i += 2) {
      final diff =
          batidas[i + 1].dataHoraPonto.difference(batidas[i].dataHoraPonto);
      if (!diff.isNegative) {
        totalMinutos += diff.inMinutes;
      }
    }
    return totalMinutos;
  }

  /// Soma apenas ocorrências aprovadas (Requisito 8)
  int calcularMinutosAbonadosDoDia(List<OcorrenciaModel> ocorrenciasDoDia) {
    int totalAbonado = 0;
    for (final oc in ocorrenciasDoDia) {
      if (oc.aprovada && oc.minutosAbonados != null) {
        totalAbonado += oc.minutosAbonados!;
      }
    }
    return totalAbonado;
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