import '../repositories/jornada_repository.dart';
import '../models/jornada_trabalho_model.dart';
import '../models/jornada_usuario_model.dart';
import '../../../core/errors/app_exception.dart';

class JornadaService {
  final _repository = JornadaRepository();

  Future<List<JornadaTrabalhoModel>> listarJornadas() async {
    try {
      return await _repository.listarJornadas();
    } catch (e) {
      throw Exception('Erro ao carregar as jornadas de trabalho disponíveis.'); // <-- Corrigido
    }
  }

  Future<void> vincularJornadaUsuario({
    required String usuarioId, 
    required String jornadaId,
    DateTime? dataInicioVigencia,
  }) async {
    try {
      final inicioVigencia = dataInicioVigencia ?? DateTime.now();
      await _repository.salvarJornadaUsuario(
        usuarioId: usuarioId, 
        jornadaId: jornadaId,
        dataInicioVigencia: inicioVigencia,
      );
    } catch (e) {
      throw Exception('Erro ao vincular a jornada de trabalho ao usuário.'); // <-- Corrigido
    }
  }
  
  Future<JornadaUsuarioModel?> obterJornadaAtualDoUsuario(String usuarioId) async {
    try {
      return await _repository.buscarJornadaUsuario(usuarioId);
    } catch (e) {
      throw Exception('Erro ao buscar a jornada atual do usuário.'); // <-- Corrigido
    }
  }
}