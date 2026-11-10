import 'package:flutter/foundation.dart';
import '../../../core/errors/app_exception.dart';
import '../../usuarios/models/usuario_model.dart';
import '../models/ocorrencia_model.dart';
import '../services/ocorrencia_service.dart';

class OcorrenciaController extends ChangeNotifier {
  final OcorrenciaService _service;

  OcorrenciaController({OcorrenciaService? service})
      : _service = service ?? OcorrenciaService();

  bool carregando = false;
  bool salvando = false;
  String? erroMensagem;
  List<OcorrenciaModel> ocorrenciasDoMes = [];
  List<OcorrenciaModel> ocorrenciasGestor = [];
  List<UsuarioModel> pessoasComPendencias = [];
  List<OcorrenciaModel> ocorrenciasDaPessoa = [];
  UsuarioModel? pessoaSelecionada;

  List<TipoOcorrenciaEnum> get tiposOcorrencia => TipoOcorrenciaEnum.values;

  int get quantidadePendentes =>
      ocorrenciasGestor.where((oc) => oc.isPendente).length;

  Future<void> carregarPessoasComPendencias(UsuarioModel usuarioLogado) async {
    carregando = true;
    erroMensagem = null;
    pessoaSelecionada = null;
    ocorrenciasDaPessoa = [];
    pessoasComPendencias = [];
    notifyListeners();

    try {
      pessoasComPendencias = await _service.listarPessoasComPendencias(
        usuarioLogado: usuarioLogado,
      );
    } on AppException catch (e) {
      erroMensagem = e.mensagem;
    } catch (_) {
      erroMensagem = 'Erro ao carregar pessoas com ocorrências pendentes.';
    } finally {
      carregando = false;
      notifyListeners();
    }
  }

  Future<void> selecionarPessoa({
    required UsuarioModel usuarioLogado,
    required UsuarioModel pessoa,
  }) async {
    carregando = true;
    erroMensagem = null;
    pessoaSelecionada = pessoa;
    ocorrenciasDaPessoa = [];
    notifyListeners();

    try {
      ocorrenciasDaPessoa = await _service.listarOcorrenciasDaPessoa(
        usuarioLogado: usuarioLogado,
        pessoa: pessoa,
      );
    } on AppException catch (e) {
      erroMensagem = e.mensagem;
    } catch (_) {
      erroMensagem = 'Erro ao carregar ocorrências da pessoa selecionada.';
    } finally {
      carregando = false;
      notifyListeners();
    }
  }

  void voltarParaPessoas() {
    pessoaSelecionada = null;
    ocorrenciasDaPessoa = [];
    erroMensagem = null;
    notifyListeners();
  }

  Future<void> carregarOcorrenciasGestor(String gestorId) async {
    carregando = true;
    erroMensagem = null;
    notifyListeners();

    try {
      ocorrenciasGestor = await _service.listarPorGestor(gestorId);
    } on AppException catch (e) {
      erroMensagem = e.mensagem;
    } catch (_) {
      erroMensagem = 'Erro ao carregar ocorrências da equipe.';
    } finally {
      carregando = false;
      notifyListeners();
    }
  }

  Future<bool> salvarOcorrencia({
    String? idEdicao,
    required String usuarioId,
    required DateTime dataReferencia,
    required TipoOcorrenciaEnum? tipoSelecionado,
    required String justificativa,
    required String minutosTexto,
  }) async {
    salvando = true;
    erroMensagem = null;
    notifyListeners();

    try {
      final minutos = int.tryParse(minutosTexto.trim()) ?? 0;
      await _service.salvarOcorrencia(
        idEdicao: idEdicao,
        usuarioId: usuarioId,
        dataReferencia: dataReferencia,
        tipoOcorrencia: tipoSelecionado,
        justificativa: justificativa,
        minutosSolicitados: minutos,
      );
      return true;
    } on AppException catch (e) {
      erroMensagem = e.mensagem;
      return false;
    } catch (_) {
      erroMensagem = 'Erro inesperado ao salvar ocorrência.';
      return false;
    } finally {
      salvando = false;
      notifyListeners();
    }
  }

  Future<bool> excluirOcorrencia(OcorrenciaModel ocorrencia) async {
    salvando = true;
    erroMensagem = null;
    notifyListeners();

    try {
      await _service.excluirOcorrencia(ocorrencia);
      return true;
    } on AppException catch (e) {
      erroMensagem = e.mensagem;
      return false;
    } catch (_) {
      erroMensagem = 'Erro ao excluir ocorrência.';
      return false;
    } finally {
      salvando = false;
      notifyListeners();
    }
  }

  Future<bool> avaliarOcorrencia({
    required OcorrenciaModel ocorrencia,
    required bool aprovar,
    required UsuarioModel usuarioLogado,
    required UsuarioModel pessoaSelecionada,
    String? observacaoGestor,
  }) async {
    salvando = true;
    erroMensagem = null;
    notifyListeners();

    try {
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
      return true;
    } on AppException catch (e) {
      erroMensagem = e.mensagem;
      return false;
    } catch (_) {
      erroMensagem = 'Erro ao processar avaliação da ocorrência.';
      return false;
    } finally {
      salvando = false;
      notifyListeners();
    }
  }

  Future<bool> reabrirOcorrencia({
    required OcorrenciaModel ocorrencia,
    required UsuarioModel usuarioLogado,
    required UsuarioModel pessoaSelecionada,
  }) async {
    salvando = true;
    erroMensagem = null;
    notifyListeners();
    try {
      await _service.reabrirOcorrencia(
        ocorrencia: ocorrencia,
        pessoaSelecionada: pessoaSelecionada,
      );
      await selecionarPessoa(
        usuarioLogado: usuarioLogado,
        pessoa: pessoaSelecionada,
      );
      return true;
    } on AppException catch (e) {
      erroMensagem = e.mensagem;
      return false;
    } catch (_) {
      erroMensagem = 'Erro ao reabrir ocorrência.';
      return false;
    } finally {
      salvando = false;
      notifyListeners();
    }
  }

  Future<void> carregarDoMes(
    String usuarioId,
    DateTime mes, {
    required UsuarioModel usuarioLogado,
  }) async {
    carregando = true;
    erroMensagem = null;
    notifyListeners();

    try {
      final lista = await _service.listarOcorrenciasConsultadas(
        usuarioLogado: usuarioLogado,
        usuarioId: usuarioId,
        ano: mes.year,
        mes: mes.month,
      );
      lista.sort((a, b) => b.dataInicio.compareTo(a.dataInicio));
      ocorrenciasDoMes = lista;
    } on AppException catch (e) {
      erroMensagem = e.mensagem;
      ocorrenciasDoMes = [];
    } catch (_) {
      erroMensagem = 'Erro ao carregar ocorrências.';
      ocorrenciasDoMes = [];
    } finally {
      carregando = false;
      notifyListeners();
    }
  }
}
