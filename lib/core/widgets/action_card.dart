import 'package:flutter/material.dart';
import '../../features/usuarios/models/usuario_model.dart';

class ActionCardItem {
  final String title;
  final IconData icon;
  final VoidCallback onTap;
  final Color? iconColor;
  final List<TipoUsuario> cargosPermitidos;

  const ActionCardItem({
    required this.title,
    required this.icon,
    required this.onTap,
    this.iconColor,
    required this.cargosPermitidos,
  });
}

class ActionCardGrid extends StatelessWidget {
  final TipoUsuario tipoUsuario;
  final List<ActionCardItem> itens;

  const ActionCardGrid({
    super.key,
    required this.tipoUsuario,
    required this.itens,
  });

  @override
  Widget build(BuildContext context) {
    final itensPermitidos = itens
        .where((item) => item.cargosPermitidos.contains(tipoUsuario))
        .toList();

    if (itensPermitidos.isEmpty) {
      return const SizedBox.shrink();
    }

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: itensPermitidos.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
      ),
      itemBuilder: (context, index) {
        final item = itensPermitidos[index];
        return ActionCard(
          title: item.title,
          icon: item.icon,
          iconColor: item.iconColor,
          onTap: item.onTap,
        );
      },
    );
  }
}

class ActionCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final VoidCallback onTap;
  final Color? iconColor;

  const ActionCard({
    super.key,
    required this.title,
    required this.icon,
    required this.onTap,
    this.iconColor,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final effectiveColor = iconColor ?? theme.primaryColor;

    return Material(
      color: theme.cardColor,
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: theme.colorScheme.outline.withOpacity(0.4),
            ),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: effectiveColor.withOpacity(0.12),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, size: 34, color: effectiveColor),
              ),
              const SizedBox(height: 16),
              Text(
                title,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: theme.colorScheme.onSurface,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}