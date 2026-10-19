import 'dart:io';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/errors/app_exception.dart';
import '../../../core/services/supabase_service.dart';
import '../models/setor_model.dart';
import '../../usuarios/models/usuario_model.dart';

class SetorRepository {
  final _client = Supabase.instance.client;

  Future<SetorModel> salvarSetor(SetorModel setor, {bool ehEdicao = false}) async {
    try {
      final dados = setor.toMap();
      
      if (ehEdicao) {
        dados.remove('id');
        dados.remove('empresa_id'); // Proteção para não mudar a empresa do setor
        
        final response = await _client
            .from('setores')
            .update(dados)
            .eq('id', setor.id)
            .select()
            .single();
            
        return SetorModel.fromMap(response);
      } else {
        dados.remove('id'); // Deixa o PostgreSQL gerar o UUID
        
        final response = await _client
            .from('setores')
            .insert(dados)
            .select()
            .single();
            
        return SetorModel.fromMap(response);
      }
    } on PostgrestException catch (e) {
      throw ServidorException('Erro no banco de dados: ${e.message}');
    } catch (e) {
      throw ServidorException('Falha inesperada ao salvar setor.');
    }
  }

  Future<List<SetorModel>> listarSetoresPorEmpresa(String empresaId) async {
    try {
      final response = await _client
          .from('setores')
          .select()
          .eq('empresa_id', empresaId)
          .order('nome', ascending: true);
          
      return (response as List).map((e) => SetorModel.fromMap(e)).toList();
    } on PostgrestException catch (e) {
      throw ServidorException('Erro ao buscar setores: ${e.message}');
    }
  }

  Future<void> excluirSetor(String id) async {
      try {
        await _client.from('setores').delete().eq('id', id);
      } on PostgrestException catch (e) {
        // 23503 é o código do PostgreSQL para violação de Chave Estrangeira
        if (e.code == '23503') {
          throw ServidorException('Não é possível excluir este setor pois há funcionários vinculados a ele.');
        }
        throw ServidorException('Erro ao excluir setor: ${e.message}');
      } catch (e) {
        throw ServidorException('Falha inesperada ao excluir setor.');
      }
  }



}
