class JornadaUsuarioModel {
  final String id;
  final String usuarioId;
  final String jornadaId;
  final DateTime? dataInicioVigencia;
  final DateTime? dataFimVigencia;
  final DateTime? criadoEm;
  final DateTime? atualizadoEm;

  JornadaUsuarioModel({
    required this.id,
    required this.usuarioId,
    required this.jornadaId,
    this.dataInicioVigencia,
    this.dataFimVigencia,
    this.criadoEm,
    this.atualizadoEm,
  });

  factory JornadaUsuarioModel.fromMap(Map<String, dynamic> map) {
    return JornadaUsuarioModel(
      id: map['id'] ?? '',
      usuarioId: map['usuario_id'] ?? '',
      jornadaId: map['jornada_id'] ?? '',
      dataInicioVigencia: map['data_inicio_vigencia'] != null 
          ? DateTime.parse(map['data_inicio_vigencia']) 
          : null,
      dataFimVigencia: map['data_fim_vigencia'] != null 
          ? DateTime.parse(map['data_fim_vigencia']) 
          : null,
      criadoEm: map['criado_em'] != null 
          ? DateTime.parse(map['criado_em']) 
          : null,
      atualizadoEm: map['atualizado_em'] != null 
          ? DateTime.parse(map['atualizado_em']) 
          : null,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'usuario_id': usuarioId,
      'jornada_id': jornadaId,
      if (dataInicioVigencia != null) 'data_inicio_vigencia': dataInicioVigencia!.toIso8601String().split('T')[0], // Pega só a data (YYYY-MM-DD)
      if (dataFimVigencia != null) 'data_fim_vigencia': dataFimVigencia!.toIso8601String().split('T')[0],
      if (criadoEm != null) 'criado_em': criadoEm!.toIso8601String(),
      if (atualizadoEm != null) 'atualizado_em': atualizadoEm!.toIso8601String(),
    };
  }
}