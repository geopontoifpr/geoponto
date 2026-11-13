import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/themes/app_themes.dart';
import '../models/ocorrencia_model.dart';

class OcorrenciaCard extends StatelessWidget {
  final OcorrenciaModel ocorrencia;
  final String dataFormatada;
  final Future<void> Function(OcorrenciaModel ocorrencia, bool aprovar)? onAvaliar;
  final Future<void> Function(OcorrenciaModel ocorrencia)? onReabrir;
  final VoidCallback? onEditar; // NOVO

  const OcorrenciaCard({
    super.key,
    required this.ocorrencia,
    required this.dataFormatada,
    this.onAvaliar,
    this.onReabrir,
    this.onEditar,
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
          
          // BOTÃO DE EDITAR (Aparece apenas para quem passou o onEditar)
          if (onEditar != null && ocorrencia.isPendente)
            Padding(
              padding: const EdgeInsets.only(top: 16),
              child: SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: onEditar,
                  icon: const Icon(Icons.edit_outlined),
                  label: const Text('Editar Ocorrência'),
                ),
              ),
            ),
            
          // BOTÃO DE TORNAR PENDENTE (Aparece apenas para o Gestor, se passou onReabrir)
          if (oc.foiAvaliada && onReabrir != null) ...[
            const SizedBox(height: 14),
            OutlinedButton.icon(
              onPressed: () => onReabrir!(oc),
              icon: const Icon(Icons.undo),
              label: const Text('Tornar pendente novamente'),
            ),
          ],
          
          // BOTÕES DE APROVAR/RECUSAR (Aparece apenas para o Gestor, se passou onAvaliar)
          if (onAvaliar != null && ocorrencia.isPendente) ...[
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => onAvaliar!(ocorrencia, false),
                    icon: const Icon(Icons.cancel_outlined, color: AppColors.error),
                    label: const Text('Recusar', style: TextStyle(color: AppColors.error)),
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: AppColors.error),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: FilledButton.icon(
                    onPressed: () => onAvaliar!(ocorrencia, true),
                    icon: const Icon(Icons.check_circle_outline),
                    label: const Text('Aprovar'),
                    style: FilledButton.styleFrom(
                      backgroundColor: AppColors.success,
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
