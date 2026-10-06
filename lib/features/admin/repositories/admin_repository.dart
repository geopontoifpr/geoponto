import 'dart:io';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/errors/app_exception.dart';
import '../../../core/services/supabase_service.dart';
import '../models/empresa_model.dart';
import '../models/setor_model.dart';

class AdminRepository {
  final SupabaseClient _client;

  AdminRepository({SupabaseClient? client})
      : _client = client ?? SupabaseService.instance.client;

  // ==========================================
  // EMPRESAS
  // ==========================================

  Future<List<EmpresaModel>> listarEmpresas() async {
    try {
      final response = await _client
          .from('empresas')
          .select()
          .order('nome', ascending: true); // Ajustado para 'nome'
      
      return (response as List)
          .map((e) => EmpresaModel.fromMap(e as Map<String, dynamic>))
          .toList();
    } on SocketException {
      throw const ConexaoException();
    } on PostgrestException catch (e) {
      throw ServidorException('Erro ao buscar empresas: ${e.message}');
    } catch (e) {
      throw const ServidorException('Falha inesperada ao listar empresas.');
    }
  }

  Future<EmpresaModel> buscarEmpresaPorId(String id) async {
    try {
      final response = await _client
          .from('empresas')
          .select()
          .eq('id', id)
          .maybeSingle();

      if (response == null) {
        throw const NaoEncontradoException('Empresa não encontrada.');
      }

      return EmpresaModel.fromMap(response);
    } on AppException {
      rethrow;
    } on SocketException {
      throw const ConexaoException();
    } on PostgrestException catch (e) {
      throw ServidorException('Erro no banco de dados: ${e.message}');
    } catch (_) {
      throw const ServidorException('Falha ao localizar empresa.');
    }
  }

  Future<EmpresaModel> salvarEmpresa(EmpresaModel empresa, {bool ehEdicao = false}) async {
    try {
      if (ehEdicao) {
        // Fluxo de Edição normal usando o RLS restrito da tabela
        final dados = empresa.toMap();
        dados.remove('id'); // Não tentamos atualizar a Primary Key

        final response = await _client
            .from('empresas')
            .update(dados)
            .eq('id', empresa.id)
            .select()
            .single();
            
        return EmpresaModel.fromMap(response);
      } else {
        // Fluxo de Criação: Aciona a RPC que salva a empresa e atualiza o usuário na mesma transação
        final response = await _client.rpc('cadastrar_empresa_inicial', params: {
          'p_nome': empresa.nome,
          'p_cnpj': empresa.cnpj,
          'p_latitude_ponto': empresa.latitude,
          'p_longitude_ponto': empresa.longitude,
          'p_raio_permitido_m': empresa.raioPermitido,
        });

        return EmpresaModel.fromMap(response as Map<String, dynamic>);
      }
    } on SocketException {
      throw const ConexaoException();
    } on PostgrestException catch (e) {
      if (e.code == '23505') {
        throw const DadoDuplicadoException('Já existe uma empresa cadastrada com este CNPJ.');
      }
      throw ServidorException('Erro ao salvar empresa: ${e.message}');
    } catch (_) {
      throw const ServidorException('Falha inesperada ao processar empresa.');
    }    
    
  }

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