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
      // Se idAtual vier preenchido, é edição. Se for nulo, é criação.
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
      } else {
        print('DEBUG CONTROLLER: A lista de empresas veio VAZIA!');
      }
    } catch (e) {
      // ADICIONE ESTE PRINT PARA VER SE A TELA ESTÁ ESCONDENDO O ERRO
      print('DEBUG CONTROLLER: Erro ao carregar painel: $e');
    } finally {
      _setLoading(false);
    }
  }

  void _setLoading(bool value) {
    isLoading = value;
    notifyListeners();
  }
}