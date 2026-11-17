import 'package:flutter/foundation.dart';
import '../../../core/errors/app_exception.dart';
import '../../../core/utils/executor_async.dart';
import '../../usuarios/models/usuario_model.dart';
import '../../usuarios/services/usuario_service.dart';
import '../models/empresa_model.dart';
import '../services/empresa_service.dart';

class EmpresaController extends ChangeNotifier with ExecutorAsync {
  final EmpresaService _service;
  final UsuarioService _usuarioService;
  final UsuarioModel usuario;

  EmpresaModel? empresaAtual;
  int totalGestores = 0;
  int totalColaboradores = 0;

  EmpresaController({
    required this.usuario,
    EmpresaService? service,
    UsuarioService? usuarioService,
  })  : _service = service ?? EmpresaService(usuario: usuario),
        _usuarioService = usuarioService ?? UsuarioService();

  /// Lança AppException para a tela tratar (a tela já faz try/catch).
  Future<void> submeterFormulario({
    required String? idAtual,
    required String nome,
    required String cnpj,
    required String latTexto,
    required String lngTexto,
    required String raioTexto,
  }) async {
    if (nome.isEmpty || cnpj.isEmpty || latTexto.isEmpty || lngTexto.isEmpty) {
      throw const ValidacaoException('Preencha todos os campos obrigatórios.');
    }

    final lat = double.tryParse(latTexto.replaceAll(',', '.'));
    final lng = double.tryParse(lngTexto.replaceAll(',', '.'));
    final raio = int.tryParse(raioTexto);

    if (lat == null || lng == null || raio == null) {
      throw const ValidacaoException('Coordenadas ou raio em formato inválido.');
    }

    final empresa = EmpresaModel(
      id: idAtual ?? '',
      nome: nome,
      cnpj: cnpj,
      latitude: lat,
      longitude: lng,
      raioPermitido: raio,
    );

    await comCarregamento(
      () => _service.salvarEmpresa(empresa, ehEdicao: idAtual != null),
    );
  }

  Future<void> carregarDadosDoPainel() => executar(() async {
        final empresas = await _service.buscarMinhasEmpresas();
        final empresa = empresas.isEmpty ? null : empresas.first;
        empresaAtual = empresa;

        if (empresa == null) {
          totalGestores = 0;
          totalColaboradores = 0;
          return;
        }

        final membros = await _usuarioService.listarUsuarios(empresaId: empresa.id);
        final ativos = membros.where((u) => u.ativo);
        totalGestores =
            ativos.where((u) => u.tipoUsuario == TipoUsuario.gestor).length;
        totalColaboradores =
            ativos.where((u) => u.tipoUsuario == TipoUsuario.funcionario).length;
      }, erroPadrao: 'Não foi possível carregar os dados da empresa.');
}