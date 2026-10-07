class SetorModel {
  final String id;
  final String empresaId;
  final String gestorId;
  final String nome;
  final DateTime? criadoEm;
  final DateTime? atualizadoEm;

  SetorModel({
    required this.id,
    required this.empresaId,
    required this.gestorId,
    required this.nome,
    this.criadoEm,
    this.atualizadoEm,
  });

  factory SetorModel.fromMap(Map<String, dynamic> map) {
    return SetorModel(
      id: map['id']?.toString() ?? '',
      empresaId: map['empresa_id']?.toString() ?? '',
      gestorId: map['gestor_id']?.toString() ?? '',
      nome: map['nome']?.toString() ?? '',
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
      'empresa_id': empresaId,
      'gestor_id': gestorId,
      'nome': nome,
    };
  }
}