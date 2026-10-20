import 'package:flutter/material.dart';

class UserHeader extends StatelessWidget {
  final String nome;

  const UserHeader({
    super.key,
    required this.nome,
  });

  String get _primeiroNome => nome.trim().split(' ').first;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'GEOPONTO',
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w700,
            letterSpacing: 1.2,
            color: colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 2),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Olá, $_primeiroNome',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: colorScheme.onSurface,
              ),
            ),
            const SizedBox(width: 4),
            const Text(
              '👋',
              style: TextStyle(fontSize: 14),
            ),
          ],
        ),
      ],
    );
  }
}