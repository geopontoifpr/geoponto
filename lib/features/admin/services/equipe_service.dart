import '../../../core/errors/app_exception.dart';
import '../../usuarios/models/usuario_model.dart';
import '../repositories/equipe_repository.dart';

class EquipeService {
  final EquipeRepository _repository;

  EquipeService({EquipeRepository? repository}) : _repository = repository ?? EquipeRepository();

  Future<List<UsuarioModel>> listar(String empresaId) async {
    return await _repository.listarEquipe(empresaId);
  }

  Future<void> salvarMembro({
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

    if (idEdicao == null) {
      // CRIAÇÃO
      await _repository.criarMembro({
        'nome': nome.trim(),
        'email': email.trim().toLowerCase(),
        'tipo_usuario': tipoUsuario,
        'empresa_id': empresaId,
        'setor_id': setorId,
      });
    } else {
      // EDIÇÃO
      await _repository.atualizarMembro(idEdicao, {
        'nome': nome.trim(),
        'tipo_usuario': tipoUsuario,
        'setor_id': setorId,
      });
    }
  }

  // Soft Delete: Apenas inativa o usuário para não quebrar o histórico de ponto
  Future<void> alternarStatusAtivo(String id, bool statusAtual) async {
    await _repository.atualizarMembro(id, {'ativo': !statusAtual});
  }
}