import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/themes/app_themes.dart';
import '../../../core/utils/snackbar_util.dart';
import '../../usuarios/models/usuario_model.dart';
import '../controllers/ocorrencia_controller.dart';
import '../models/ocorrencia_model.dart';

class OcorrenciasGestorScreen extends StatefulWidget {
  final UsuarioModel gestor;
  final OcorrenciaController? controller;

  const OcorrenciasGestorScreen({
    super.key,
    required this.gestor,
    this.controller,
  });

  @override
  State<OcorrenciasGestorScreen> createState() => _OcorrenciasGestorScreenState();
}

class _OcorrenciasGestorScreenState extends State<OcorrenciasGestorScreen> {
  late final OcorrenciaController _controller;
  late final bool _possuiControllerExterno;

  @override
  void initState() {
    super.initState();
    _possuiControllerExterno = widget.controller != null;
    _controller = widget.controller ?? OcorrenciaController();
    _controller.carregarOcorrenciasGestor(widget.gestor.id);
  }

  @override
  void dispose() {
    if (!_possuiControllerExterno) {
      _controller.dispose();
    }
    super.dispose();
  }

  String _formatarData(DateTime d) {
    return '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';
  }

  Future<void> _confirmarAvaliacao({
    required OcorrenciaModel ocorrencia,
    required bool aprovar,
    required String observacaoGestor,
  }) async {
    final acaoTexto = aprovar ? 'aceitar' : 'recusar';

    final confirmar = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(aprovar ? 'Aceitar Ocorrência?' : 'Recusar Ocorrência?'),
        content: Text(
          'Tem certeza que deseja $acaoTexto esta ocorrência'
          '${aprovar && ocorrencia.minutosPropostos > 0 ? ' e abonar ${ocorrencia.minutosPropostos} minutos' : ''}?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: aprovar ? AppColors.success : AppColors.error,
              foregroundColor: Colors.white,
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(aprovar ? 'Sim, Aceitar' : 'Sim, Recusar'),
          ),
        ],
      ),
    );

    if (confirmar != true || !mounted) return;

    final sucesso = await _controller.avaliarOcorrencia(
      ocorrencia: ocorrencia,
      aprovar: aprovar,
      observacaoGestor: observacaoGestor,
      gestorId: widget.gestor.id,
    );

    if (!mounted) return;

    if (sucesso) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            aprovar
                ? 'Ocorrência aprovada com sucesso!'
                : 'Ocorrência recusada.',
          ),
          backgroundColor: aprovar ? AppColors.success : AppColors.warning,
        ),
      );
    } else {
      SnackbarUtil.showError(
        context,
        _controller.erroMensagem ?? 'Erro ao avaliar ocorrência.',
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return ListenableBuilder(
      listenable: _controller,
      builder: (context, _) {
        if (_controller.carregando) {
          return const Center(child: CircularProgressIndicator());
        }

        if (_controller.ocorrenciasGestor.isEmpty) {
          return Center(
            child: Text(
              'Nenhuma ocorrência enviada pela equipe.',
              style: TextStyle(color: colorScheme.onSurfaceVariant, fontSize: 16),
            ),
          );
        }

        return RefreshIndicator(
          onRefresh: () => _controller.carregarOcorrenciasGestor(widget.gestor.id),
          child: ListView.separated(
            padding: const EdgeInsets.all(20),
            itemCount: _controller.ocorrenciasGestor.length,
            separatorBuilder: (_, __) => const SizedBox(height: 16),
            itemBuilder: (context, index) {
              final oc = _controller.ocorrenciasGestor[index];
              return _OcorrenciaGestorCard(
                ocorrencia: oc,
                dataFormatada: _formatarData(oc.dataInicio),
                onAvaliar: (aprovar, obs) => _confirmarAvaliacao(
                  ocorrencia: oc,
                  aprovar: aprovar,
                  observacaoGestor: obs,
                ),
              );
            },
          ),
        );
      },
    );
  }
}

class _OcorrenciaGestorCard extends StatefulWidget {
  final OcorrenciaModel ocorrencia;
  final String dataFormatada;
  final void Function(bool aprovar, String observacao) onAvaliar;

  const _OcorrenciaGestorCard({
    required this.ocorrencia,
    required this.dataFormatada,
    required this.onAvaliar,
  });

  @override
  State<_OcorrenciaGestorCard> createState() => _OcorrenciaGestorCardState();
}

class _OcorrenciaGestorCardState extends State<_OcorrenciaGestorCard> {
  late final TextEditingController _obsGestorController;

  @override
  void initState() {
    super.initState();
    _obsGestorController = TextEditingController(
      text: widget.ocorrencia.observacaoGestor ?? '',
    );
  }

  @override
  void dispose() {
    _obsGestorController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final oc = widget.ocorrencia;

    final Color badgeBg;
    final Color badgeText;
    final String labelStatus;

    if (oc.aprovada) {
      badgeBg = const Color(0xFFE8F5E9);
      badgeText = const Color(0xFF2E7D32);
      labelStatus = 'Aprovada';
    } else if (oc.isRecusada) {
      badgeBg = const Color(0xFFFFEBEE);
      badgeText = const Color(0xFFC62828);
      labelStatus = 'Recusada';
    } else {
      badgeBg = const Color(0xFFFFF3E0);
      badgeText = const Color(0xFFD97757);
      labelStatus = 'Pendente';
    }

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [AppThemes.cardShadow(context)],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.dataFormatada,
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                        color: colorScheme.onSurface,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      oc.nomeUsuario != null
                          ? '${oc.nomeUsuario} • ${oc.tipoOcorrencia.titulo}'
                          : oc.tipoOcorrencia.titulo,
                      style: TextStyle(
                        fontSize: 14,
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                    if (oc.minutosPropostos > 0) ...[
                      const SizedBox(height: 2),
                      Text(
                        'Abono solicitado: ${oc.minutosPropostos} min (${oc.horarioProposto ?? ''})',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: theme.primaryColor,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                decoration: BoxDecoration(
                  color: badgeBg,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  labelStatus,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: badgeText,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Quadro de Observação do Colaborador (igual à 4ª imagem)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: colorScheme.surfaceContainerHighest.withOpacity(0.6),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Observação',
                  style: TextStyle(
                    fontSize: 13,
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  oc.justificativa,
                  style: TextStyle(
                    fontSize: 15,
                    color: colorScheme.onSurface,
                    height: 1.3,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 12),

          // Quadro para Observação do Gestor (observacao_gestor)
          TextField(
            controller: _obsGestorController,
            enabled: oc.isPendente,
            style: TextStyle(color: colorScheme.onSurface, fontSize: 14),
            decoration: InputDecoration(
              labelText: 'Observação do gestor (opcional)',
              labelStyle: TextStyle(color: colorScheme.onSurfaceVariant, fontSize: 13),
              filled: true,
              fillColor: theme.scaffoldBackgroundColor,
              contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: colorScheme.outline),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: colorScheme.outline),
              ),
            ),
          ),

          if (oc.isPendente) ...[
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: SizedBox(
                    height: 48,
                    child: ElevatedButton(
                      onPressed: () =>
                          widget.onAvaliar(false, _obsGestorController.text),
                      style: ElevatedButton.styleFrom(
                        elevation: 0,
                        backgroundColor: const Color(0xFFFDE8E8),
                        foregroundColor: const Color(0xFFE02424),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      child: const Text(
                        'Recusar',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: SizedBox(
                    height: 48,
                    child: ElevatedButton(
                      onPressed: () =>
                          widget.onAvaliar(true, _obsGestorController.text),
                      style: ElevatedButton.styleFrom(
                        elevation: 0,
                        backgroundColor: const Color(0xFFE8F5E9),
                        foregroundColor: const Color(0xFF2E7D32),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      child: const Text(
                        'Aceitar',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}