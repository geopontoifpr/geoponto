
// Enum padronizado para evitar erros de digitação e facilitar o uso
enum TipoUsuario {
  administrador,
  gestor,
  funcionario;

  // Converte do Enum para String do Banco
  String toDbValue() => name.toUpperCase();

  // Converte da String do Banco para o Enum
  static TipoUsuario fromString(String value) {
    switch (value.toUpperCase()) {
      case 'ADMINISTRADOR':
        return TipoUsuario.administrador;
      case 'GESTOR':
        return TipoUsuario.gestor;
      case 'FUNCIONARIO':
      default:
        return TipoUsuario.funcionario;
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
  final bool primeiroAcesso;
  final String? setorNome; // Apenas para exibição (Join)
  final String? dispositivoUsuario;


  UsuarioModel({
    required this.id,
    this.empresaId,
    this.setorId,
    required this.nome,
    required this.email,
    required this.tipoUsuario,
    this.ativo = true,
    this.primeiroAcesso = true,
    this.setorNome,
    this.dispositivoUsuario,

  });

  factory UsuarioModel.fromMap(Map<String, dynamic> map) {
    return UsuarioModel(
      id: map['id']?.toString() ?? '',
      empresaId: map['empresa_id']?.toString(),
      setorId: map['setor_id']?.toString(),
      nome: map['nome']?.toString() ?? '',
      email: map['email']?.toString() ?? '',
      tipoUsuario: TipoUsuario.fromString(map['tipo_usuario']?.toString() ?? 'FUNCIONARIO'),
      // Navega no JSON aninhado que o Supabase retorna no join
      setorNome: map['setores']?['nome']?.toString(),
      // Garante que se vier null do banco, tratamos como ativo (true)
      ativo: map['ativo'] == true || map['ativo'] == null,
      primeiroAcesso: map['primeiro_acesso'] ?? false,
      dispositivoUsuario: map['dispositivo_usuario']?.toString(),

    );
  }

  Map<String, dynamic> toMap() {
    return {
      // id é omitido aqui geralmente, pois é gerado pelo banco ou passado por .eq('id', id)
      'empresa_id': empresaId,
      'setor_id': setorId,
      'nome': nome,
      'email': email,
      'tipo_usuario': tipoUsuario.toDbValue(),
      'ativo': ativo,
      'primeiro_acesso': primeiroAcesso,
      'dispositivo_usuario': dispositivoUsuario,
    };
  }

  // O copyWith é excelente para manipulações rápidas sem perder os dados originais
  UsuarioModel copyWith({
    String? id,
    String? empresaId,
    String? setorId,
    String? nome,
    String? email,
    TipoUsuario? tipoUsuario,
    bool? ativo,
    bool? primeiroAcesso,
    String? setorNome,
    String? dispositivoUsuario,

  }) {
    return UsuarioModel(
      id: id ?? this.id,
      empresaId: empresaId ?? this.empresaId,
      setorId: setorId ?? this.setorId,
      nome: nome ?? this.nome,
      email: email ?? this.email,
      tipoUsuario: tipoUsuario ?? this.tipoUsuario,
      ativo: ativo ?? this.ativo,
      setorNome: setorNome ?? this.setorNome,
      primeiroAcesso: primeiroAcesso ?? this.primeiroAcesso,
      dispositivoUsuario: dispositivoUsuario ?? this.dispositivoUsuario
    );
  }
}