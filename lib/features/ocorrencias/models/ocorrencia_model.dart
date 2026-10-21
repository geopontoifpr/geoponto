enum TipoOcorrenciaEnum {
  esquecimento('esquecimento', 'Esquecimento de registro'),
  atraso('atraso', 'Atraso'),
  falta('falta', 'Falta justificada'),
  saidaAntecipada('saida_antecipada', 'Saída antecipada'),
  erroRegistro('erro_registro', 'Erro no registro'),
  abono('abono', 'Pedido de abono / Atestado');

  final String valorBanco;
  final String titulo;

  const TipoOcorrenciaEnum(this.valorBanco, this.titulo);

  factory TipoOcorrenciaEnum.fromBanco(String valor) {
    final limpo = valor.trim().toLowerCase();
    for (final tipo in TipoOcorrenciaEnum.values) {
      if (tipo.valorBanco.toLowerCase() == limpo ||
          tipo.name.toLowerCase() == limpo) {
        return tipo;
      }
    }
    return TipoOcorrenciaEnum.esquecimento;
  }
}

class OcorrenciaModel {
  final String? id;
  final String usuarioId;
  final String? nomeUsuario; // Preenchido no join para a tela do gestor
  final String gestorId;
  final DateTime dataInicio;
  final DateTime? dataFim;
  final int? minutosAbonados;
  final TipoOcorrenciaEnum tipoOcorrencia;
  final String justificativa;
  final String? horarioProposto; // Formato TIME no banco: 'HH:mm:ss'
  final bool aprovada;
  final String? observacaoGestor;
  final DateTime? criadoEm;

  OcorrenciaModel({
    this.id,
    required this.usuarioId,
    this.nomeUsuario,
    required this.gestorId,
    required this.dataInicio,
    this.dataFim,
    this.minutosAbonados,
    required this.tipoOcorrencia,
    required this.justificativa,
    this.horarioProposto,
    this.aprovada = false,
    this.observacaoGestor,
    this.criadoEm,
  });

  /// Quando criada, aprovada é false e minutosAbonados é null.
  /// Quando recusada pelo gestor, aprovada continua false e minutosAbonados vira 0.
  bool get foiAvaliada =>
      aprovada ||
      minutosAbonados != null ||
      (observacaoGestor != null && observacaoGestor!.trim().isNotEmpty);

  bool get isPendente => !foiAvaliada;
  bool get isRecusada => foiAvaliada && !aprovada;

  /// Converte 'HH:mm:ss' de horario_proposto em total de minutos (int)
  int get minutosPropostos {
    if (horarioProposto == null || horarioProposto!.trim().isEmpty) return 0;
    final partes = horarioProposto!.split(':');
    if (partes.length >= 2) {
      final h = int.tryParse(partes[0]) ?? 0;
      final m = int.tryParse(partes[1]) ?? 0;
      return (h * 60) + m;
    }
    return int.tryParse(horarioProposto!) ?? 0;
  }

  /// Formata minutos inteiros (ex: 90) para TIME do Postgres ('01:30:00')
  static String formatarMinutosParaTime(int minutos) {
    final mTotal = minutos.clamp(0, 1439);
    final h = (mTotal ~/ 60).toString().padLeft(2, '0');
    final m = (mTotal % 60).toString().padLeft(2, '0');
    return '$h:$m:00';
  }

  factory OcorrenciaModel.fromMap(Map<String, dynamic> map) {
    String? nomeJoin;
    if (map['usuarios'] is Map) {
      nomeJoin = map['usuarios']['nome']?.toString();
    }

    return OcorrenciaModel(
      id: map['id']?.toString(),
      usuarioId: map['usuario_id'].toString(),
      nomeUsuario: nomeJoin,
      gestorId: map['gestor_id'].toString(),
      dataInicio: DateTime.parse(map['data_inicio'].toString()),
      dataFim: map['data_fim'] != null
          ? DateTime.parse(map['data_fim'].toString())
          : null,
      minutosAbonados: (map['minutos_abonados'] as num?)?.toInt(),
      tipoOcorrencia:
          TipoOcorrenciaEnum.fromBanco(map['tipo_ocorrencia'].toString()),
      justificativa: map['justificativa']?.toString() ?? '',
      horarioProposto: map['horario_proposto']?.toString(),
      aprovada: map['aprovada'] as bool? ?? false,
      observacaoGestor: map['observacao_gestor']?.toString(),
      criadoEm: map['criado_em'] != null
          ? DateTime.parse(map['criado_em'].toString()).toLocal()
          : null,
    );
  }

  Map<String, dynamic> toInsertMap() {
    String formatDate(DateTime d) =>
        '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

    return {
      'usuario_id': usuarioId,
      'gestor_id': gestorId,
      'data_inicio': formatDate(dataInicio),
      if (dataFim != null) 'data_fim': formatDate(dataFim!),
      if (minutosAbonados != null) 'minutos_abonados': minutosAbonados,
      'tipo_ocorrencia': tipoOcorrencia.valorBanco,
      'justificativa': justificativa,
      if (horarioProposto != null) 'horario_proposto': horarioProposto,
      'aprovada': aprovada,
      if (observacaoGestor != null) 'observacao_gestor': observacaoGestor,
    };
  }
}