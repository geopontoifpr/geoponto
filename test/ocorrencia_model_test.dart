import 'package:flutter_test/flutter_test.dart';
import 'package:geoponto/features/ocorrencias/models/ocorrencia_model.dart';

OcorrenciaModel criarOcorrencia({
  bool aprovada = false,
  int? minutosAbonados,
  String? observacaoGestor,
}) {
  return OcorrenciaModel(
    usuarioId: 'usuario-1',
    gestorId: 'gestor-1',
    dataInicio: DateTime(2026, 10, 10),
    tipoOcorrencia: TipoOcorrenciaEnum.atraso,
    justificativa: 'Justificativa de teste',
    aprovada: aprovada,
    minutosAbonados: minutosAbonados,
    observacaoGestor: observacaoGestor,
  );
}

void main() {
  test('ocorrência sem resultado persistido permanece pendente', () {
    final ocorrencia = criarOcorrencia();

    expect(ocorrencia.isPendente, isTrue);
    expect(ocorrencia.foiAvaliada, isFalse);
    expect(ocorrencia.isRecusada, isFalse);
  });

  test('ocorrência aprovada é respondida', () {
    final ocorrencia = criarOcorrencia(
      aprovada: true,
      minutosAbonados: 60,
    );

    expect(ocorrencia.foiAvaliada, isTrue);
    expect(ocorrencia.isPendente, isFalse);
    expect(ocorrencia.isRecusada, isFalse);
  });

  test('ocorrência recusada com zero minutos é respondida', () {
    final ocorrencia = criarOcorrencia(minutosAbonados: 0);

    expect(ocorrencia.foiAvaliada, isTrue);
    expect(ocorrencia.isPendente, isFalse);
    expect(ocorrencia.isRecusada, isTrue);
  });

  test('observação isolada não marca ocorrência como respondida', () {
    final ocorrencia = criarOcorrencia(
      observacaoGestor: 'Analisarei em seguida',
    );

    expect(ocorrencia.isPendente, isTrue);
    expect(ocorrencia.foiAvaliada, isFalse);
  });
}
