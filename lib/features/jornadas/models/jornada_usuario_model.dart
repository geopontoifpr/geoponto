class JornadaUsuarioModel {
  final String id;
  final String usuarioId;
  final String jornadaId;
  final DateTime dataInicioVigencia;
  final DateTime? dataFimVigencia;
  JornadaUsuarioModel({
    required this.id,
    required this.usuarioId,
    required this.jornadaId,
    required this.dataInicioVigencia,
    this.dataFimVigencia,
  });

  factory JornadaUsuarioModel.fromJson(Map<String, dynamic> json) {
    return JornadaUsuarioModel(
      id: json['id'] as String,
      usuarioId: json['usuario_id'] as String,
      jornadaId: json['jornada_id'] as String,
      dataInicioVigencia: DateTime.parse(json['data_inicio_vigencia'] as String),
      dataFimVigencia: json['data_fim_vigencia'] != null 
          ? DateTime.parse(json['data_fim_vigencia'] as String) 
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (id.isNotEmpty) 'id': id,
      'usuario_id': usuarioId,
      'jornada_id': jornadaId,
      'data_inicio_vigencia': dataInicioVigencia.toIso8601String().split('T').first,
      'data_fim_vigencia': dataFimVigencia?.toIso8601String().split('T').first,
    };
  }
}