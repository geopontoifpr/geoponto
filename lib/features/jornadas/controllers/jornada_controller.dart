import 'package:flutter/foundation.dart';
import '../../../core/utils/executor_async.dart';
import '../models/jornada_trabalho_model.dart';
import '../services/jornada_service.dart';

class JornadaController extends ChangeNotifier with ExecutorAsync {
  final _service = JornadaService();

  List<JornadaTrabalhoModel> jornadas = [];

  /// Carrega as jornadas para o Dropdown.
  Future<void> carregarJornadas() => executar(
        () async => jornadas = await _service.listarJornadas(),
      );

  /// Não liga o loading global para não travar a tela de cadastro.
  Future<bool> salvarJornadaUsuario(String usuarioId, String jornadaId) =>
      executar(
        () => _service.vincularJornadaUsuario(
          usuarioId: usuarioId,
          jornadaId: jornadaId,
        ),
        mostrarCarregando: false,
      );

  /// ID da jornada vigente do usuário (usado ao editar um membro).
  /// Não notifica para não repintar a tela enquanto ela inicializa.
  Future<String?> buscarJornadaSelecionada(String usuarioId) async {
    try {
      final atual = await _service.obterJornadaAtualDoUsuario(usuarioId);
      return atual?.jornadaId;
    } catch (e) {
      erroMensagem = mensagemDeErro(e, null);
      return null;
    }
  }
}