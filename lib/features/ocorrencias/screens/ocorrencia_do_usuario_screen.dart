// features/ocorrencias/screens/ocorrencia_do_usuario_screen.dart
import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/themes/app_themes.dart';
import '../../usuarios/models/usuario_model.dart';
import '../controllers/ocorrencia_controller.dart';
import '../models/ocorrencia_model.dart';

class OcorrenciaDoUsuarioScreen extends StatefulWidget {
  final UsuarioModel colaborador;
  final UsuarioModel gestorLogado;

  const OcorrenciaDoUsuarioScreen({
    super.key,
    required this.colaborador,
    required this.gestorLogado,
  });

  @override
  State<OcorrenciaDoUsuarioScreen> createState() =>
      _OcorrenciaDoUsuarioScreenState();
}

class _OcorrenciaDoUsuarioScreenState extends State<OcorrenciaDoUsuarioScreen> {
  final _controller = OcorrenciaController();
  final DateTime _mes = DateTime.now();

  static const _meses = [
    'Janeiro', 'Fevereiro', 'Março', 'Abril', 'Maio', 'Junho',
    'Julho', 'Agosto', 'Setembro', 'Outubro', 'Novembro', 'Dezembro'
  ];

  @override
  void initState() {
    super.initState();
    _carregar();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _carregar() =>
      _controller.carregarDoMes(widget.colaborador.id, _mes);

  String _fmtData(DateTime d) =>
      '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}';



      

  (Color, String, IconData) _status(OcorrenciaModel oc) {
    if (oc.aprovada) {
      return (
        AppColors.success,
        'Aprovada (${oc.minutosAbonados ?? oc.minutosPropostos} min)',
        Icons.check_circle
      );
    }
    if (oc.isRecusada) {
      return (AppColors.error, 'Recusada', Icons.cancel);
    }
    return (AppColors.warning, 'Pendente', Icons.pending_actions);
  }

  void _abrirOcorrencia(OcorrenciaModel oc) {
    // TODO: navegar para a tela de avaliação (aprovar/recusar) quando existir.
    // Ex.: Navigator.push(context, MaterialPageRoute(builder: (_) =>
    //   AvaliarOcorrenciaScreen(ocorrencia: oc, gestorLogado: widget.gestorLogado)));
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.colaborador.nome,
              style: TextStyle(
                color: cs.onSurface,
                fontWeight: FontWeight.bold,
                fontSize: 18,
              ),
            ),
            Text(
              'Ocorrências de ${_meses[_mes.month - 1]} de ${_mes.year}',
              style: TextStyle(color: cs.onSurfaceVariant, fontSize: 13),
            ),
          ],
        ),
      ),
      body: ListenableBuilder(
        listenable: _controller,
        builder: (context, _) {
          if (_controller.carregando) {
            return Center(
              child: CircularProgressIndicator(color: theme.primaryColor),
            );
          }

          if (_controller.erroMensagem != null) {
            return Center(
              child: Text(
                _controller.erroMensagem!,
                style: const TextStyle(color: AppThemes.errorColor),
                textAlign: TextAlign.center,
              ),
            );
          }

          final lista = _controller.ocorrenciasDoMes;
          if (lista.isEmpty) {
            return const Center(
              child: Text('Nenhuma ocorrência neste mês.'),
            );
          }

          return RefreshIndicator(
            onRefresh: _carregar,
            child: ListView.separated(
              padding: const EdgeInsets.all(20),
              itemCount: lista.length,
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemBuilder: (context, i) {
                final oc = lista[i];
                final (cor, texto, icone) = _status(oc);

                return InkWell(
                  borderRadius: BorderRadius.circular(16),
                  onTap: () => _abrirOcorrencia(oc),
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: theme.cardColor,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [AppThemes.cardShadow(context)],
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Column(
                          children: [
                            Text(
                                
                              _fmtData(oc.dataInicio),
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                                color: cs.onSurface,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                oc.tipoOcorrencia.titulo,
                                style: TextStyle(
                                  fontWeight: FontWeight.w600,
                                  color: cs.onSurface,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                '${oc.minutosPropostos} min solicitados',
                                style: TextStyle(
                                  fontSize: 13,
                                  color: cs.onSurfaceVariant,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Row(
                                children: [
                                  Icon(icone, size: 16, color: cor),
                                  const SizedBox(width: 6),
                                  Text(
                                    texto,
                                    style: TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.bold,
                                      color: cor,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        Icon(Icons.chevron_right, color: cs.onSurfaceVariant),
                      ],
                    ),
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }
}