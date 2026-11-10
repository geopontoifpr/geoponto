import 'package:flutter/foundation.dart';

import '../../features/admin/services/empresa_service.dart';
import '../../features/ocorrencias/controllers/ocorrencia_controller.dart';
import '../../features/usuarios/models/usuario_model.dart';

class PainelUnificadoController extends ChangeNotifier {
  final UsuarioModel usuario;
  late final EmpresaService _empresaService;
  final OcorrenciaController ocorrenciaController;

  String? empresaIdAdmin;
  bool carregandoEmpresa = false;
  String? erroEmpresa;

  PainelUnificadoController({
    required this.usuario,
    OcorrenciaController? ocorrenciaController,
    EmpresaService? empresaService,
  })  : ocorrenciaController = ocorrenciaController ?? OcorrenciaController() {
    _empresaService = empresaService ?? EmpresaService(usuario: usuario);
    this.ocorrenciaController.addListener(_notificarAlteracao);
  }

  bool get temOcorrenciasPendentes =>
      ocorrenciaController.quantidadePendentes > 0;

  Future<void> inicializar() async {
    final tarefas = <Future<void>>[];

    if (usuario.tipoUsuario == TipoUsuario.gestor) {
      tarefas.add(ocorrenciaController.carregarOcorrenciasGestor(usuario.id));
    }

    if (usuario.tipoUsuario == TipoUsuario.administrador) {
      tarefas.add(carregarEmpresaAdmin());
    }

    await Future.wait(tarefas);
  }

  Future<void> carregarEmpresaAdmin() async {
    carregandoEmpresa = true;
    erroEmpresa = null;
    notifyListeners();

    try {
      final empresas = await _empresaService.buscarMinhasEmpresas();
      empresaIdAdmin = empresas.isEmpty ? null : empresas.first.id;
    } catch (_) {
      erroEmpresa = 'Não foi possível carregar a empresa.';
    } finally {
      carregandoEmpresa = false;
      notifyListeners();
    }
  }

  void _notificarAlteracao() {
    notifyListeners();
  }

  @override
  void dispose() {
    ocorrenciaController.removeListener(_notificarAlteracao);
    ocorrenciaController.dispose();
    super.dispose();
  }
}