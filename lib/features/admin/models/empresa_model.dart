class EmpresaModel {
  final String id;
  final String? nome;
  final String? cnpj;
  final double? latitude;
  final double? longitude;
  final int? raioPermitido;
  final DateTime? criadoEm;
  final DateTime? atualizadoEm;

  EmpresaModel({
    required this.id,
    this.nome,
    this.cnpj,
    this.latitude,
    this.longitude,
    this.raioPermitido,
    this.criadoEm,
    this.atualizadoEm,
  });

  factory EmpresaModel.fromMap(Map<String, dynamic> map) {
    return EmpresaModel(
      id: map['id']?.toString() ?? '',
      nome: map['nome']?.toString(),
      cnpj: map['cnpj']?.toString(),
      latitude: (map['latitude_ponto'] as num?)?.toDouble(),
      longitude: (map['longitude_ponto'] as num?)?.toDouble(),
      raioPermitido: (map['raio_permitido_m'] as num?)?.toInt(), // Agora é int
      criadoEm: map['criado_em'] != null 
          ? DateTime.tryParse(map['criado_em'].toString()) 
          : null,
      atualizadoEm: map['atualizado_em'] != null 
          ? DateTime.tryParse(map['atualizado_em'].toString()) 
          : null,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'nome': nome,
      'cnpj': cnpj,
      'latitude_ponto': latitude,
      'longitude_ponto': longitude,
      'raio_permitido_m': raioPermitido,
    };
  }
}