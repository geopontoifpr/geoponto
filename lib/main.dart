import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'core/services/supabase_service.dart';
import 'core/themes/app_themes.dart';
import 'core/themes/theme_controller.dart';
import 'features/auth/screens/login_screen.dart';

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
              : const LoginScreen(),
        );
      },
    );
  }
}