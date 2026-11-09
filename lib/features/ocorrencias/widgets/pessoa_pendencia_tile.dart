import 'package:flutter/material.dart';
import '../../usuarios/models/usuario_model.dart';

class PessoaPendenciaTile extends StatelessWidget {
  final UsuarioModel pessoa;
  final VoidCallback onTap;

  const PessoaPendenciaTile({
    super.key,
    required this.pessoa,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Card(
      color: theme.cardColor,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: colorScheme.outlineVariant),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 18,
          vertical: 8,
        ),
        leading: CircleAvatar(
          backgroundColor: colorScheme.primaryContainer,
          foregroundColor: colorScheme.onPrimaryContainer,
          child: const Icon(Icons.person_outline),
        ),
        title: Text(
          pessoa.nome,
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        subtitle: Text(
          pessoa.tipoUsuario == TipoUsuario.gestor ? 'Gestor' : 'Colaborador',
        ),
        trailing: const Icon(Icons.chevron_right),
        onTap: onTap,
      ),
    );
  }
}
