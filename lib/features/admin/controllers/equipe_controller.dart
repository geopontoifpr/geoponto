import 'package:flutter/material.dart';
import '../../../core/errors/app_exception.dart';
import '../../usuarios/models/usuario_model.dart';
import '../services/equipe_service.dart';

class EquipeController extends ChangeNotifier {
  final EquipeService _service;
  
  bool isLoading = false;
  String? erroMensagem;
  List<UsuarioModel> equipe = [];

  EquipeController({EquipeService? service}) : _service = service ?? EquipeService();

  void _setLoading(bool value) { isLoading = value; notifyListeners(); }

  Future<void> carregarEquipe(String empresaId) async {
    _setLoading(true);
    erroMensagem = null;
    try {
      equipe = await _service.listar(empresaId);
    } on AppException catch (e) {
      erroMensagem = e.mensagem;
    } finally {
      _setLoading(false);
    }
  }

  Future<bool> salvarMembro({
    String? idEdicao,
    required String empresaId,
    required String nome,
    required String email,
    required String tipoUsuario,
    required String? setorId,
  }) async {
    _setLoading(true);
    try {
      await _service.salvarMembro(
        idEdicao: idEdicao, empresaId: empresaId, nome: nome, 
        email: email, tipoUsuario: tipoUsuario, setorId: setorId
      );
      await carregarEquipe(empresaId);
      return true;
    } on AppException catch (e) {
      erroMensagem = e.mensagem; return false;
    } catch (e) {
      erroMensagem = 'Ocorreu um erro inesperado.'; return false;
    } finally {
      _setLoading(false);
    }
  }

  Future<bool> alternarStatus(String id, bool statusAtual, String empresaId) async {
    _setLoading(true);
    try {
      await _service.alternarStatusAtivo(id, statusAtual);
      await carregarEquipe(empresaId);
      return true;
    } on AppException catch (e) {
      erroMensagem = e.mensagem; return false;
    } finally {
      _setLoading(false);
    }
  }
}