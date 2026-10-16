class RegistroPontoModel {
  final String? id;
  final String usuarioId;
  final DateTime criadoEm;
  final String tipoRegistro;
  final double latitudeDisp;
  final double longitudeDisp;

  const RegistroPontoModel({
    this.id,
    required this.usuarioId,
    required this.criadoEm,
    required this.tipoRegistro,
    required this.latitudeDisp,
    required this.longitudeDisp,
  });

  factory RegistroPontoModel.fromMap(Map<String, dynamic> map) {
    return RegistroPontoModel(
      id: map['id']?.toString(),
      usuarioId: map['usuario_id'] as String,
      criadoEm: DateTime.parse(map['criado_em'] as String),
      tipoRegistro: map['tipo_registro_ponto'].toString(),
      latitudeDisp: (map['latitude_disp'] as num).toDouble(),
      longitudeDisp: (map['longitude_disp'] as num).toDouble(),
    );
  }

  Map<String, dynamic> toMap() => {
        if (id != null) 'id': id,
        'usuario_id': usuarioId,
        'tipo_registro_ponto': tipoRegistro,
        'latitude_disp': latitudeDisp,
        'longitude_disp': longitudeDisp,
        'criado_em': criadoEm.toIso8601String(),
      };
}
