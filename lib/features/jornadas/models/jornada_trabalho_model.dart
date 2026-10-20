class JornadaTrabalhoModel {
  final String id;
  final int cargaHorariaSem;
  final DateTime? criadoEm;
  final DateTime? atualizadoEm;

  JornadaTrabalhoModel({
    required this.id,
    required this.cargaHorariaSem,
    this.criadoEm,
    this.atualizadoEm,
  });

  factory JornadaTrabalhoModel.fromMap(Map<String, dynamic> map) {
    return JornadaTrabalhoModel(
      id: map['id'] ?? '',
      cargaHorariaSem: map['carga_horaria_sem']?.toInt() ?? 0,
      criadoEm: map['criado_em'] != null ? DateTime.parse(map['criado_em']) : null,
      atualizadoEm: map['atualizado_em'] != null ? DateTime.parse(map['atualizado_em']) : null,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'carga_horaria_sem': cargaHorariaSem,
      if (criadoEm != null) 'criado_em': criadoEm!.toIso8601String(),
      if (atualizadoEm != null) 'atualizado_em': atualizadoEm!.toIso8601String(),
    };
  }
}