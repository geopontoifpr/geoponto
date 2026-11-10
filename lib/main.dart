import 'dart:async';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'core/services/supabase_service.dart';
import 'core/themes/app_themes.dart';
import 'core/themes/theme_controller.dart';
import 'features/auth/screens/login_screen.dart';
import 'features/usuarios/models/usuario_model.dart'; 
import 'features/auth/screens/primeiro_acesso_screen.dart';
import 'core/widgets/animacao_abertura.dart';
import 'core/widgets/fundo_futurista.dart';


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
        final isDarkMode = ThemeController.instance.isDarkMode;

        return MaterialApp(
          title: 'GeoPonto',
          debugShowCheckedModeBanner: false,
          theme: AppThemes.lightTheme,
          darkTheme: AppThemes.darkTheme,
          themeMode: isDarkMode ? ThemeMode.dark : ThemeMode.light,
          
          // Adicionamos o builder global para manter o FundoFuturista vivo em todas as telas
          builder: (context, child) {
            return Stack(
              fit: StackFit.expand,
              children: [
                // Renderiza o fundo apenas no modo escuro
                if (isDarkMode)
                  FundoFuturista(child: child ?? const SizedBox.shrink())
                else
                  child ?? const SizedBox.shrink(),
              ],
            );
          },

          home: erroInicializacao != null
              ? Scaffold(
                  backgroundColor: Colors.transparent, // Fundo transparente para não cobrir a animação
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
              : const AberturaGeoPonto(), 
        );
      },
    );
  }
}

class AberturaGeoPonto extends StatefulWidget {
  const AberturaGeoPonto({super.key});

  @override
  State<AberturaGeoPonto> createState() => _AberturaGeoPontoState();
}

class _AberturaGeoPontoState extends State<AberturaGeoPonto> {
  bool _animacaoConcluida = false;

  @override
  Widget build(BuildContext context) {
    if (_animacaoConcluida) {
      return const AuthWrapper();
    }

    return AnimacaoAbertura(
      onFinished: () {
        if (!mounted) return;

        setState(() {
          _animacaoConcluida = true;
        });
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

      // Log para visualizarmos no console do VS Code qual evento o Supabase disparou
      debugPrint('🚨 Evento Supabase capturado: ${event.name}');

      // Se capturar o evento de recuperação E tiver uma sessão válida
      if (event == AuthChangeEvent.passwordRecovery && session != null) {
        debugPrint('✅ Iniciando redirecionamento para troca de senha...');
        
        try {
          // Nota baseada no seu contexto: Consultando a tabela 'empresa' caso o app seja single-tenant
          final resposta = await Supabase.instance.client
              .from('usuarios') // Lembre-se de alterar para 'empresa' se for a lógica single-tenant
              .select()
              .eq('id', session.user.id)
              .single();

          final usuario = UsuarioModel.fromMap(resposta);

          if (mounted) {
            // Força a ida para a tela de criar nova senha (PrimeiroAcessoScreen)
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                builder: (_) => PrimeiroAcessoScreen(usuario: usuario),
              ),
            );
          }
        } catch (e) {
          debugPrint('❌ Erro ao buscar dados do usuário na recuperação: $e');
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
    return const LoginScreen();
  }
}