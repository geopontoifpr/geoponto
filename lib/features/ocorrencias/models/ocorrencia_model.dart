class OcorrenciaModel {
  final String? id;
  final String usuarioId;
  final String gestorId;
  final DateTime dataInicio;
  final DateTime? dataFim;
  final int? minutosAbonados;
  final String tipoOcorrencia;
  final String justificativa;
  final String? horarioProposto;
  final bool aprovada;
  final String? observacaoGestor;
  final DateTime? criadoEm;

  OcorrenciaModel({
    this.id,
    required this.usuarioId,
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

  factory OcorrenciaModel.fromMap(Map<String, dynamic> map) {
    return OcorrenciaModel(
      id: map['id']?.toString(),
      usuarioId: map['usuario_id'].toString(),
      gestorId: map['gestor_id'].toString(),
      dataInicio: DateTime.parse(map['data_inicio'].toString()),
      dataFim: map['data_fim'] != null ? DateTime.parse(map['data_fim'].toString()) : null,
      minutosAbonados: map['minutos_abonados'] as int?,
      tipoOcorrencia: map['tipo_ocorrencia'].toString(),
      justificativa: map['justificativa'].toString(),
      horarioProposto: map['horario_proposto']?.toString(),
      aprovada: map['aprovada'] as bool? ?? false,
      observacaoGestor: map['observacao_gestor']?.toString(),
      criadoEm: map['criado_em'] != null ? DateTime.parse(map['criado_em'].toString()).toLocal() : null,
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
      'tipo_ocorrencia': tipoOcorrencia,
      'justificativa': justificativa,
      if (horarioProposto != null) 'horario_proposto': horarioProposto,
      'aprovada': aprovada,
      if (observacaoGestor != null) 'observacao_gestor': observacaoGestor,
    };
  }
}