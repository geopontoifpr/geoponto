import 'package:flutter/material.dart';
import '../../../core/errors/app_exception.dart';
import '../../usuarios/models/usuario_model.dart';
import '../services/usuario_service.dart';

class UsuarioController extends ChangeNotifier {
  final UsuarioService _service;
  
  bool isLoading = false;
  String? erroMensagem;
  List<UsuarioModel> usuario = [];

  UsuarioController({UsuarioService? service}) : _service = service ?? UsuarioService();

  void _setLoading(bool value) { isLoading = value; notifyListeners(); }

  Future<void> carregarUsuarios(String empresaId) async {
    _setLoading(true);
    erroMensagem = null;
    
    try {
      if (usuarioLogado.tipoUsuario == TipoUsuario.administrador) {
        // O Administrador vê TODOS da empresa
        equipe = await _service.listar(
          empresaId: usuarioLogado.empresaId!,
        );
      } else if (usuarioLogado.tipoUsuario == TipoUsuario.gestor) {
        // O Gestor vê APENAS o seu setor e não vê a si mesmo
        equipe = await _service.listar(
          empresaId: usuarioLogado.empresaId!,
          setorId: usuarioLogado.setorId,
          ignorarUsuarioId: usuarioLogado.id,
        );
      }
    } on AppException catch (e) {
      erroMensagem = e.mensagem;
    } finally {
      _setLoading(false);
    }
  }

  Future<bool> salvarUsuario({
    String? idEdicao,
    required String empresaId,
    required String nome,
    required String email,
    required String tipoUsuario,
    required String? setorId,
  }) async {
    _setLoading(true);
    try {
      await _service.salvarUsuario(
        idEdicao: idEdicao, empresaId: empresaId, nome: nome, 
        email: email, tipoUsuario: tipoUsuario, setorId: setorId
      );
      await carregarUsuarios(empresaId);
      return true;
    } on AppException catch (e) {
      erroMensagem = e.mensagem; return false;
    } catch (e) {
      erroMensagem = 'Ocorreu um erro inesperado.'; return false;
    } finally {
      _setLoading(false);
    }
  }

  // Alteramos para receber o UsuarioModel
  Future<bool> alternarStatus(UsuarioModel usuario, String empresaId) async {
    _setLoading(true);
    erroMensagem = null; // Limpa o erro anterior antes de tentar
    try {
      await _service.alternarStatusAtivo(usuario); // Passa o objeto para o Service
      await carregarUsuarios(empresaId);
      return true;
    } on AppException catch (e) {
      erroMensagem = e.mensagem; 
      return false;
    } finally {
      _setLoading(false);
    }
  }
}