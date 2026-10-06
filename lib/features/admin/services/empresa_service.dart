import '../../../core/errors/app_exception.dart';
import '../models/empresa_model.dart';
import '../repositories/admin_repository.dart';

class EmpresaService {
  final AdminRepository _repository;

  EmpresaService({AdminRepository? repository}) 
      : _repository = repository ?? AdminRepository();

  Future<EmpresaModel> salvarEmpresa(EmpresaModel empresa, {bool ehEdicao = false}) async {
    // 1. Regra de Negócio: Limpar a máscara e validar o tamanho do CNPJ
    final cnpjLimpo = empresa.cnpj?.replaceAll(RegExp(r'[^0-9]'), '') ?? '';

    if (cnpjLimpo.isEmpty) {
      throw const ValidacaoException('O CNPJ não pode estar vazio.');
    }
    
    if (cnpjLimpo.length != 14) {
      throw const ValidacaoException('O CNPJ inválido. Ele deve conter exatamente 14 dígitos numéricos.');
    }

    // 2. Regra de Negócio: Validar limites geográficos
    if (empresa.latitude != null && (empresa.latitude! < -90 || empresa.latitude! > 90)) {
      throw const ValidacaoException('Latitude inválida. Deve estar entre -90 e 90.');
    }
    if (empresa.longitude != null && (empresa.longitude! < -180 || empresa.longitude! > 180)) {
      throw const ValidacaoException('Longitude inválida. Deve estar entre -180 e 180.');
    }

    // Atualiza o model para salvar o CNPJ limpo no banco
    final empresaValidada = EmpresaModel(
      id: empresa.id,
      nome: empresa.nome,
      cnpj: cnpjLimpo,
      latitude: empresa.latitude, // Corrigido para latitude
      longitude: empresa.longitude, // Corrigido para longitude
      raioPermitido: empresa.raioPermitido, // Corrigido para raioPermitido
    );

    return await _repository.salvarEmpresa(empresaValidada, ehEdicao: ehEdicao);
  }

  Future<List<EmpresaModel>> buscarMinhasEmpresas() async {
    return await _repository.listarEmpresas();
  }
}