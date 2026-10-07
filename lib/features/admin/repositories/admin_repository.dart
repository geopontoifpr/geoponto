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
          .order('nome', ascending: true); 
      
      // ADICIONE ESTE PRINT PARA DEBUG
      print('=== DEBUG SUPABASE (listarEmpresas) ===');
      print('Resposta do banco: $response');
      print('=======================================');
      
      return (response as List)
          .map((e) => EmpresaModel.fromMap(e as Map<String, dynamic>))
          .toList();
    } on SocketException {
      throw const ConexaoException();
    } on PostgrestException catch (e) {
      print('ERRO POSTGREST: ${e.message} | Detalhes: ${e.details}'); // DEBUG
      throw ServidorException('Erro ao buscar empresas: ${e.message}');
    } catch (e) {
      print('ERRO DESCONHECIDO NO REPOSITÓRIO: $e'); // DEBUG
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
      // GARANTIA: Pegamos o usuário logado direto do Supabase no Flutter
      final usuarioLogado = _client.auth.currentUser;
      if (usuarioLogado == null) {
        throw const ServidorException('Sessão expirada. Feche o app e faça login novamente.');
      }

      if (ehEdicao) {
        // FLUXO DE EDIÇÃO
        final dados = empresa.toMap();
        dados.remove('id'); 

        final response = await _client
            .from('empresas')
            .update(dados)
            .eq('id', empresa.id)
            .select()
            .single();
            
        return EmpresaModel.fromMap(response);
      } else {
        // FLUXO DE CRIAÇÃO: Passando o ID explicitamente para a RPC!
        final response = await _client.rpc('cadastrar_empresa_inicial', params: {
          'p_admin_id': usuarioLogado.id, // <=== PASSAMOS O UUID DO ADMIN AQUI!
          'p_nome': empresa.nome,
          'p_cnpj': empresa.cnpj,
          'p_latitude_ponto': empresa.latitude,
          'p_longitude_ponto': empresa.longitude,
          'p_raio_permitido_m': empresa.raioPermitido,
        });

        return EmpresaModel.fromMap(response as Map<String, dynamic>);
      }
    } on PostgrestException catch (e) {
      if (e.code == '23505') {
        throw const DadoDuplicadoException('Já existe uma empresa cadastrada com este CNPJ no sistema.');
      }
      if (e.message.contains('já possui uma empresa')) {
        throw const ValidacaoException('Você já possui uma empresa vinculada. Atualize os dados em vez de recadastrar.');
      }
      throw ServidorException('Erro no banco: ${e.message}');
    } catch (e) {
      print('ERRO DESCONHECIDO NO REPOSITÓRIO: $e');
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