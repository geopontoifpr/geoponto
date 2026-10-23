import 'package:flutter/material.dart';
import '../../../core/utils/feriados_util.dart';
import '../../features/usuarios/models/usuario_model.dart';
import '../../features/colaborador/controllers/frequencia_controller.dart';
import '../../features/colaborador/services/extrato_pdf_service.dart';

class BotaoImprimirPdfWidget extends StatelessWidget {
  final FrequenciaController controller;
  final UsuarioModel colaborador;
  final String nomeGestor;

  const BotaoImprimirPdfWidget({
    super.key,
    required this.controller,
    required this.colaborador,
    required this.nomeGestor,
  });

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
    final colorScheme = Theme.of(context).colorScheme;

    return SizedBox(
      height: 54,
      child: OutlinedButton.icon(
        onPressed: () async {
          try {
            final extrato = controller.calcularExtratoDetalhado();
            final diasInfo = List.generate(controller.totalDiasMes, (index) {
              final dia = index + 1;
              final info = controller.obterDadosDia(dia);
              return {
                'dia': dia,
                'isFimDeSemana': info.isFimDeSemana,
                'nomeFeriado': FeriadosUtil.obterFeriado(DateTime(controller.mesAtual.year, controller.mesAtual.month, dia)),
                'batidas': info.batidas,
                'horasTrabalhadas': _formatarMinutos(info.minutosTrabalhados),
                'saldoMinutos': _formatarMinutos(info.saldoMinutos, mostrarSinal: true),
              };
            });

            List<String> jornadasFmt = [];
            if (controller.jornadasDoMes.isEmpty) {
              jornadasFmt.add('Regime da jornada de trabalho: ${controller.cargaHorariaSemanalPadrao}h');
            } else {
              for (var vinculo in controller.jornadasDoMes) {
                final jornadaData = vinculo['jornadas_trabalho'];
                final carga = (jornadaData is Map && jornadaData['carga_horaria_sem'] != null)
                    ? (jornadaData['carga_horaria_sem'] as num).toInt()
                    : controller.cargaHorariaSemanalPadrao;
                
                String formatarDataIso(String? dataIso) {
                  if (dataIso == null) return 'Atual';
                  final d = DateTime.tryParse(dataIso);
                  if (d == null) return 'Atual';
                  return '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}';
                }

                final inicio = formatarDataIso(vinculo['data_inicio_vigencia']?.toString());
                final fim = formatarDataIso(vinculo['data_fim_vigencia']?.toString());
                jornadasFmt.add('Jornada ${carga}h - $inicio até $fim');
              }
            }

            await ExtratoPdfService.gerarEImprimirPdf(
              nomeColaborador: colaborador.nome,
              nomeGestor: nomeGestor,
              nomeSetor: colaborador.setorNome ?? 'Não informado',
              jornadasText: jornadasFmt,
              nomeMes: controller.nomeMesAtual,
              ano: controller.mesAtual.year,
              horasPrevistas: _formatarMinutos(extrato.minutosPrevistos),
              horasTrabalhadas: _formatarMinutos(extrato.minutosTrabalhados),
              horasAbonadas: _formatarMinutos(extrato.minutosAbonados),
              saldoFinal: _formatarMinutos(extrato.saldoMinutos, mostrarSinal: true),
              dias: diasInfo,
            );
          } catch (e) {
            if (context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Erro ao gerar documento: $e'), backgroundColor: Colors.red),
              );
            }
          }
        },
        icon: const Icon(Icons.print),
        label: const Text('Imprimir Relatório Mensal', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
        style: OutlinedButton.styleFrom(
          foregroundColor: colorScheme.primary,
          side: BorderSide(color: colorScheme.primary, width: 1.5),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        ),
      ),
    );
  }
}