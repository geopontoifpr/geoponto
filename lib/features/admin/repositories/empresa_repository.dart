import 'dart:io';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/errors/app_exception.dart';
import '../../../core/services/supabase_service.dart';
import '../models/empresa_model.dart';
import '../models/setor_model.dart';
import '../../usuarios/models/usuario_model.dart';

class EmpresaRepository {
  final SupabaseClient _client;
  final UsuarioModel usuario;

  EmpresaRepository({
    required this.usuario,
    SupabaseClient? client,
  }) : _client = client ?? SupabaseService.instance.client;

  // ==========================================
  // EMPRESAS
  // ==========================================

  Future<List<EmpresaModel>> listarEmpresas() async {
    try {
      final response = await _client
          .from('empresas')
          .select()
          .order('nome', ascending: true); 
          // O RLS (empresas_admin_all) garante que só virá a empresa dele.
      
      return (response as List)
          .map((e) => EmpresaModel.fromMap(e as Map<String, dynamic>))
          .toList();
    } on PostgrestException catch (e) {
      throw ServidorException('Erro ao buscar empresas: ${e.message}');
    }
  }

  
  Future<EmpresaModel> salvarEmpresa(EmpresaModel empresa, {bool ehEdicao = false}) async {
    try {
      final usuarioLogado = _client.auth.currentUser;
      if (usuarioLogado == null) {
        throw const ServidorException('Sessão expirada. Feche o app e faça login novamente.');
      }

      final dados = empresa.toMap();
      
      if (ehEdicao) {
        // FLUXO DE EDIÇÃO
        dados.remove('id');
        dados.remove('admin_id'); // Proteção: nunca alteramos o dono na edição

        final response = await _client
            .from('empresas')
            .update(dados)
            .eq('id', empresa.id)
            .select()
            .single();
            
        return EmpresaModel.fromMap(response);
      } else {
        // FLUXO DE CRIAÇÃO (Sem RPC!)
        // Amarra a empresa ao ID do administrador logado
        dados['admin_id'] = usuarioLogado.id;
        dados.remove('id'); // Deixa o banco gerar o UUID

        final response = await _client
            .from('empresas')
            .insert(dados)
            .select()
            .single();

        return EmpresaModel.fromMap(response);
      }
    } on PostgrestException catch (e) {
      if (e.code == '23505') { // Constraint UNIQUE do cnpj
        throw const DadoDuplicadoException('Já existe uma empresa cadastrada com este CNPJ no sistema.');
      }
      throw ServidorException('Erro no banco: ${e.message}');
    } catch (e) {
      throw const ServidorException('Falha inesperada ao processar empresa.');
    }
  }

  Future<void> deletarEmpresa(String empresaId) async {
    try {
      await _client
          .from('empresas')
          .delete()
          .eq('id', empresaId);
    } on PostgrestException catch (e) {
      throw ServidorException('Erro ao deletar empresa: ${e.message}');
    }
  }
}