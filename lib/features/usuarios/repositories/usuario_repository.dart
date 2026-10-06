import 'dart:io';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/errors/app_exception.dart';
import '../../../core/services/supabase_service.dart';
import '../models/usuario_model.dart';

class UsuarioRepository {
  final SupabaseClient _client;

  UsuarioRepository({SupabaseClient? client})
      : _client = client ?? SupabaseService.instance;

  Future<List<UsuarioModel>> listarPorEmpresa(String empresaId, {String? setorId}) async {
    try {
      var query = _client.from('usuarios').select().eq('empresa_id', empresaId);

      if (setorId != null && setorId.isNotEmpty) {
        query = query.eq('setor_id', setorId);
      }

      final response = await query.order('nome', ascending: true);
      return (response as List).map((u) => UsuarioModel.fromJson(u)).toList();
    } on SocketException {
      throw const ConexaoException();
    } on PostgrestException catch (e) {
      throw ServidorException('Erro ao consultar usuários: ${e.message}');
    } catch (_) {
      throw const ServidorException('Falha ao processar lista de colaboradores.');
    }
  }

  Future<void> criarUsuario({
    required String nome,
    required String email,
    required String senha,
    required String tipoUsuario,
    required String empresaId,
    String? setorId,
  }) async {
    try {
      await _client.rpc('cadastrar_novo_usuario', params: {
        'p_nome': nome.trim(),
        'p_email': email.trim().toLowerCase(),
        'p_senha': senha,
        'p_tipo_usuario': tipoUsuario,
        'p_empresa_id': empresaId,
        'p_setor_id': setorId,
      });
    } on SocketException {
      throw const ConexaoException();
    } on PostgrestException catch (e) {
      if (e.code == '23505' || e.message.contains('email_key') || e.message.contains('já cadastrado')) {
        throw const DadoDuplicadoException('O e-mail informado já está em uso.');
      }
      throw ServidorException('Falha no cadastro: ${e.message}');
    } catch (_) {
      throw const ServidorException('Erro inesperado ao cadastrar novo usuário.');
    }
  }

  Future<void> alternarStatusUsuario(String usuarioId, bool ativo) async {
    try {
      await _client
          .from('usuarios')
          .update({'ativo': ativo})
          .eq('id', usuarioId);
    } on SocketException {
      throw const ConexaoException();
    } on PostgrestException catch (e) {
      throw ServidorException('Erro ao atualizar usuário: ${e.message}');
    } catch (_) {
      throw const ServidorException('Falha ao modificar status do colaborador.');
    }
  }
}