import 'package:flutter/material.dart';
import '../../features/usuarios/models/usuario_model.dart';
import '../themes/app_themes.dart';

class UsuarioList extends StatelessWidget {
  final UsuarioModel membro;
  final VoidCallback onEdit;
  final VoidCallback onToggleStatus;

  const UsuarioList({
    Key? key,
    required this.membro,
    required this.onEdit,
    required this.onToggleStatus,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isGestor = membro.tipoUsuario.name.toUpperCase() == 'GESTOR';
    
    String subtitulo = isGestor ? 'Gestor' : 'Funcionário';
    subtitulo += ' • ${membro.setorNome ?? 'Setor não vinculado'}';
    if (!membro.ativo) subtitulo += ' • Inativo';

    return ListTile(
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
          color: membro.ativo ? theme.textTheme.bodyLarge?.color : theme.disabledColor,
        )
      ),
      subtitle: Text(subtitulo),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            icon: Icon(Icons.edit, color: theme.primaryColor),
            onPressed: onEdit, // Chama a função que a tela passou
          ),
          IconButton(
            icon: Icon(
              membro.ativo ? Icons.block : Icons.check_circle, 
              color: membro.ativo ? AppThemes.errorColor : Colors.green, 
            ),
            onPressed: onToggleStatus, // Chama a função que a tela passou
          ),
        ],
      ),
    );
  }
}