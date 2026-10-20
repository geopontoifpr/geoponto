import '../../ocorrencias/models/ocorrencia_model.dart';
import '../../ocorrencias/repositories/ocorrencia_repository.dart';
import '../models/registro_ponto_model.dart';
import '../repositories/frequencia_repository.dart';

enum StatusDiaCalendario { neutro, verde, laranja, vermelho }

class FrequenciaService {
  final FrequenciaRepository _frequenciaRepo;
  final OcorrenciaRepository _ocorrenciaRepo;

  FrequenciaService({
    FrequenciaRepository? frequenciaRepo,
    OcorrenciaRepository? ocorrenciaRepo,
  })  : _frequenciaRepo = frequenciaRepo ?? FrequenciaRepository(),
        _ocorrenciaRepo = ocorrenciaRepo ?? OcorrenciaRepository();

  Future<DateTime> obterDataCadastroUsuario(String usuarioId) {
    return _frequenciaRepo.obterDataCadastroUsuario(usuarioId);
  }

  Future<int> obterCargaHorariaSemanal(String usuarioId) {
    return _frequenciaRepo.obterCargaHorariaSemanal(usuarioId);
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
      final dia = p.criadoEm.toLocal().day;
      mapPontos.putIfAbsent(dia, () => []).add(p);
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
      final dia = oc.dataInicio.day;
      mapOcorrencias.putIfAbsent(dia, () => []).add(oc);
    }
    return mapOcorrencias;
  }

  Duration calcularHorasDoDia({
    required List<RegistroPontoModel> batidasDoDia,
    required List<OcorrenciaModel> ocorrenciasDoDia,
  }) {
    final batidas = List<RegistroPontoModel>.from(batidasDoDia)
      ..sort((a, b) => a.criadoEm.compareTo(b.criadoEm));

    Duration total = Duration.zero;
    for (int i = 0; i + 1 < batidas.length; i += 2) {
      final diff = batidas[i + 1].criadoEm.difference(batidas[i].criadoEm);
      if (!diff.isNegative) {
        total += diff;
      }
    }

    for (final oc in ocorrenciasDoDia) {
      if (oc.aprovada && oc.minutosAbonados != null) {
        total += Duration(minutes: oc.minutosAbonados!);
      }
    }
    return total;
  }

  StatusDiaCalendario avaliarStatusDia({
    required DateTime dataDia,
    required DateTime dataCadastroUsuario,
    required int cargaHorariaSemanal,
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

    final isFimDeSemana =
        dataDia.weekday == DateTime.saturday || dataDia.weekday == DateTime.sunday;

    if (dataDia.isAfter(hojeSemHora)) return StatusDiaCalendario.neutro;
    if (dataDia.isBefore(cadastroSemHora) && batidas.isEmpty) {
      return StatusDiaCalendario.neutro;
    }
    if (isFimDeSemana && batidas.isEmpty) {
      return StatusDiaCalendario.neutro;
    }

    if (batidas.isEmpty) {
      final temAbonoAprovado = ocorrencias.any((o) => o.aprovada);
      if (temAbonoAprovado) return StatusDiaCalendario.verde;

      if (dataDia.isAtSameMomentAs(hojeSemHora)) {
        return StatusDiaCalendario.neutro;
      }
      return StatusDiaCalendario.vermelho;
    }

    if (batidas.length.isOdd) {
      return StatusDiaCalendario.laranja;
    }

    final metaMinutosDia = (cargaHorariaSemanal / 5.0 * 60.0).round();
    final trabalhadoMinutos = calcularHorasDoDia(
      batidasDoDia: batidas,
      ocorrenciasDoDia: ocorrencias,
    ).inMinutes;

    if (trabalhadoMinutos >= (metaMinutosDia - 15)) {
      return StatusDiaCalendario.verde;
    } else {
      return StatusDiaCalendario.laranja;
    }
  }
}