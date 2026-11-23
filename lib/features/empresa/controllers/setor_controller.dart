import 'package:flutter/foundation.dart';
import '../../../core/utils/executor_async.dart';
import '../models/setor_model.dart';
import '../services/setor_service.dart';

class SetorController extends ChangeNotifier with ExecutorAsync {
  final SetorService _service;

  List<SetorModel> setores = [];

  SetorController({SetorService? service}) : _service = service ?? SetorService();

  Future<void> carregarSetores(String empresaId) => executar(
        () async => setores = await _service.listarSetores(empresaId),
        erroPadrao: 'Erro ao carregar setores.',
      );

  Future<bool> salvarSetor({
    required String id,
    required String empresaId,
    String? gestorId,
    required String nome,
    bool ehEdicao = false,
  }) =>
      executar(() async {
        final setor = SetorModel(
          id: id,
          empresaId: empresaId,
          gestorId: gestorId,
          nome: nome,
        );
        await _service.salvarSetor(setor, ehEdicao: ehEdicao);
        await carregarSetores(empresaId);
      }, erroPadrao: 'Ocorreu um erro inesperado.');

  Future<bool> excluirSetor(String id, String empresaId) => executar(() async {
        await _service.excluirSetor(id);
        await carregarSetores(empresaId);
      }, erroPadrao: 'Erro ao excluir setor.');
}