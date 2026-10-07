enum TipoUsuario {
  administrador,
  gestor,
  colaborador;

  static TipoUsuario fromString(String valor) {
    switch (valor.toUpperCase()) {
      case 'ADMINISTRADOR':
        return TipoUsuario.administrador;
      case 'GESTOR':
        return TipoUsuario.gestor;
      case 'COLABORADOR':
      default:
        return TipoUsuario.colaborador;
    }
  }

  String toDbValue() {
    switch (this) {
      case TipoUsuario.administrador:
        return 'ADMINISTRADOR';
      case TipoUsuario.gestor:
        return 'GESTOR';
      case TipoUsuario.colaborador:
        return 'COLABORADOR';
    }
  }
}

class UsuarioModel {
  final String id;
  final String? empresaId;
  final String? setorId;
  final String nome;
  final String email;
  final TipoUsuario tipoUsuario;
  final bool ativo;

  UsuarioModel({
    required this.id,
    this.empresaId,
    this.setorId,
    required this.nome,
    required this.email,
    required this.tipoUsuario,
    required this.ativo,
  });

  factory UsuarioModel.fromMap(Map<String, dynamic> map) {
  return UsuarioModel(
    id: map['id']?.toString() ?? '',
    empresaId: map['empresa_id']?.toString(),
    setorId: map['setor_id']?.toString(),
    nome: map['nome']?.toString() ?? '',
    email: map['email']?.toString() ?? '',
    tipoUsuario: TipoUsuario.fromString(map['tipo_usuario']?.toString() ?? 'COLABORADOR'),
    // Garante que se vier null, false falso-positivo ou outro tipo, trate com segurança
    ativo: map['ativo'] == true || map['ativo'] == null, 
  );
}

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'empresa_id': empresaId,
      'setor_id': setorId,
      'nome': nome,
      'email': email,
      'tipo_usuario': tipoUsuario.toDbValue(),
      'ativo': ativo,
    };
  }
}