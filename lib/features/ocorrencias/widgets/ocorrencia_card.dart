import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/themes/app_themes.dart';
import '../models/ocorrencia_model.dart';

class OcorrenciaCard extends StatelessWidget {
  final OcorrenciaModel ocorrencia;
  final String dataFormatada;
  final Future<void> Function(OcorrenciaModel ocorrencia, bool aprovar) onAvaliar;
  final Future<void> Function(OcorrenciaModel ocorrencia)? onReabrir;

  const OcorrenciaCard({
    required this.ocorrencia,
    required this.dataFormatada,
    required this.onAvaliar,
    this.onReabrir,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final OcorrenciaModel oc = ocorrencia;

    final Color corStatus;
    final String status;
    final IconData iconeStatus;
    if (oc.aprovada) {
      corStatus = AppColors.success;
      status = 'Aprovada';
      iconeStatus = Icons.check_circle_outline;
    } else if (oc.isRecusada) {
      corStatus = AppColors.error;
      status = 'Recusada';
      iconeStatus = Icons.cancel_outlined;
    } else {
      corStatus = AppColors.warning;
      status = 'Pendente';
      iconeStatus = Icons.pending_actions;
    }

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [AppThemes.cardShadow(context)],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      dataFormatada,
                      style: TextStyle(
                        color: cs.onSurface,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      oc.tipoOcorrencia.titulo,
                      style: TextStyle(color: cs.onSurfaceVariant),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Chip(
                avatar: Icon(iconeStatus, size: 16, color: corStatus),
                label: Text(status),
                side: BorderSide.none,
                backgroundColor: corStatus.withValues(alpha: 0.12),
                labelStyle: TextStyle(
                  color: corStatus,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          if (oc.minutosPropostos > 0) ...[
            const SizedBox(height: 10),
            Text(
              'Abono solicitado: ${oc.minutosPropostos} minutos',
              style: TextStyle(
                color: cs.primary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
          const SizedBox(height: 12),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: cs.surfaceContainerHighest.withValues(alpha: 0.55),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              oc.justificativa,
              style: TextStyle(color: cs.onSurface, height: 1.35),
            ),
          ),
          if (oc.observacaoGestor != null &&
              oc.observacaoGestor!.trim().isNotEmpty) ...[
            const SizedBox(height: 10),
            Text(
              'Observação da avaliação: ${oc.observacaoGestor}',
              style: TextStyle(color: cs.onSurfaceVariant, fontSize: 13),
            ),
          ],
          if (oc.isPendente) ...[
            const SizedBox(height: 14),
            Wrap(
              spacing: 10,
              runSpacing: 8,
              children: [
                FilledButton.icon(
                  onPressed: () => onAvaliar(oc, true),
                  icon: const Icon(Icons.check),
                  label: const Text('Aprovar'),
                ),
                OutlinedButton.icon(
                  onPressed: () => onAvaliar(oc, false),
                  icon: const Icon(Icons.close),
                  label: const Text('Recusar'),
                ),
              ],
            ),
          ],
          if (oc.foiAvaliada && onReabrir != null) ...[
            const SizedBox(height: 14),
            OutlinedButton.icon(
              onPressed: () => onReabrir!(oc),
              icon: const Icon(Icons.undo),
              label: const Text('Tornar pendente novamente'),
            ),
          ],
        ],
      ),
    );
  }
}
