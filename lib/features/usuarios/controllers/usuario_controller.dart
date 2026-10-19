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

  Future<void> carregarUsuarios(UsuarioModel usuarioLogado, String empresaId) async {
    _setLoading(true);
    erroMensagem = null;
    
    try {    

      if (usuarioLogado.tipoUsuario == TipoUsuario.administrador) {
        // Administrador vê TODOS da empresa
        usuario = await _service.listarUsuarios(
          empresaId: empresaId,
        );
      } else if (usuarioLogado.tipoUsuario == TipoUsuario.gestor) {
        // Gestor vê o seu setor e a query exclui ele mesmo
        
        usuario = await _service.listarUsuarios(
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
    required UsuarioModel usuarioLogado,
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
      await carregarUsuarios(usuarioLogado, empresaId); // Recarrega a lista após salvar
      return true;
    } on AppException catch (e) {
      erroMensagem = e.mensagem; return false;
    } catch (e) {
      erroMensagem = 'Ocorreu um erro inesperado.'; return false;
    } finally {
      _setLoading(false);
    }
  }

  Future<bool> alternarStatus(UsuarioModel membro, UsuarioModel usuarioLogado) async {
    _setLoading(true);
    erroMensagem = null;
    
    try {
      // 1. Chama a Service (que vai validar a regra do Gestor que você acabou de criar)
      await _service.alternarStatusAtivo(membro);
      
      // 2. Se não lançou exceção (ValidacaoException), recarrega a lista atualizada
      await carregarUsuarios(usuarioLogado, membro.empresaId!); 
      return true;
      
    } on AppException catch (e) {
      // Captura o erro "O setor selecionado já possui um Gestor..." e exibe na tela
      erroMensagem = e.mensagem;
      return false;
    } finally {
      _setLoading(false);
    }
  }
}