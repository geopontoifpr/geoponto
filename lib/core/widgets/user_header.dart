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
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

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
            color: isDark ? Colors.blueGrey[200] : const Color(0xFF94A3B8),
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
                color: isDark ? Colors.white : const Color(0xFF1E293B),
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