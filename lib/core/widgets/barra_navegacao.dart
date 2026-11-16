import 'package:flutter/material.dart';
import '../constants/app_colors.dart';
import 'efeito_agua.dart';

class AlertaBadge extends StatelessWidget {
  final Widget child;
  final bool visivel;
  
  const AlertaBadge({super.key, required this.child, required this.visivel});

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      alignment: Alignment.center,
      children: [
        child,
        if (visivel)
          Positioned(
            top: -5,
            right: -8,
            child: Container(
              width: 16,
              height: 16,
              decoration: BoxDecoration(
                color: AppColors.error,
                shape: BoxShape.circle,
                border: Border.all(color: Theme.of(context).cardColor, width: 1.5),
              ),
              child: const Center(
                child: Text('!', style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w900, height: 1.0)),
              ),
            ),
          ),
      ],
    );
  }
}

class ItemNavegacao {
  final String label;
  final IconData icon;
  final bool alerta;
  const ItemNavegacao(this.label, this.icon, {this.alerta = false});
}

class BarraNavegacao extends StatelessWidget {
  final List<ItemNavegacao> itens;
  final int atual;
  final ValueChanged<int> onTap;

  const BarraNavegacao({super.key, required this.itens, required this.atual, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      decoration: BoxDecoration(
        color: theme.cardColor,
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 12, offset: const Offset(0, -2))],
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              for (var i = 0; i < itens.length; i++)
                Expanded(
                  child: _ItemNavegacaoUnico(
                    item: itens[i],
                    ativo: i == atual,
                    onTap: () => onTap(i),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ItemNavegacaoUnico extends StatelessWidget {
  final ItemNavegacao item;
  final bool ativo;
  final VoidCallback onTap;

  const _ItemNavegacaoUnico({required this.item, required this.ativo, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final corAtiva = AppColors.progressGreen;
    final corInativa = theme.colorScheme.onSurfaceVariant;

    return EfeitoAgua(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      cor: corAtiva.withOpacity(0.2),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AlertaBadge(
              visivel: item.alerta,
              child: Icon(item.icon, size: 24, color: ativo ? corAtiva : corInativa),
            ),
            const SizedBox(height: 4),
            Text(
                item.label,
                maxLines: 2, // <-- Altere de 1 para 2
                textAlign: TextAlign.center, // <-- Adicione para o texto quebrado ficar alinhado ao centro
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                    fontSize: 10, // Se ainda ficar apertado, você pode reduzir para 9 ou 9.5
                    fontWeight: ativo ? FontWeight.w800 : FontWeight.w600,
                    letterSpacing: 0.4,
                    color: ativo ? corAtiva : corInativa,
                    height: 1.1, // <-- Adicione para diminuir o espaço entre as duas linhas
                ),
            ),
            const SizedBox(height: 4),
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: 5,
              height: 5,
              decoration: BoxDecoration(shape: BoxShape.circle, color: ativo ? corAtiva : Colors.transparent),
            ),
          ],
        ),
      ),
    );
  }
}