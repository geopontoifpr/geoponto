class JornadaTrabalhoModel {
  final String id;
  final int cargaHorariaSemanal;
  final DateTime criadoEm;
  final DateTime atualizadoEm;

  JornadaTrabalhoModel({
    required this.id,
    required this.cargaHorariaSemanal,
    required this.criadoEm,
    required this.atualizadoEm,
  });

  factory JornadaTrabalhoModel.fromJson(Map<String, dynamic> json) {
    return JornadaTrabalhoModel(
      id: json['id'] as String,
      cargaHorariaSemanal: json['carga_horaria_sem'] as int,
      criadoEm: DateTime.parse(json['criado_em'] as String),
      atualizadoEm: DateTime.parse(json['atualizado_em'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (id.isNotEmpty) 'id': id,
      'carga_horaria_sem': cargaHorariaSemanal,
    };
  }
}