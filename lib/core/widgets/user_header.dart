import 'package:flutter/material.dart';
import '../../features/usuarios/models/usuario_model.dart'; // Ajuste o caminho do import do seu model

class UserHeader extends StatelessWidget {
  final String nome;
  final String? setorNome;
  final TipoUsuario tipoUsuario; // <-- Agora recebe o Enum diretamente

  const UserHeader({
    super.key,
    required this.nome,
    this.setorNome,
    required this.tipoUsuario,
  });

  String get _primeiroNome => nome.trim().split(' ').first;
  String get _inicial => _primeiroNome.isNotEmpty ? _primeiroNome[0].toUpperCase() : 'U';

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    // Lógica corrigida utilizando o Enum
    String complemento;
    if (tipoUsuario == TipoUsuario.administrador) {
      complemento = 'Administrador(a) da empresa.';
    } else if (tipoUsuario == TipoUsuario.gestor) {
      complemento = 'Gestor(a) do setor ${setorNome ?? 'Não informado'}.';
    } else {
      complemento = 'Funcionário(a) do setor ${setorNome ?? 'Não informado'}.';
    }

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: colorScheme.shadow.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
        border: Border.all(
          color: colorScheme.outlineVariant.withOpacity(0.5),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          // Avatar com a inicial do nome
          CircleAvatar(
            radius: 28,
            backgroundColor: colorScheme.primary.withOpacity(0.1),
            child: Text(
              _inicial,
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: colorScheme.primary,
              ),
            ),
          ),
          const SizedBox(width: 16),
          // Textos
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'GEOPONTO',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1.5,
                    color: colorScheme.primary,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        'Olá, $_primeiroNome',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: colorScheme.onSurface,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 4),
                    const Text('👋', style: TextStyle(fontSize: 16)),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  complemento,
                  style: TextStyle(
                    fontSize: 13,
                    color: colorScheme.onSurfaceVariant,
                    height: 1.3,
                  ),
                  maxLines: 2,
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