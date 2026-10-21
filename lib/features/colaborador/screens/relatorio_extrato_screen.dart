import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/widgets/custom_app_bar.dart';
import '../../usuarios/models/usuario_model.dart';
import '../models/registro_ponto_model.dart';

class RelatorioExtratoScreen extends StatelessWidget {
  final UsuarioModel colaborador;
  final String nomeMes;
  final int ano;
  final String horasPrevistas;
  final String horasTrabalhadas;
  final String horasAbonadas;
  final String saldoFinal;
  final bool saldoPositivo;
  final List<Map<String, dynamic>> dias;

  const RelatorioExtratoScreen({
    super.key,
    required this.colaborador,
    required this.nomeMes,
    required this.ano,
    required this.horasPrevistas,
    required this.horasTrabalhadas,
    required this.horasAbonadas,
    required this.saldoFinal,
    required this.saldoPositivo,
    required this.dias,
  });

  String _formatarBatidas(List<RegistroPontoModel> batidas) {
    if (batidas.isEmpty) return '-';
    return batidas.map((p) {
      final dt = p.dataHoraPonto.toLocal();
      return '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
    }).join(' • ');
  }

  String _formatarMinutos(int totalMinutos, {bool mostrarSinal = false}) {
    if (totalMinutos == 0) return '00h00';
    final negativo = totalMinutos < 0;
    final absMin = totalMinutos.abs();
    final h = (absMin ~/ 60).toString().padLeft(2, '0');
    final m = (absMin % 60).toString().padLeft(2, '0');
    final sinal = mostrarSinal ? (negativo ? '-' : '+') : '';
    return '$sinal${h}h$m';
  }

  @override
  Widget build(BuildContext context) {
    // Usamos um fundo branco para simular papel impresso
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: const CustomAppBar(nomeUsuario: 'Relatório de Ponto'),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // CABEÇALHO DO DOCUMENTO
            Center(
              child: Column(
                children: [
                  const Text(
                    'EXTRATO MENSAL DE FREQUÊNCIA',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.black,
                      letterSpacing: 1.2,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Período: $nomeMes / $ano',
                    style: const TextStyle(fontSize: 15, color: Colors.black87),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),
            
            // DADOS DO COLABORADOR E TOTAIS
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.black26),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Colaborador(a): ${colaborador.nome}',
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.black)),
                  const Divider(color: Colors.black26),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Previsto: $horasPrevistas', style: const TextStyle(color: Colors.black87)),
                      Text('Trabalhado: $horasTrabalhadas', style: const TextStyle(color: Colors.black87)),
                      Text('Abonado: $horasAbonadas', style: const TextStyle(color: Colors.black87)),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Saldo do Mês:', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black)),
                      Text(
                        saldoFinal,
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: saldoPositivo ? Colors.green[700] : Colors.red[700],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),

            // TABELA DE PONTOS DIÁRIOS
            Table(
              border: TableBorder.all(color: Colors.black12),
              columnWidths: const {
                0: FixedColumnWidth(40), // Dia
                1: FlexColumnWidth(2),   // Batidas
                2: FlexColumnWidth(1),   // Trab
                3: FlexColumnWidth(1),   // Saldo
              },
              children: [
                // Cabeçalho da Tabela
                TableRow(
                  decoration: BoxDecoration(color: Colors.grey[200]),
                  children: const [
                    Padding(padding: EdgeInsets.all(8.0), child: Text('Dia', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Colors.black))),
                    Padding(padding: EdgeInsets.all(8.0), child: Text('Registros', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Colors.black))),
                    Padding(padding: EdgeInsets.all(8.0), child: Text('Trab.', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Colors.black))),
                    Padding(padding: EdgeInsets.all(8.0), child: Text('Saldo', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Colors.black))),
                  ],
                ),
                // Linhas dos Dias
                ...dias.map((diaInfo) {
                  final dia = diaInfo['dia'];
                  final isFds = diaInfo['isFimDeSemana'] as bool;
                  final batidas = diaInfo['batidas'] as List<RegistroPontoModel>;
                  final trab = diaInfo['minutosTrabalhados'] as int;
                  final saldo = diaInfo['saldoMinutos'] as int;

                  return TableRow(
                    decoration: BoxDecoration(color: isFds ? Colors.grey[50] : Colors.white),
                    children: [
                      Padding(padding: const EdgeInsets.all(8.0), child: Text(dia.toString().padLeft(2, '0'), style: const TextStyle(color: Colors.black87))),
                      Padding(padding: const EdgeInsets.all(8.0), child: Text(_formatarBatidas(batidas), style: const TextStyle(fontSize: 12, color: Colors.black87))),
                      Padding(padding: const EdgeInsets.all(8.0), child: Text(_formatarMinutos(trab), style: const TextStyle(fontSize: 12, color: Colors.black87))),
                      Padding(padding: const EdgeInsets.all(8.0), child: Text(
                        _formatarMinutos(saldo, mostrarSinal: true),
                        style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: saldo > 0 ? Colors.green[700] : (saldo < 0 ? Colors.red[700] : Colors.black54)),
                      )),
                    ],
                  );
                }),
              ],
            ),
            const SizedBox(height: 64),

            // CAMPOS DE ASSINATURA (Rodapé)
            Row(
              children: [
                Expanded(
                  child: Column(
                    children: [
                      Container(height: 1, width: double.infinity, color: Colors.black),
                      const SizedBox(height: 8),
                      const Text(
                        'Assinatura do Gestor',
                        style: TextStyle(fontSize: 12, color: Colors.black),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 40),
                Expanded(
                  child: Column(
                    children: [
                      Container(height: 1, width: double.infinity, color: Colors.black),
                      const SizedBox(height: 8),
                      Text(
                        colaborador.nome,
                        textAlign: TextAlign.center,
                        style: const TextStyle(fontSize: 12, color: Colors.black),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const Text(
                        'Colaborador(a)',
                        style: TextStyle(fontSize: 10, color: Colors.black54),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 40),
            
            // Botão de Imprimir (Apenas visual para a versão web/mobile)
            Center(
              child: ElevatedButton.icon(
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Para gerar um PDF real, tire um print ou utilize um pacote como "printing".'),
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                },
                icon: const Icon(Icons.print),
                label: const Text('Imprimir / Salvar PDF'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}