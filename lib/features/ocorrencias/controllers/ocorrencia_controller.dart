import 'package:flutter/foundation.dart';
import '../../../core/errors/app_exception.dart';
import '../models/ocorrencia_model.dart';
import '../services/ocorrencia_service.dart';

class OcorrenciaController extends ChangeNotifier {
  final OcorrenciaService _service;

  OcorrenciaController({OcorrenciaService? service})
      : _service = service ?? OcorrenciaService();

  bool carregando = false;
  bool salvando = false;
  String? erroMensagem;

  List<OcorrenciaModel> ocorrenciasGestor = [];

  List<TipoOcorrenciaEnum> get tiposOcorrencia => TipoOcorrenciaEnum.values;

  int get quantidadePendentes =>
      ocorrenciasGestor.where((oc) => oc.isPendente).length;

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
    String? observacaoGestor,
    required String gestorId,
  }) async {
    salvando = true;
    erroMensagem = null;
    notifyListeners();

    try {
      await _service.avaliarOcorrencia(
        ocorrencia: ocorrencia,
        aprovar: aprovar,
        observacaoGestor: observacaoGestor,
      );
      await carregarOcorrenciasGestor(gestorId);
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
}