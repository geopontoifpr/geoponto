import 'package:flutter/material.dart';
import '../../features/admin/services/empresa_service.dart';
import '../../features/ocorrencias/controllers/ocorrencia_controller.dart';
import '../../features/usuarios/models/usuario_model.dart';

class PainelUnificadoController extends ChangeNotifier {
  final UsuarioModel usuario;
  final OcorrenciaController _oc;
  final EmpresaService _empresaService;
  String? empresaId;

  PainelUnificadoController({
    required this.usuario,
    OcorrenciaController? oc,
    EmpresaService? empresaService,
  })  : _oc = oc ?? OcorrenciaController(),
        _empresaService = empresaService ?? EmpresaService(usuario: usuario),
        empresaId = usuario.empresaId {
    _oc.addListener(notifyListeners);
  }

  bool get temPendencias {
    switch (usuario.tipoUsuario) {
      case TipoUsuario.gestor:
        return _oc.quantidadePendentes > 0;
      case TipoUsuario.administrador:
        return _oc.pessoasComPendencias.isNotEmpty;
      case TipoUsuario.funcionario:
        return false;
    }
  }

  Future<void> atualizarPendencias() {
    switch (usuario.tipoUsuario) {
      case TipoUsuario.gestor:
        return _oc.carregarOcorrenciasGestor(usuario.id);
      case TipoUsuario.administrador:
        return _oc.carregarPessoasComPendencias(usuario);
      case TipoUsuario.funcionario:
        return Future.value();
    }
  }

  Future<void> inicializar() async {
    await Future.wait([
      atualizarPendencias(),
      if (usuario.tipoUsuario == TipoUsuario.administrador) carregarEmpresa(),
    ]);
  }

  Future<void> carregarEmpresa() async {
    try {
      final lista = await _empresaService.buscarMinhasEmpresas();
      if (lista.isNotEmpty) {
        empresaId = lista.first.id;
        notifyListeners();
      }
    } catch (_) {}
  }

  @override
  void dispose() {
    _oc.removeListener(notifyListeners);
    _oc.dispose();
    super.dispose();
  }
}