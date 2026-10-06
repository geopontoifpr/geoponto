import 'package:flutter/material.dart';
import '../../../core/errors/app_exception.dart';
import '../models/empresa_model.dart';
import '../services/empresa_service.dart';

class EmpresaController extends ChangeNotifier {
  final EmpresaService _service;

  bool isLoading = false;
  EmpresaModel? empresaAtual;

  EmpresaController({EmpresaService? service}) 
      : _service = service ?? EmpresaService();

  Future<void> submeterFormulario({
    required String? idAtual,
    required String nome,
    required String cnpj,
    required String latTexto,
    required String lngTexto,
    required String raioTexto,
  }) async {
    if (nome.isEmpty || cnpj.isEmpty || latTexto.isEmpty || lngTexto.isEmpty) {
      throw const ValidacaoException('Por favor, preencha todos os campos obrigatórios.');
    }

    final lat = double.tryParse(latTexto.replaceAll(',', '.'));
    final lng = double.tryParse(lngTexto.replaceAll(',', '.'));
    final raio = int.tryParse(raioTexto);

    if (lat == null || lng == null) {
      throw const ValidacaoException('As coordenadas devem ser números válidos.');
    }
    if (raio == null || raio <= 0) {
      throw const ValidacaoException('O raio deve ser um número inteiro maior que zero.');
    }

    final empresa = EmpresaModel(
      id: idAtual ?? '',
      nome: nome,
      cnpj: cnpj,
      latitude: lat, // Corrigido
      longitude: lng, // Corrigido
      raioPermitido: raio, // Corrigido
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
      }
    } catch (_) {
      // Falhas silenciosas no carregamento do painel
    } finally {
      _setLoading(false);
    }
  }

  void _setLoading(bool value) {
    isLoading = value;
    notifyListeners();
  }
}