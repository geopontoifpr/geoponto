import 'package:flutter/material.dart';
import '../services/jornada_service.dart';
import '../models/jornada_trabalho_model.dart';

class JornadaController extends ChangeNotifier {
  final _service = JornadaService();

  List<JornadaTrabalhoModel> jornadas = [];
  bool isLoading = false;
  String? erroMensagem;

  /// Carrega a lista de jornadas disponíveis para preencher o Dropdown
  Future<void> carregarJornadas() async {
    isLoading = true;
    erroMensagem = null;
    notifyListeners();

    try {
      jornadas = await _service.listarJornadas();
    } catch (e) {
      erroMensagem = e.toString();
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  /// Vincula a jornada selecionada ao usuário no banco de dados
  Future<bool> salvarJornadaUsuario(String usuarioId, String jornadaId) async {
    // Não alteramos o isLoading global aqui para não travar a tela inteira de cadastro,
    // apenas retornamos sucesso ou falha.
    try {
      await _service.vincularJornadaUsuario(
        usuarioId: usuarioId, 
        jornadaId: jornadaId,
      );
      return true;
    } catch (e) {
      erroMensagem = e.toString();
      notifyListeners();
      return false;
    }
  }
  
  /// Busca o ID da jornada atual vinculada ao usuário (usado ao editar um membro da equipe)
  Future<String?> buscarJornadaSelecionada(String usuarioId) async {
    try {
      final jornadaAtual = await _service.obterJornadaAtualDoUsuario(usuarioId);
      return jornadaAtual?.jornadaId;
    } catch (e) {
      erroMensagem = e.toString();
      // Não damos notifyListeners aqui para não repintar a tela enquanto ela inicializa
      return null;
    }
  }
}