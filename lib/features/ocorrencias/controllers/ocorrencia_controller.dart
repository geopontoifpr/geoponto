import 'package:flutter/foundation.dart';
import '../../../core/utils/executor_async.dart';
import '../../usuarios/models/usuario_model.dart';
import '../models/ocorrencia_model.dart';
import '../services/ocorrencia_service.dart';

class OcorrenciaController extends ChangeNotifier with ExecutorAsync {
  final OcorrenciaService _service;
  // novos campos
  DateTime mesReferencia = DateTime(DateTime.now().year, DateTime.now().month, 1);
  int _requisicaoAtual = 0;

  OcorrenciaController({OcorrenciaService? service})
      : _service = service ?? OcorrenciaService();

  List<OcorrenciaModel> ocorrenciasDoMes = [];
  List<UsuarioModel> pessoasComPendencias = [];
  List<OcorrenciaModel> ocorrenciasDaPessoa = [];
  UsuarioModel? pessoaSelecionada;

  List<TipoOcorrenciaEnum> get tiposOcorrencia => TipoOcorrenciaEnum.values; 

  Future<void> carregarPessoasComPendencias(UsuarioModel usuarioLogado) {
    pessoaSelecionada = null;
    ocorrenciasDaPessoa = [];
    pessoasComPendencias = [];
    return executar(() async {
      pessoasComPendencias = await _service.listarPessoasComPendencias(
        usuarioLogado: usuarioLogado,       
      );
    }, erroPadrao: 'Erro ao carregar pessoas com ocorrências pendentes.');
  }

  Future<void> selecionarPessoa({
  required UsuarioModel usuarioLogado,
  required UsuarioModel pessoa,
  DateTime? mes, // opcional: se null, mantém o mês atual do controller
  }) {
    pessoaSelecionada = pessoa;
    if (mes != null) mesReferencia = DateTime(mes.year, mes.month, 1);
    ocorrenciasDaPessoa = [];

    return executar(() async {
      final id = ++_requisicaoAtual;
      final lista = await _service.listarOcorrenciasDaPessoa(
        usuarioLogado: usuarioLogado,
        pessoa: pessoa,
        ano: mesReferencia.year,
        mes: mesReferencia.month,
      );
      if (id != _requisicaoAtual) return; // resposta de um mês antigo: descarta
      ocorrenciasDaPessoa = lista;
    }, erroPadrao: 'Erro ao carregar ocorrências da pessoa selecionada.');
  }

  void voltarParaPessoas() {
    pessoaSelecionada = null;
    ocorrenciasDaPessoa = [];
    erroMensagem = null;
    mesReferencia = DateTime(DateTime.now().year, DateTime.now().month, 1);
    notifyListeners();
  }

 
  Future<void> carregarDoMes(
    String usuarioId,
    DateTime mes, {
    required UsuarioModel usuarioLogado,
  }) {
    ocorrenciasDoMes = [];
    return executar(() async {
      final lista = await _service.listarOcorrenciasConsultadas(
        usuarioLogado: usuarioLogado,
        usuarioId: usuarioId,
        ano: mes.year,
        mes: mes.month,
      );
      lista.sort((a, b) => b.dataInicio.compareTo(a.dataInicio));
      ocorrenciasDoMes = lista;
    }, erroPadrao: 'Erro ao carregar ocorrências.');
  }

  // ───────────── Escrita (usam `salvando`) ─────────────

  Future<bool> salvarOcorrencia({
    String? idEdicao,
    required String usuarioId,
    required DateTime dataReferencia,
    required TipoOcorrenciaEnum? tipoSelecionado,
    required String justificativa,
    required String minutosTexto,
  }) =>
      executar(
        () => _service.salvarOcorrencia(
          idEdicao: idEdicao,
          usuarioId: usuarioId,
          dataReferencia: dataReferencia,
          tipoOcorrencia: tipoSelecionado,
          justificativa: justificativa,
          minutosSolicitados: int.tryParse(minutosTexto.trim()) ?? 0,
        ),
        salvar: true,
        erroPadrao: 'Erro inesperado ao salvar ocorrência.',
      );

  Future<bool> excluirOcorrencia(OcorrenciaModel ocorrencia) => executar(
        () => _service.excluirOcorrencia(ocorrencia),
        salvar: true,
        erroPadrao: 'Erro ao excluir ocorrência.',
      );

  Future<bool> avaliarOcorrencia({
    required OcorrenciaModel ocorrencia,
    required bool aprovar,
    required UsuarioModel usuarioLogado,
    required UsuarioModel pessoaSelecionada,
    String? observacaoGestor,
  }) =>
      executar(() async {
        await _service.avaliarOcorrencia(
          ocorrencia: ocorrencia,
          aprovar: aprovar,
          pessoaSelecionada: pessoaSelecionada,
          observacaoGestor: observacaoGestor,
        );
        await selecionarPessoa(
          usuarioLogado: usuarioLogado,
          pessoa: pessoaSelecionada,
        );
      }, salvar: true, erroPadrao: 'Erro ao processar avaliação da ocorrência.');

  Future<bool> reabrirOcorrencia({
    required OcorrenciaModel ocorrencia,
    required UsuarioModel usuarioLogado,
    required UsuarioModel pessoaSelecionada,
  }) =>
      executar(() async {
        await _service.reabrirOcorrencia(
          ocorrencia: ocorrencia,
          pessoaSelecionada: pessoaSelecionada,
        );
        await selecionarPessoa(
          usuarioLogado: usuarioLogado,
          pessoa: pessoaSelecionada,
        );
      }, salvar: true, erroPadrao: 'Erro ao reabrir ocorrência.');
}