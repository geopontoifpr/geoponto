import 'package:flutter/material.dart';
import '../../features/usuarios/models/usuario_model.dart';

class UserHeader extends StatelessWidget {
  final String nome;
  final String? setorNome;
  final TipoUsuario tipoUsuario;

  const UserHeader({
    super.key,
    required this.nome,
    this.setorNome,
    required this.tipoUsuario,
  });

  String get _primeiroNome => nome.trim().split(' ').first;
  String get _inicial =>
      _primeiroNome.isNotEmpty ? _primeiroNome[0].toUpperCase() : 'U';

  String get _perfil {
    switch (tipoUsuario) {
      case TipoUsuario.administrador:
        return 'Administrador(a)';
      case TipoUsuario.gestor:
        return 'Gestor(a)';
      default:
        return 'Funcionário(a)';
    }
  }

  String get _complemento {
    if (tipoUsuario == TipoUsuario.administrador) return _perfil;
    final setor = (setorNome == null || setorNome!.trim().isEmpty)
        ? 'Setor não informado'
        : setorNome!;
    return '$_perfil do setor - $setor';
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
      child: Row(
        children: [
          CircleAvatar(
            radius: 20,
            backgroundColor: cs.primary.withOpacity(0.12),
            child: Text(
              _inicial,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: cs.primary,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Olá, $_primeiroNome 👋',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: cs.onSurface,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  _complemento,
                  style: TextStyle(
                    fontSize: 12.5,
                    color: cs.onSurfaceVariant,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}