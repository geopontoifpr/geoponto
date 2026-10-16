class RegistroPontoModel {
  final String id;
  final String usuarioId;
  final String tipoRegistroPonto; // ex: 'entrada', 'saida', 'inicio_intervalo', etc.
  final double latitudeDisp;
  final double longitudeDisp;
  final DateTime criadoEm;

  RegistroPontoModel({
    required this.id,
    required this.usuarioId,
    required this.tipoRegistroPonto,
    required this.latitudeDisp,
    required this.longitudeDisp,
    required this.criadoEm,
  });

  factory RegistroPontoModel.fromMap(Map<String, dynamic> map) {
    return RegistroPontoModel(
      id: map['id'].toString(),
      usuarioId: map['usuario_id'].toString(),
      tipoRegistroPonto: map['tipo_registro_ponto'].toString(),
      latitudeDisp: (map['latitude_disp'] as num).toDouble(),
      longitudeDisp: (map['longitude_disp'] as num).toDouble(),
      criadoEm: DateTime.parse(map['criado_em'].toString()).toLocal(),
    );
  }
}