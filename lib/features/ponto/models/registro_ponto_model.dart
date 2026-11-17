enum TipoRegistroEnum {
  entrada1('entrada_1', 'Entrada 1'),
  saida1('saida_1', 'Saída 1 (Almoço)'),
  entrada2('entrada_2', 'Entrada 2 (Retorno)'),
  saida2('saida_2', 'Saída 2 (Fim do Expediente)');

  final String valorBanco;
  final String titulo;

  const TipoRegistroEnum(this.valorBanco, this.titulo);

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
        return TipoRegistroEnum.entrada1;
    }
  }
}

class RegistroPontoModel {
  final String? id;
  final String usuarioId;
  final DateTime dataHoraPonto;
  final DateTime criadoEm;
  final TipoRegistroEnum tipoRegistro;
  final double latitudeDisp;
  final double longitudeDisp;

  const RegistroPontoModel({
    this.id,
    required this.usuarioId,
    required this.dataHoraPonto,
    required this.criadoEm,
    required this.tipoRegistro,
    required this.latitudeDisp,
    required this.longitudeDisp,
  });

  factory RegistroPontoModel.fromMap(Map<String, dynamic> map) {
    // Prioriza a coluna da data real da batida; se não existir, usa criado_em
    final rawDataPonto = map['data_hora_ponto'] ??
        map['data_hora'] ??
        map['registrado_em'] ??
        map['criado_em'];

    final dataPonto = DateTime.parse(rawDataPonto.toString());
    final dataCriacao = map['criado_em'] != null
        ? DateTime.parse(map['criado_em'].toString())
        : dataPonto;

    return RegistroPontoModel(
      id: map['id']?.toString(),
      usuarioId: map['usuario_id'].toString(),
      dataHoraPonto: dataPonto,
      criadoEm: dataCriacao,
      tipoRegistro: TipoRegistroEnum.fromBanco(
        (map['tipo_registro_ponto'] ?? 'entrada_1').toString(),
      ),
      // Null-safe para não quebrar com dados populados manualmente em testes
      latitudeDisp: (map['latitude_disp'] as num?)?.toDouble() ?? 0.0,
      longitudeDisp: (map['longitude_disp'] as num?)?.toDouble() ?? 0.0,
    );
  }

  Map<String, dynamic> toMap() => {
        if (id != null) 'id': id,
        'usuario_id': usuarioId,
        'tipo_registro_ponto': tipoRegistro.valorBanco,
        'latitude_disp': latitudeDisp,
        'longitude_disp': longitudeDisp,
        'criado_em': criadoEm.toIso8601String(),
      };
}