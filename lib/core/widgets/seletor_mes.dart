import 'package:material_ui/material_ui.dart';
import '../utils/formatadores.dart';

class SeletorMes extends StatelessWidget {
  final DateTime mes;
  final ValueChanged<int> onMudar; // -1 = anterior, +1 = próximo
  final bool bloquearFuturo;

  const SeletorMes({
    super.key,
    required this.mes,
    required this.onMudar,
    this.bloquearFuturo = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final agora = DateTime.now();
    final noMesAtual = mes.year == agora.year && mes.month == agora.month;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      color: theme.cardColor,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(
            icon: const Icon(Icons.chevron_left),
            onPressed: () => onMudar(-1),
          ),
          Text(
            '${Formatadores.meses[mes.month - 1]} ${mes.year}',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: theme.colorScheme.onSurface,
            ),
          ),
          IconButton(
            icon: const Icon(Icons.chevron_right),
            onPressed: (bloquearFuturo && noMesAtual) ? null : () => onMudar(1),
          ),
        ],
      ),
    );
  }
}