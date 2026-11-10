import 'package:flutter/material.dart';
import '../../../core/errors/app_exception.dart';
import '../../usuarios/models/usuario_model.dart';
import '../../usuarios/services/usuario_service.dart';
import '../models/empresa_model.dart';
import '../services/empresa_service.dart';

class EmpresaController extends ChangeNotifier {
  final EmpresaService _service;
  final UsuarioService _usuarioService;
  final UsuarioModel usuario;

  bool isLoading = false;
  EmpresaModel? empresaAtual;
  int totalGestores = 0;
  int totalColaboradores = 0;

  EmpresaController({
    required this.usuario,
    EmpresaService? service,
    UsuarioService? usuarioService,
  })  : _service = service ?? EmpresaService(usuario: usuario),
        _usuarioService = usuarioService ?? UsuarioService();

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

    _setLoading(true);
    try {
      await _service.salvarEmpresa(empresa, ehEdicao: idAtual != null);
    } finally {
      _setLoading(false);
    }
  }

  Future<void> carregarDadosDoPainel() async {
    _setLoading(true);
    try {
      final empresas = await _service.buscarMinhasEmpresas();
      if (empresas.isNotEmpty) {
        empresaAtual = empresas.first;
        final membros = await _usuarioService.listarUsuarios(
          empresaId: empresaAtual!.id,
        );
        totalGestores = membros
            .where((u) => u.tipoUsuario == TipoUsuario.gestor && u.ativo)
            .length;
        totalColaboradores = membros
            .where((u) => u.tipoUsuario == TipoUsuario.funcionario && u.ativo)
            .length;
      } else {
        empresaAtual = null;
        totalGestores = 0;
        totalColaboradores = 0;
      }
    } catch (_) {
    } finally {
      _setLoading(false);
    }
  }

  void _setLoading(bool value) {
    isLoading = value;
    notifyListeners();
  }
}