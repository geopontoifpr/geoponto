import 'package:flutter/material.dart';
import '../../features/usuarios/models/usuario_model.dart';
import '../themes/app_themes.dart';

class UsuarioList extends StatelessWidget {
  final UsuarioModel membro;
  final VoidCallback? onEdit;
  final VoidCallback? onToggleStatus;
  final VoidCallback? onTap;

  const UsuarioList({
    super.key,
    required this.membro,
    this.onEdit,
    this.onToggleStatus,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isGestor = membro.tipoUsuario == TipoUsuario.gestor;

    String subtitulo = isGestor ? 'Gestor' : 'Funcionário';
    subtitulo += ' • ${membro.setorNome ?? 'Setor não vinculado'}';
    if (!membro.ativo) subtitulo += ' • Inativo';

    final temAcoes = onEdit != null || onToggleStatus != null;

    return ListTile(
      onTap: onTap,
      leading: CircleAvatar(
        backgroundColor: membro.ativo ? theme.primaryColor : theme.disabledColor,
        child: Icon(
          isGestor ? Icons.manage_accounts : Icons.person,
          color: Colors.white,
        ),
      ),
      title: Text(
        membro.nome,
        style: TextStyle(
          fontWeight: FontWeight.bold,
          decoration: membro.ativo ? null : TextDecoration.lineThrough,
          color: membro.ativo
              ? theme.textTheme.bodyLarge?.color
              : theme.disabledColor,
        ),
      ),
      subtitle: Text(subtitulo),
      trailing: temAcoes
          ? Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (onEdit != null)
                  IconButton(
                    icon: Icon(Icons.edit, color: theme.primaryColor),
                    onPressed: onEdit,
                  ),
                if (onToggleStatus != null)
                  IconButton(
                    icon: Icon(
                      membro.ativo ? Icons.block : Icons.check_circle,
                      color: membro.ativo ? AppThemes.errorColor : Colors.green,
                    ),
                    onPressed: onToggleStatus,
                  ),
              ],
            )
          : (onTap != null ? const Icon(Icons.chevron_right) : null),
    );
  }
}