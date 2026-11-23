class FechamentoMensalModel {
  final String? id;
  final String usuarioId;
  final DateTime mesReferencia;
  final int minutosPrevistos;
  final int minutosTrabalhados;
  final int minutosAbonados;
  final int saldoMinutos;
  final bool fechada;
  final DateTime? criadoEm;
  final DateTime? atualizadoEm;

  FechamentoMensalModel({
    this.id,
    required this.usuarioId,
    required this.mesReferencia,
    required this.minutosPrevistos,
    required this.minutosTrabalhados,
    required this.minutosAbonados,
    required this.saldoMinutos,
    this.fechada = true,
    this.criadoEm,
    this.atualizadoEm,
  });

  factory FechamentoMensalModel.fromMap(Map<String, dynamic> map) {
    return FechamentoMensalModel(
      id: map['id']?.toString(),
      usuarioId: map['usuario_id'].toString(),
      mesReferencia: DateTime.parse(map['mes_referencia'].toString()),
      minutosPrevistos: (map['minutos_previstos'] as num).toInt(),
      minutosTrabalhados: (map['minutos_trabalhados'] as num).toInt(),
      minutosAbonados: (map['minutos_abonados'] as num).toInt(),
      saldoMinutos: (map['saldo_minutos'] as num).toInt(),
      fechada: map['fechada'] as bool? ?? false,
      criadoEm: map['criado_em'] != null
          ? DateTime.parse(map['criado_em'].toString())
          : null,
      atualizadoEm: map['atualizado_em'] != null
          ? DateTime.parse(map['atualizado_em'].toString())
          : null,
    );
  }

  Map<String, dynamic> toMap() {
    final mesRefStr =
        "${mesReferencia.year}-${mesReferencia.month.toString().padLeft(2, '0')}-01";
    return {
      if (id != null) 'id': id,
      'usuario_id': usuarioId,
      'mes_referencia': mesRefStr,
      'minutos_previstos': minutosPrevistos,
      'minutos_trabalhados': minutosTrabalhados,
      'minutos_abonados': minutosAbonados,
      'saldo_minutos': saldoMinutos,
      'fechada': fechada,
    };
  }
}