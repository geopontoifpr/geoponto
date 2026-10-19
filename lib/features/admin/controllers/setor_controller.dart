import 'package:flutter/material.dart';
import '../../../core/errors/app_exception.dart';
import '../models/setor_model.dart';
import '../services/setor_service.dart';

class SetorController extends ChangeNotifier {
  final SetorService _service;
  
  bool isLoading = false;
  String? erroMensagem;
  List<SetorModel> setores = []; // Lista que vai alimentar a interface

  SetorController({SetorService? service}) : _service = service ?? SetorService();

  void _setLoading(bool value) {
    isLoading = value;
    notifyListeners();
  }

  Future<void> carregarSetores(String empresaId) async {
    _setLoading(true);
    erroMensagem = null;
    try {
      setores = await _service.listarSetores(empresaId);
    } on AppException catch (e) {
      erroMensagem = e.mensagem;
    } catch (e) {
      erroMensagem = 'Erro ao carregar setores.';
    } finally {
      _setLoading(false);
    }
  }

  Future<bool> salvarSetor({
    required String id,
    required String empresaId,
    String? gestorId,
    required String nome,
    bool ehEdicao = false,
  }) async {
    _setLoading(true);
    erroMensagem = null;

    try {
      final setor = SetorModel(id: id, empresaId: empresaId, gestorId: gestorId, nome: nome);
      await _service.salvarSetor(setor, ehEdicao: ehEdicao);
      
      await carregarSetores(empresaId); // Recarrega a lista após salvar
      return true; 
    } on AppException catch (e) {
      erroMensagem = e.mensagem;
      return false;
    } catch (e) {
      erroMensagem = 'Ocorreu um erro inesperado.';
      return false;
    } finally {
      _setLoading(false);
    }
  }

  Future<bool> excluirSetor(String id, String empresaId) async {
    _setLoading(true);
    erroMensagem = null;
    try {
      await _service.excluirSetor(id);
      await carregarSetores(empresaId); // Recarrega a lista após deletar
      return true;
    } on AppException catch (e) {
      erroMensagem = e.mensagem;
      return false;
    } catch (e) {
      erroMensagem = 'Erro ao excluir setor.';
      return false;
    } finally {
      _setLoading(false);
    }
  }
}