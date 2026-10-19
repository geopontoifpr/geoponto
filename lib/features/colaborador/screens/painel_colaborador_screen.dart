import 'package:flutter/material.dart';
import '../../usuarios/models/usuario_model.dart';
import 'bater_ponto_screen.dart';
import '../../../core/themes/app_themes.dart';
import '../../../core/widgets/custom_app_bar.dart';
import 'historico_mensal_screen.dart';

class PainelColaboradorScreen extends StatefulWidget {
  final UsuarioModel usuario;

  const PainelColaboradorScreen({
    Key? key,
    required this.usuario,
  }) : super(key: key);

  @override
  State<PainelColaboradorScreen> createState() => _PainelColaboradorScreenState();
}

class _PainelColaboradorScreenState extends State<PainelColaboradorScreen> {
  
 void _baterPonto() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => BaterPontoScreen(usuario: widget.usuario),
      ),
    );
  }

  void _verFrequencia() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => HistoricoMensalScreen(usuario: widget.usuario),
      ),
    );
  }

  void _verOcorrencias() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Ocorrências em breve!'),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;

    // Cores padronizadas com a tela de histórico
    final bgColorScreen = isDarkMode ? const Color(0xFF0F172A) : const Color(0xFFF6F7F9);
    final cardColor = isDarkMode ? const Color(0xFF1E293B) : Colors.white;
    final textColorSecondary = isDarkMode ? const Color(0xFF94A3B8) : Colors.black54;

    return Scaffold(
      backgroundColor: bgColorScreen,
      appBar: CustomAppBar(
        nomeUsuario: widget.usuario.nome,
        onPerfilPressed: () {},
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Saudação Personalizada
            Card(
              elevation: 0,
              color: isDarkMode ? cardColor : theme.primaryColor.withOpacity(0.1),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Olá, ${widget.usuario.nome.split(' ').first}!',
                      style: theme.textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: isDarkMode ? Colors.white : theme.primaryColor,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'O que você deseja fazer hoje?',
                      style: TextStyle(fontSize: 16, color: textColorSecondary),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Grid de Botões (Ações)
            Expanded(
              child: GridView.count(
                crossAxisCount: 2,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
                children: [
                  _buildActionCard(
                    context,
                    title: 'Bater Ponto',
                    icon: Icons.fingerprint,
                    color: Colors.teal,
                    onTap: _baterPonto,
                    isDarkMode: isDarkMode,
                    cardBgColor: cardColor,
                  ),
                  _buildActionCard(
                    context,
                    title: 'Frequência Mensal',
                    icon: Icons.calendar_month,
                    color: Colors.indigo,
                    onTap: _verFrequencia,
                    isDarkMode: isDarkMode,
                    cardBgColor: cardColor,
                  ),
                  _buildActionCard(
                    context,
                    title: 'Ocorrências',
                    icon: Icons.assignment_late_outlined,
                    color: Colors.orange,
                    onTap: _verOcorrencias,
                    isDarkMode: isDarkMode,
                    cardBgColor: cardColor,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Widget reaproveitável para os cartões de ação
  Widget _buildActionCard(
    BuildContext context, {
    required String title,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
    required bool isDarkMode,
    required Color cardBgColor,
  }) {
    return Card(
      color: cardBgColor,
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  // Fundo do ícone fica um pouquinho mais visível no modo escuro
                  color: color.withOpacity(isDarkMode ? 0.2 : 0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, size: 40, color: color),
              ),
              const SizedBox(height: 16),
              Text(
                title,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: isDarkMode ? Colors.white : const Color(0xFF1E293B),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}