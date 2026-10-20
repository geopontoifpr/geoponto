import 'package:flutter/material.dart';
import '../../../core/themes/app_themes.dart';
import '../../../core/widgets/action_card.dart';
import '../../../core/widgets/custom_app_bar.dart';
import '../../admin/screens/equipe_screen.dart';
import '../../colaborador/screens/bater_ponto_screen.dart';
import '../../usuarios/models/usuario_model.dart';

class PainelGestorScreen extends StatelessWidget {
  final UsuarioModel usuario;

  const PainelGestorScreen({super.key, required this.usuario});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      appBar: CustomAppBar(
        nomeUsuario: usuario.nome,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24.0),
              decoration: BoxDecoration(
                color: theme.cardColor,
                borderRadius: BorderRadius.circular(24),
                boxShadow: [AppThemes.cardShadow(context)],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Painel de Gestão',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.2,
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    usuario.setorNome ?? 'Setor não identificado',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: colorScheme.onSurface,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Gestor Responsável',
                    style: TextStyle(
                      color: theme.primaryColor,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),
            Text(
              'Acesso Rápido',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: 16),
            GridView.count(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisCount: 2,
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
              children: [
                ActionCard(
                  title: 'Bater\nPonto',
                  icon: Icons.fingerprint,
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => BaterPontoScreen(usuario: usuario),
                      ),
                    );
                  },
                ),
                ActionCard(
                  title: 'Minha\nEquipe',
                  icon: Icons.people_alt_outlined,
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => EquipeScreen(
                          empresaId: usuario.empresaId!,
                          usuarioLogado: usuario,
                        ),
                      ),
                    );
                  },
                ),
                ActionCard(
                  title: 'Relatórios\nde Ponto',
                  icon: Icons.insert_chart_outlined,
                  onTap: () {},
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}