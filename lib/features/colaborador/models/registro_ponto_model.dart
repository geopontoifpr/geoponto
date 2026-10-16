enum TipoRegistroEnum {
  entrada1('entrada_1', 'Entrada 1'),
  saida1('saida_1', 'Saída 1 (Almoço)'),
  entrada2('entrada_2', 'Entrada 2 (Retorno)'),
  saida2('saida_2', 'Saída 2 (Fim do Expediente)');

  final String valorBanco;
  final String titulo;

  const TipoRegistroEnum(this.valorBanco, this.titulo);

  // Fabrica o Enum a partir do que vem do banco de dados (trata entry1, entrada_1, etc.)
  factory TipoRegistroEnum.fromBanco(String valor) {
    final normalizado = valor.toLowerCase().replaceAll('_', '');
    switch (normalizado) {
      case 'entrada1':
      case 'entry1':
        return TipoRegistroEnum.entrada1;
      case 'saida1':
      case 'exit1':
      case 'saidaalmoco':
        return TipoRegistroEnum.saida1;
      case 'entrada2':
      case 'entry2':
      case 'retorno':
        return TipoRegistroEnum.entrada2;
      case 'saida2':
      case 'exit2':
        return TipoRegistroEnum.saida2;
      default:
        return TipoRegistroEnum.entrada1; // Fallback de segurança
    }
  }
}

class RegistroPontoModel {
  final String? id;
  final String usuarioId;
  final DateTime criadoEm;
  final TipoRegistroEnum tipoRegistro; // Mudamos de String para o Enum forte!
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
      // Converte a string do banco diretamente para o nosso Enum
      tipoRegistro: TipoRegistroEnum.fromBanco(map['tipo_registro_ponto'].toString()),
      latitudeDisp: (map['latitude_disp'] as num).toDouble(),
      longitudeDisp: (map['longitude_disp'] as num).toDouble(),
    );
  }

  Map<String, dynamic> toMap() => {
        if (id != null) 'id': id,
        'usuario_id': usuarioId,
        // Ao salvar no banco, manda a string correta (ex: 'entrada_1')
        'tipo_registro_ponto': tipoRegistro.valorBanco, 
        'latitude_disp': latitudeDisp,
        'longitude_disp': longitudeDisp,
        'criado_em': criadoEm.toIso8601String(),
      };
}