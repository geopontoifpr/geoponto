import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/utils/executor_async.dart';
import '../models/usuario_model.dart';
import '../services/usuario_service.dart';

class UsuarioController extends ChangeNotifier with ExecutorAsync {
  final UsuarioService _service;

  List<UsuarioModel> usuario = [];

  UsuarioController({UsuarioService? service})
      : _service = service ?? UsuarioService();

  Future<void> carregarUsuarios(UsuarioModel logado, String empresaId) =>
      executar(() async {
        switch (logado.tipoUsuario) {
          case TipoUsuario.administrador:
            usuario = await _service.listarUsuarios(empresaId: empresaId);
          case TipoUsuario.gestor:
            usuario = await _service.listarUsuarios(
              empresaId: logado.empresaId!,
              setorId: logado.setorId,
              ignorarUsuarioId: logado.id,
            );
          case TipoUsuario.funcionario:
            break;
        }
      }, erroPadrao: 'Erro ao carregar a equipe.');

  Future<bool> salvarUsuario({
    String? idEdicao,
    required String empresaId,
    required UsuarioModel usuarioLogado,
    required String nome,
    required String cpf,
    required String email,
    required String tipoUsuario,
    required String? setorId,
  }) =>
      executar(() async {
        await _service.salvarUsuario(
          idEdicao: idEdicao,
          empresaId: empresaId,
          nome: nome,
          cpf: cpf,
          email: email,
          tipoUsuario: tipoUsuario,
          setorId: setorId,
        );
        await carregarUsuarios(usuarioLogado, empresaId);
      }, erroPadrao: 'Ocorreu um erro inesperado.');

  Future<bool> alternarStatus(UsuarioModel membro, UsuarioModel usuarioLogado) =>
      executar(() async {
        await _service.alternarStatusAtivo(membro);
        await carregarUsuarios(usuarioLogado, membro.empresaId!);
      }, erroPadrao: 'Erro ao alterar o status do usuário.');

  Future<bool> desvincularDispositivo(String usuarioId) =>
      executar(() => _service.desvincularDispositivo(usuarioId));

  Future<bool> atualizarNome(UsuarioModel usuarioAtual, String novoNome) {
    final nome = novoNome.trim();
    if (nome == usuarioAtual.nome) return Future.value(true);

    return executar(() async {
      // Idealmente isto iria para UsuarioService/UsuarioRepository.
      await Supabase.instance.client
          .from('usuarios')
          .update({'nome': nome})
          .eq('id', usuarioAtual.id);
      usuarioAtual.nome = nome; // atualiza o objeto em memória
    }, erroPadrao: 'Erro ao atualizar o nome.');
  }

  /// Chamada em segundo plano no cadastro: não notifica a tela.
  Future<String?> obterIdPorEmail(String email) async {
    try {
      return await _service.obterIdPorEmail(email);
    } catch (e) {
      erroMensagem = mensagemDeErro(e, null);
      return null;
    }
  }
}