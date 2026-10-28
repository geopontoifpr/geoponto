import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
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
  /// Busca o ID do usuário consumindo o serviço
  Future<String?> obterIdPorEmail(String email) async {
    try {
      // _service é a sua instância de UsuarioService()
      return await _service.obterIdPorEmail(email);
    } catch (e) {
      erroMensagem = e.toString();
      // Não damos notifyListeners() aqui porque é uma chamada em background do fluxo de cadastro
      return null;
    }
  }
  Future<bool> desvincularDispositivo(String usuarioId) async {
    _setLoading(true);
    erroMensagem = null;
    
    try {
      await _service.desvincularDispositivo(usuarioId);
      return true;
    } catch (e) {
      erroMensagem = e.toString();
      return false;
    } finally {
      _setLoading(false);
    }
  }
  Future<bool> atualizarNome(UsuarioModel usuarioAtual, String novoNome) async {
    _setLoading(true);
    erroMensagem = null;

    try {
      if (novoNome.trim() == usuarioAtual.nome) return true;

      // Importe o supabase_flutter caso não esteja importado no controller
      await Supabase.instance.client
          .from('usuarios')
          .update({'nome': novoNome.trim()})
          .eq('id', usuarioAtual.id!);
          
      usuarioAtual.nome = novoNome.trim(); // Atualiza o nome localmente
      return true;
    } catch (e) {
      erroMensagem = 'Erro ao atualizar o nome.';
      return false;
    } finally {
      _setLoading(false);
    }
  }
  
}