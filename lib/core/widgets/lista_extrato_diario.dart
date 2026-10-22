import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/themes/app_themes.dart';
import '../../../core/utils/feriados_util.dart';
import '../../features/colaborador/controllers/frequencia_controller.dart';

class ListaExtratoDiarioWidget extends StatelessWidget {
  final FrequenciaController controller;

  const ListaExtratoDiarioWidget({super.key, required this.controller});

  String _formatarMinutos(int totalMinutos, {bool mostrarSinal = false}) {
    if (totalMinutos == 0) return '00h00';
    final absMin = totalMinutos.abs();
    final h = (absMin ~/ 60).toString().padLeft(2, '0');
    final m = (absMin % 60).toString().padLeft(2, '0');
    final sinal = mostrarSinal ? (totalMinutos < 0 ? '-' : '+') : '';
    return '$sinal${h}h$m';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [AppThemes.cardShadow(context)],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Extrato Diário do Mês',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 14),
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: controller.totalDiasMes,
            separatorBuilder: (_, __) => const Divider(height: 20),
            itemBuilder: (context, index) {
              final dia = index + 1;
              final info = controller.obterDadosDia(dia);
              final saldoDiaPositivo = info.saldoMinutos >= 0;

              final dataDia = DateTime(controller.mesAtual.year, controller.mesAtual.month, dia);
              final feriado = FeriadosUtil.obterFeriado(dataDia);
              final isFolga = info.isFimDeSemana || feriado != null;

              final textoBatidas = info.batidas.isEmpty
                  ? (feriado ?? (info.isFimDeSemana ? 'Fim de semana' : 'Sem registros'))
                  : info.batidas.map((p) {
                      final dtLocal = p.dataHoraPonto.toLocal();
                      final h = dtLocal.hour.toString().padLeft(2, '0');
                      final m = dtLocal.minute.toString().padLeft(2, '0');
                      return '$h:$m';
                    }).join(' • ');

              return Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: isFolga
                          ? AppColors.error.withOpacity(0.1)
                          : colorScheme.primary.withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: Text(
                        '$dia',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: isFolga ? AppColors.error : colorScheme.primary,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          textoBatidas,
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: info.batidas.isEmpty ? FontWeight.normal : FontWeight.w600,
                            color: (info.batidas.isEmpty && isFolga)
                                ? AppColors.error
                                : (info.batidas.isEmpty ? colorScheme.onSurfaceVariant : colorScheme.onSurface),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Trab: ${_formatarMinutos(info.minutosTrabalhados)}  •  '
                          'Abono: ${_formatarMinutos(info.minutosAbonados)}  •  '
                          'Prev: ${_formatarMinutos(info.minutosPrevistos)}',
                          style: TextStyle(
                            fontSize: 11,
                            color: colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      const Text(
                        'Saldo',
                        style: TextStyle(fontSize: 10, color: Colors.grey),
                      ),
                      Text(
                        _formatarMinutos(
                          info.saldoMinutos,
                          mostrarSinal: true,
                        ),
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: info.saldoMinutos == 0
                              ? colorScheme.onSurfaceVariant
                              : (saldoDiaPositivo ? AppColors.success : AppColors.error),
                        ),
                      ),
                    ],
                  ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}