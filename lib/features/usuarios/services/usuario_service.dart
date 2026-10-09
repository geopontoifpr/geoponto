import '../../../core/errors/app_exception.dart';
import '../../usuarios/models/usuario_model.dart';
import '../repositories/usuario_repository.dart';

class UsuarioService {
  final UsuarioRepository _repository;

  UsuarioService({UsuarioRepository? repository}) : _repository = repository ?? UsuarioRepository();

  Future<List<UsuarioModel>> listar(String empresaId) async {
    return await _repository.listarUsuarios(empresaId);
  }

  Future<void> salvarUsuario({
    String? idEdicao,
    required String empresaId,
    required String nome,
    required String email,
    required String tipoUsuario,
    required String? setorId,
  }) async {
    if (nome.trim().length < 3) throw ValidacaoException('Nome muito curto.');
    if (!email.contains('@')) throw ValidacaoException('E-mail inválido.');
    if (setorId == null || setorId.isEmpty) throw ValidacaoException('Selecione um setor.');

    if (tipoUsuario == 'GESTOR' && setorId != null) {
      final setorOcupado = await _repository.verificarSeSetorTemGestor(setorId, ignorarId: idEdicao);
      if (setorOcupado) {
        throw ValidacaoException('Este setor já possui um Gestor responsável vinculado a ele.');
      }
    }

    if (idEdicao == null) {
      // CRIAÇÃO (A RPC cuidará disso, veja o Passo 3)
      await _repository.criarUsuario({
        'nome': nome.trim(),
        'email': email.trim().toLowerCase(),
        'tipo_usuario': tipoUsuario,
        'empresa_id': empresaId,
        'setor_id': setorId,
      });
    } else {
      // EDIÇÃO
      await _repository.atualizarUsuario(idEdicao, {
        'nome': nome.trim(),
        'tipo_usuario': tipoUsuario,
        'setor_id': setorId,
      });

      // --- A MÁGICA DA SINCRONIA NO DART ---
      // 1. Sempre limpamos o vínculo antigo desse usuário primeiro para evitar sujeira
      await _repository.removerGestorDosSetores(idEdicao);

      // 2. Se ele foi salvo como GESTOR, vinculamos o ID dele ao novo setor!
      if (tipoUsuario == 'GESTOR') {
        await _repository.vincularGestorAoSetor(setorId, idEdicao);
      }
    }
  }

  // Soft Delete atualizado com a sincronia de Gestor
  Future<void> alternarStatusAtivo(UsuarioModel usuario) async {
    final novoStatus = !usuario.ativo;

    if (novoStatus == true && usuario.tipoUsuario.name.toUpperCase() == 'GESTOR' && usuario.setorId != null) {
      final setorOcupado = await _repository.verificarSeSetorTemGestor(usuario.setorId!, ignorarId: usuario.id);
      if (setorOcupado) {
        throw ValidacaoException('O setor selecionado já possui um Gestor vinculado. Altere o gestor atual primeiro.');
      }
    }

    // Atualiza o status do usuário no banco
    await _repository.atualizarUsuario(usuario.id, {'ativo': novoStatus});

    // --- A MÁGICA DA SINCRONIA NO DART (Status) ---
    if (usuario.tipoUsuario.name.toUpperCase() == 'GESTOR') {
      if (novoStatus == false) {
        // Se inativou, tira ele da chefia
        await _repository.removerGestorDosSetores(usuario.id);
      } else if (novoStatus == true && usuario.setorId != null) {
        // Se reativou, coloca ele de volta na chefia
        await _repository.vincularGestorAoSetor(usuario.setorId!, usuario.id);
      }
    }
  }
}