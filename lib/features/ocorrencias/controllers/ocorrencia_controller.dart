import 'package:flutter/foundation.dart';
import '../../../core/errors/app_exception.dart';
import '../services/ocorrencia_service.dart';

class OcorrenciaController extends ChangeNotifier {
  final OcorrenciaService _service;

  OcorrenciaController({OcorrenciaService? service})
      : _service = service ?? OcorrenciaService();

  bool salvando = false;
  String? erroMensagem;

  Map<String, String> get tiposOcorrencia => OcorrenciaService.tiposOcorrencia;

  Future<bool> salvarOcorrencia({
    required String usuarioId,
    required DateTime dataReferencia,
    required String? tipoSelecionado,
    required String assunto,
    required String observacoes,
  }) async {
    salvando = true;
    erroMensagem = null;
    notifyListeners();

    try {
      await _service.registrarOcorrencia(
        usuarioId: usuarioId,
        dataReferencia: dataReferencia,
        tipoOcorrencia: tipoSelecionado,
        assunto: assunto,
        observacoes: observacoes,
      );
      return true;
    } on AppException catch (e) {
      erroMensagem = e.mensagem;
      return false;
    } catch (e) {
      erroMensagem = 'Erro inesperado ao registrar ocorrência.';
      return false;
    } finally {
      salvando = false;
      notifyListeners();
    }
  }
}