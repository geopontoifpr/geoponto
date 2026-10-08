import 'dart:io';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/errors/app_exception.dart';
import '../../../core/services/supabase_service.dart';
import '../models/setor_model.dart';
import '../../usuarios/models/usuario_model.dart';

class SetorRepository {
  final SupabaseClient _client;
  final UsuarioModel usuario;

  SetorRepository({
    required this.usuario,
    SupabaseClient? client,
  }) : _client = client ?? SupabaseService.instance.client;

  // ==========================================
  // SETORES
  // ==========================================

  
  Future<List<SetorModel>> listarSetoresPorEmpresa(String empresaId, {bool apenasAtivos = true}) async {
    try {
      var query = _client.from('setores').select().eq('empresa_id', empresaId);

      if (apenasAtivos) {
        // Se a tabela setores também não tiver 'ativo', você precisará remover este if!
        query = query.eq('ativo', true);
      }

      final response = await query.order('nome', ascending: true);
      
      return (response as List)
          .map((e) => SetorModel.fromMap(e as Map<String, dynamic>))
          .toList();
    } on SocketException {
      throw const ConexaoException();
    } on PostgrestException catch (e) {
      throw ServidorException('Erro ao buscar setores: ${e.message}');
    } catch (_) {
      throw const ServidorException('Falha inesperada ao listar setores.');
    }
  }

  Future<SetorModel> cadastrarSetor(SetorModel setor) async {
    try {
      final dados = setor.toMap();
      if (setor.id.isEmpty) {
        dados.remove('id');
      }

      final response = await _client
          .from('setores')
          .insert(dados)
          .select()
          .single();
      return SetorModel.fromMap(response);
    } on SocketException {
      throw const ConexaoException();
    } on PostgrestException catch (e) {
      if (e.code == '23505') {
        throw const DadoDuplicadoException('Já existe um setor com este nome nesta empresa.');
      }
      throw ServidorException('Erro ao registrar setor: ${e.message}');
    } catch (_) {
      throw const ServidorException('Falha inesperada ao cadastrar setor.');
    }
  }
}


