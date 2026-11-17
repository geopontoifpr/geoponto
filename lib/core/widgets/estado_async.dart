import 'package:material_ui/material_ui.dart';

class EstadoAsync extends StatelessWidget {
  final bool carregando;
  final bool vazio;
  final String? erro;
  final String mensagemVazio;
  final VoidCallback? onTentarNovamente;
  final Widget child;
  
  const EstadoAsync({
    super.key, 
    required this.carregando, 
    required this.vazio,
    required this.child, 
    this.erro, 
    this.mensagemVazio = '', 
    this.onTentarNovamente,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    if (carregando) return const Center(child: CircularProgressIndicator());
    if (erro != null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min, 
          children: [
            Text(erro!, textAlign: TextAlign.center, style: TextStyle(color: cs.error)),
            if (onTentarNovamente != null)
              TextButton.icon(
                onPressed: onTentarNovamente,
                icon: const Icon(Icons.refresh), 
                label: const Text('Tentar novamente'),
              ),
          ]
        )
      );
    }
    if (vazio) return Center(child: Text(mensagemVazio, style: TextStyle(color: cs.onSurfaceVariant)));
    return child;
  }
}