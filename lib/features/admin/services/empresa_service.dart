import '../../../core/errors/app_exception.dart';
import '../models/empresa_model.dart';
import '../repositories/admin_repository.dart';

class EmpresaService {
  final AdminRepository _repository;

  EmpresaService({AdminRepository? repository}) 
      : _repository = repository ?? AdminRepository();

  Future<EmpresaModel> salvarEmpresa(EmpresaModel empresa, {bool ehEdicao = false}) async {
    // Validação de CNPJ
    final cnpjLimpo = empresa.cnpj?.replaceAll(RegExp(r'[^0-9]'), '') ?? '';
    if (cnpjLimpo.length != 14) {
      throw const ValidacaoException('CNPJ inválido. Digite exatamente 14 números.');
    }

    // Validação GPS
    if (empresa.latitude != null && (empresa.latitude! < -90 || empresa.latitude! > 90)) {
      throw const ValidacaoException('Latitude inválida.');
    }
    if (empresa.longitude != null && (empresa.longitude! < -180 || empresa.longitude! > 180)) {
      throw const ValidacaoException('Longitude inválida.');
    }

    final empresaFormatada = EmpresaModel(
      id: empresa.id,
      nome: empresa.nome,
      cnpj: cnpjLimpo,
      latitude: empresa.latitude,
      longitude: empresa.longitude,
      raioPermitido: empresa.raioPermitido,
    );

    return await _repository.salvarEmpresa(empresaFormatada, ehEdicao: ehEdicao);
  }

  Future<List<EmpresaModel>> buscarMinhasEmpresas() async {
    return await _repository.listarEmpresas();
  }
}