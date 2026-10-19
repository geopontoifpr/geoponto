import 'dart:async';
import 'dart:io';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../errors/app_exception.dart';

class SupabaseService {
  // Construtor privado para garantir o padrão Singleton
  SupabaseService._();

  static final SupabaseService instance = SupabaseService._();

  // Retorna a instância padrão do cliente Supabase
  SupabaseClient get client => Supabase.instance.client;

  // Atalhos rápidos para recursos mais usados
  GoTrueClient get auth => client.auth;
  User? get usuarioAtual => client.auth.currentUser;

  // Método de inicialização chamado no main.dart
  static Future<void> inicializar() async {
    final url = dotenv.env['SUPABASE_URL'];
    final anonKey = dotenv.env['SUPABASE_ANON_KEY'];

    if (url == null || anonKey == null) {
      throw const CredenciaisSupabaseException();
    }

    await Supabase.initialize(
      url: url,
      anonKey: anonKey,
    );
  }

  /// Verifica se o serviço do Supabase/Banco de Dados está acessível.
  /// Dispara uma requisição leve com timeout estrito para não travar o app.
  Future<bool> verificarConexao({Duration timeout = const Duration(seconds: 4)}) async {
    try {
      // Faz uma requisição HEAD/COUNT mínima na tabela de usuários ou empresas
      // limit(0) não traz dados de linhas, apenas testa o handshake HTTP com o PostgREST
      await client
          .from('usuarios')
          .select('id')
          .limit(0)
          .timeout(timeout);

      return true;
    } on TimeoutException {
      return false;
    } on SocketException {
      return false;
    } on PostgrestException catch (e) {
      // Se o banco responder com erro de RLS (código 42501) ou similar,
      // significa que o servidor está online e respondendo!
      if (e.code != null && e.code != 'PGRST000') {
        return true;
      }
      return false;
    } catch (_) {
      return false;
    }
  }

  /// Valida a conexão e lança [ConexaoException] diretamente se estiver fora do ar.
  Future<void> assegurarConexaoOnline() async {
    final online = await verificarConexao();
    if (!online) {
      throw const ConexaoException(
        'Não foi possível conectar ao servidor do banco de dados. Verifique sua conexão ou se o serviço está ativo.',
      );
    }
  }
}