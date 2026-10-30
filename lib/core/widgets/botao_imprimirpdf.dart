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

  String _formatarMinutos(int totalMinutos, {bool mostrarSinal = false, bool ocultarZero = false}) {
    if (totalMinutos == 0) return ocultarZero ? '---' : '00:00';
    final absMin = totalMinutos.abs();
    final h = (absMin ~/ 60).toString().padLeft(2, '0');
    final m = (absMin % 60).toString().padLeft(2, '0');
    final sinal = mostrarSinal ? (totalMinutos < 0 ? '-' : '+') : '';
    return '$sinal$h:$m'; // Mudado de 'h' para ':' para igualar ao espelho contábil
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
            int saldoAcumulado = 0; // Para calcular a última coluna (Crédito Acumulado)

            final diasInfo = List.generate(controller.totalDiasMes, (index) {
              final dia = index + 1;
              final info = controller.obterDadosDia(dia);
              
              // Lógica contábil do saldo: 
              // Saldo do dia é o que passou (ou faltou) da jornada prevista + abonos
              int minutosTrabalhados = info.minutosTrabalhados;
              int minutosPrevistos = info.minutosPrevistos;
              int minutosAbonados = info.minutosAbonados;
              
              int horasExtras = 0;
              int atrasosFaltas = 0;
              int saldoDoDia = info.saldoMinutos; 
              
              if (saldoDoDia > 0) {
                horasExtras = saldoDoDia;
              } else if (saldoDoDia < 0) {
                atrasosFaltas = saldoDoDia;
              }

              saldoAcumulado += saldoDoDia;

              return {
                'dia': dia.toString().padLeft(2, '0'),
                'isFimDeSemana': info.isFimDeSemana,
                'nomeFeriado': FeriadosUtil.obterFeriado(DateTime(controller.mesAtual.year, controller.mesAtual.month, dia)),
                'batidas': info.batidas,
                'ocorrencias': controller.ocorrenciasPorDia[dia] ?? [], // Pega direto do mapa do controller
                'hrPrevistas': _formatarMinutos(minutosPrevistos, ocultarZero: true),
                'hrTrabalhadas': _formatarMinutos(minutosTrabalhados, ocultarZero: true),
                'hrExtras': _formatarMinutos(horasExtras, ocultarZero: true),
                'hrAbonadas': _formatarMinutos(minutosAbonados, ocultarZero: true), // Abono/HA
                'atrasosFaltas': _formatarMinutos(atrasosFaltas, mostrarSinal: true, ocultarZero: true), // Débito
                'saldoDia': _formatarMinutos(saldoDoDia, mostrarSinal: true),
                'saldoAcumulado': _formatarMinutos(saldoAcumulado, mostrarSinal: true),
              };
            });

            List<String> jornadasFmt = [];
              // Função auxiliar para formatar a data. Retorna null se não houver data válida (Atual)
              String? formatarDataIso(String? dataIso) {
                if (dataIso == null) return null;
                final d = DateTime.tryParse(dataIso);
                if (d == null) return null;
                return '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}';
              }

              if (controller.jornadasDoMes.isEmpty) {
                // Cenário 1: Nenhuma jornada configurada, usa o padrão do sistema
                jornadasFmt.add('Jornada de trabalho contratada para o mês corrente: ${controller.cargaHorariaSemanalPadrao}h semanais.');
              } else if (controller.jornadasDoMes.length == 1) {
                // Cenário 2: Apenas uma jornada no mês
                final vinculo = controller.jornadasDoMes.first;
                final jornadaData = vinculo['jornadas_trabalho'];
                final carga = (jornadaData is Map && jornadaData['carga_horaria_sem'] != null)
                    ? (jornadaData['carga_horaria_sem'] as num).toInt()
                    : controller.cargaHorariaSemanalPadrao;
                
                final inicio = formatarDataIso(vinculo['data_inicio_vigencia']?.toString());
                final fim = formatarDataIso(vinculo['data_fim_vigencia']?.toString());

                if (inicio != null && fim != null) {
                  jornadasFmt.add('Jornada de trabalho contratada para o mês corrente: Do dia $inicio até $fim, ${carga}h semanais.');
                } else if (inicio != null && fim == null) {
                  jornadasFmt.add('Jornada de trabalho contratada para o mês corrente: Do dia $inicio em diante, ${carga}h semanais.');
                } else {
                  jornadasFmt.add('Jornada de trabalho contratada para o mês corrente: ${carga}h semanais.');
                }
              } else {
                // Cenário 3: Múltiplas jornadas no mês (troca de turno/contrato)
                jornadasFmt.add('Jornadas de trabalho contratadas para o mês corrente:');
                
                for (var vinculo in controller.jornadasDoMes) {
                  final jornadaData = vinculo['jornadas_trabalho'];
                  final carga = (jornadaData is Map && jornadaData['carga_horaria_sem'] != null)
                      ? (jornadaData['carga_horaria_sem'] as num).toInt()
                      : controller.cargaHorariaSemanalPadrao;

                  final inicio = formatarDataIso(vinculo['data_inicio_vigencia']?.toString());
                  final fim = formatarDataIso(vinculo['data_fim_vigencia']?.toString());

                  if (inicio != null && fim != null) {
                    jornadasFmt.add('Do dia $inicio até $fim, jornada de trabalho de ${carga}h semanais.');
                  } else if (inicio != null && fim == null) {
                    jornadasFmt.add('Do dia $inicio em diante, jornada de trabalho de ${carga}h semanais.');
                  } else if (inicio == null && fim != null) {
                    jornadasFmt.add('Até o dia $fim, jornada de trabalho de ${carga}h semanais.');
                  } else {
                    jornadasFmt.add('Jornada de trabalho de ${carga}h semanais.');
                  }
                }
              }

            await ExtratoPdfService.gerarEImprimirPdf(
              nomeColaborador: colaborador.nome,
              nomeGestor: nomeGestor,
              cpf: colaborador.cpf ?? 'Não informado',
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