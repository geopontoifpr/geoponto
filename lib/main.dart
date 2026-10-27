import 'dart:async';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'core/services/supabase_service.dart';
import 'core/themes/app_themes.dart';
import 'core/themes/theme_controller.dart';
import 'features/auth/screens/login_screen.dart';

// Importe o seu modelo de usuário e a tela de destino
// Ajuste os caminhos abaixo conforme a sua estrutura de pastas real
import 'features/usuarios/models/usuario_model.dart'; 
import 'features/auth/screens/primeiro_acesso_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  String? erroInicializacao;

  try {
    await SupabaseService.inicializar();
  } catch (e) {
    erroInicializacao = e.toString();
  }

  runApp(MyApp(erroInicializacao: erroInicializacao));
}

class MyApp extends StatelessWidget {
  final String? erroInicializacao;

  const MyApp({super.key, this.erroInicializacao});

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: ThemeController.instance,
      builder: (context, _) {
        return MaterialApp(
          title: 'GeoPonto',
          debugShowCheckedModeBanner: false,
          theme: AppThemes.lightTheme,
          darkTheme: AppThemes.darkTheme,
          themeMode: ThemeController.instance.isDarkMode
              ? ThemeMode.dark
              : ThemeMode.light,
          home: erroInicializacao != null
              ? Scaffold(
                  body: Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24.0),
                      child: Text(
                        'Erro ao iniciar o app:\n\n$erroInicializacao\n\nVerifique se o arquivo .env está na raiz do projeto e listado no pubspec.yaml.',
                        textAlign: TextAlign.center,
                        style: const TextStyle(color: Colors.red, fontSize: 16),
                      ),
                    ),
                  ),
                )
              : const AuthWrapper(), // Alterado de LoginScreen() para AuthWrapper()
        );
      },
    );
  }
}

/// Wrapper raiz que escuta os eventos de autenticação do Supabase
class AuthWrapper extends StatefulWidget {
  const AuthWrapper({super.key});

  @override
  State<AuthWrapper> createState() => _AuthWrapperState();
}

class _AuthWrapperState extends State<AuthWrapper> {
  late final StreamSubscription<AuthState> _authSubscription;

  @override
  void initState() {
    super.initState();
    
    // Escuta as mudanças de estado da sessão
    _authSubscription = Supabase.instance.client.auth.onAuthStateChange.listen((data) async {
      final AuthChangeEvent event = data.event;
      final Session? session = data.session;

      // Se o evento for de recuperação de senha e o usuário estiver validado
      if (event == AuthChangeEvent.passwordRecovery && session != null) {
        try {
          // 1. Busca os dados completos do usuário na tabela do Supabase
          final resposta = await Supabase.instance.client
              .from('usuarios')
              .select()
              .eq('id', session.user.id)
              .single();

          // 2. Converte o mapa recebido para o seu UsuarioModel 
          // (Verifique se o seu método de conversão se chama fromMap ou fromJson)
          final usuario = UsuarioModel.fromMap(resposta);

          // 3. Redireciona o usuário para a tela onde ele cadastra a nova senha
          if (mounted) {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                builder: (_) => PrimeiroAcessoScreen(usuario: usuario),
              ),
            );
          }
        } catch (e) {
          debugPrint('Erro ao buscar dados do usuário na recuperação: $e');
        }
      }
    });
  }

  @override
  void dispose() {
    _authSubscription.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Por padrão, exibe a tela de login. O redirecionamento ocorre via listen() acima se necessário.
    return const LoginScreen();
  }
}