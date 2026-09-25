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

  // Método de inicialização que será chamado no main.dart
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
}