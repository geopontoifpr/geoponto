import 'package:flutter/material.dart';

class FiltroOcorrenciasChips extends StatelessWidget {
  final bool pendentes;
  final ValueChanged<bool> onChanged;
  
  const FiltroOcorrenciasChips({super.key, required this.pendentes, required this.onChanged});

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
    child: Wrap(spacing: 8, children: [
      ChoiceChip(label: const Text('Pendentes'), selected: pendentes, onSelected: (_) => onChanged(true)),
      ChoiceChip(label: const Text('Respondidas'), selected: !pendentes, onSelected: (_) => onChanged(false)),
    ]),
  );
}