import '../../../core/errors/app_exception.dart';
import '../models/setor_model.dart';
import '../repositories/setor_repository.dart';


class SetorService {
  final SetorRepository _repository;

  SetorService({SetorRepository? repository}) 
      : _repository = repository ?? SetorRepository();

 Future<SetorModel> salvarSetor(SetorModel setor, {bool ehEdicao = false}) async {
    final nomeTratado = setor.nome.trim();

    if (nomeTratado.isEmpty) {
      throw ValidacaoException('O nome do setor é obrigatório.');
    }
    if (nomeTratado.length < 3) {
      throw ValidacaoException('O nome do setor deve ter pelo menos 3 caracteres.');
    }
    if (setor.empresaId.isEmpty) {
      throw ValidacaoException('O setor precisa estar vinculado a uma empresa.');
    }

    // NOVA VALIDAÇÃO: Bloquear nomes duplicados
    final setoresExistentes = await _repository.listarSetoresPorEmpresa(setor.empresaId);
    final nomeDuplicado = setoresExistentes.any((s) => 
      s.nome.toLowerCase() == nomeTratado.toLowerCase() && s.id != setor.id
    );

    if (nomeDuplicado) {
      throw ValidacaoException('Já existe um setor com este nome nesta empresa.');
    }

    final setorValidado = SetorModel(
      id: setor.id,
      empresaId: setor.empresaId,
      gestorId: setor.gestorId,
      nome: nomeTratado,
    );

    return await _repository.salvarSetor(setorValidado, ehEdicao: ehEdicao);
  }

  // Novo método para excluir
  Future<void> excluirSetor(String id) async {
    await _repository.excluirSetor(id);
  }
  
  Future<List<SetorModel>> listarSetores(String empresaId) async {
    if (empresaId.isEmpty) throw ValidacaoException('Empresa não identificada.');
    return await _repository.listarSetoresPorEmpresa(empresaId);
  }
}