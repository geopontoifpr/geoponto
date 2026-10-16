import 'package:flutter/material.dart';
import '../../usuarios/models/usuario_model.dart';
import '../../../core/widgets/custom_app_bar.dart';
import 'bater_ponto_screen.dart';


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
    // TODO: Navegar para a tela de calendário/frequência mensal
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Histórico de Frequência em breve!'),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _verOcorrencias() {
    // TODO: Navegar para a tela de ocorrências (faltas, atestados, justificativas)
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

    return Scaffold(
      // Usando o seu widget padronizado! A lógica de sair já é tratada lá.
      appBar: CustomAppBar(
        nomeUsuario: widget.usuario.nome, // Passa o nome do colaborador
        onPerfilPressed: () {
          // TODO: Navegar para a tela de edição de perfil, se desejar
        },
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Saudação Personalizada (Reaproveitando as cores do AppThemes pelo theme do contexto)
            Card(
              elevation: 0,
              color: theme.primaryColor.withOpacity(0.1),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Olá, ${widget.usuario.nome.split(' ').first}!', // Exibe apenas o primeiro nome
                      style: theme.textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: theme.primaryColor,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'O que você deseja fazer hoje?',
                      style: TextStyle(fontSize: 16, color: Colors.black54),
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
                  ),
                  _buildActionCard(
                    context,
                    title: 'Frequência Mensal',
                    icon: Icons.calendar_month,
                    color: Colors.indigo,
                    onTap: _verFrequencia,
                  ),
                  _buildActionCard(
                    context,
                    title: 'Ocorrências',
                    icon: Icons.assignment_late_outlined,
                    color: Colors.orange,
                    onTap: _verOcorrencias,
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
  }) {
    return Card(
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
                  color: color.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, size: 40, color: color),
              ),
              const SizedBox(height: 16),
              Text(
                title,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}