import 'package:flutter/material.dart';
import '../../../core/widgets/action_card.dart';
import '../../../core/widgets/custom_app_bar.dart';
import '../../usuarios/models/usuario_model.dart';
import 'bater_ponto_screen.dart';
import 'historico_mensal_screen.dart';

class PainelColaboradorScreen extends StatefulWidget {
  final UsuarioModel usuario;

  const PainelColaboradorScreen({
    super.key,
    required this.usuario,
  });

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
        content: Text('Selecione um dia na Frequência Mensal para registrar ocorrências.'),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      appBar: CustomAppBar(
        nomeUsuario: widget.usuario.nome,
        onPerfilPressed: () {},
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Card(
              elevation: 0,
              color: theme.cardColor,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
                side: BorderSide(color: colorScheme.outline.withOpacity(0.4)),
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
                        color: colorScheme.onSurface,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'O que você deseja fazer hoje?',
                      style: TextStyle(
                        fontSize: 16,
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            Expanded(
              child: GridView.count(
                crossAxisCount: 2,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
                children: [
                  ActionCard(
                    title: 'Bater Ponto',
                    icon: Icons.fingerprint,
                    iconColor: Colors.teal,
                    onTap: _baterPonto,
                  ),
                  ActionCard(
                    title: 'Frequência Mensal',
                    icon: Icons.calendar_month,
                    iconColor: Colors.indigo,
                    onTap: _verFrequencia,
                  ),
                  ActionCard(
                    title: 'Ocorrências',
                    icon: Icons.assignment_late_outlined,
                    iconColor: Colors.orange,
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
}