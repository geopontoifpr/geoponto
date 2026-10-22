import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import '../models/registro_ponto_model.dart';

class ExtratoPdfService {
  static Future<void> gerarEImprimirPdf({
    required String nomeColaborador,
    required String nomeGestor,
    required String nomeSetor,
    required List<String> jornadasText,
    required String nomeMes,
    required int ano,
    required String horasPrevistas,
    required String horasTrabalhadas,
    required String horasAbonadas,
    required String saldoFinal,
    required List<Map<String, dynamic>> dias,
  }) async {
    final pdf = pw.Document();

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.symmetric(vertical: 24, horizontal: 32),
        build: (context) => [
          _buildCabecalho(nomeMes, ano),
          pw.SizedBox(height: 12),
          _buildResumo(
            nomeSetor,
            nomeColaborador, 
            jornadasText, 
            horasPrevistas, 
            horasTrabalhadas, 
            horasAbonadas, 
            saldoFinal,
          ),
          pw.SizedBox(height: 12),
          _buildTabela(dias),
          pw.SizedBox(height: 40),
          _buildAssinaturas(nomeColaborador, nomeGestor),
        ],
      ),
    );

    await Printing.sharePdf(
      bytes: await pdf.save(),
      filename: 'Relatório $nomeMes $nomeColaborador.pdf',
    );
  }

  static pw.Widget _buildCabecalho(String mes, int ano) {
    return pw.Center(
      child: pw.Column(
        children: [
          pw.Text(
            'EXTRATO MENSAL DE FREQUÊNCIA', 
            style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold),
          ),
          pw.SizedBox(height: 4),
          pw.Text('Período: $mes / $ano', style: const pw.TextStyle(fontSize: 11)),
        ],
      ),
    );
  }

  static pw.Widget _buildResumo(
    String nomeSetor,
    String nome, 
    List<String> jornadas, 
    String prev, 
    String trab, 
    String abon, 
    String saldo,
  ) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(8),
      decoration: pw.BoxDecoration(border: pw.Border.all(width: 0.5)),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
              
        children: [
          pw.Text(
                'Colaborador(a): $nome', 
                style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold),
              ),
              pw.Text(
                'Setor: $nomeSetor', 
                style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold),
              ),
          pw.Divider(thickness: 0.5),
          
          // Jornadas adicionadas dentro do quadro, antes do Previsto/Trab/Abon
          ...jornadas.map((j) => pw.Padding(
            padding: const pw.EdgeInsets.only(bottom: 6),
            child: pw.Text(j, style: const pw.TextStyle(fontSize: 10)),
          )),

          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Text('Horas Previstas: $prev', style: const pw.TextStyle(fontSize: 10)),
              pw.Text('Horas Trabalhadas: $trab', style: const pw.TextStyle(fontSize: 10)),
              pw.Text('Horas Abonadas: $abon', style: const pw.TextStyle(fontSize: 10)),
            ],
          ),
          pw.SizedBox(height: 4),
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Text('Saldo do Mês:', style: pw.TextStyle(fontSize: 11, fontWeight: pw.FontWeight.bold)),
              pw.Text(saldo, style: pw.TextStyle(fontSize: 11, fontWeight: pw.FontWeight.bold)),
            ],
          ),
        ],
      ),
    );
  }

  static pw.Widget _buildTabela(List<Map<String, dynamic>> dias) {
    return pw.TableHelper.fromTextArray(
      headers: ['Dia', 'Registros', 'Trab.', 'Saldo'],
      cellPadding: const pw.EdgeInsets.symmetric(vertical: 3, horizontal: 4),
      cellStyle: const pw.TextStyle(fontSize: 9),
      headerStyle: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold),
      headerDecoration: const pw.BoxDecoration(color: PdfColors.grey300),
      cellAlignment: pw.Alignment.centerLeft,
      data: dias.map((info) {
        final diaStr = info['dia'].toString().padLeft(2, '0');
        final batidas = info['batidas'] as List<RegistroPontoModel>;
        final txtBatidas = batidas.isEmpty
            ? (info['isFimDeSemana'] ? (info['nomeFeriado'] ?? 'Fim de semana') : '-')
            : batidas.map((p) => '${p.dataHoraPonto.toLocal().hour.toString().padLeft(2, '0')}:${p.dataHoraPonto.toLocal().minute.toString().padLeft(2, '0')}').join(' • ');

        return [diaStr, txtBatidas, info['horasTrabalhadas'], info['saldoMinutos']];
      }).toList(),
    );
  }

  static pw.Widget _buildAssinaturas(String nomeColaborador, String nomeGestor) {
    return pw.Row(
      children: [
        pw.Expanded(
          child: pw.Column(
            children: [
              pw.Container(height: 1, color: PdfColors.black),
              pw.SizedBox(height: 4),
              pw.Text(nomeGestor, style: const pw.TextStyle(fontSize: 10)),
              pw.Text('Gestor(a)', style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey700)),
            ],
          ),
        ),
        pw.SizedBox(width: 40),
        pw.Expanded(
          child: pw.Column(
            children: [
              pw.Container(height: 1, color: PdfColors.black),
              pw.SizedBox(height: 4),
              pw.Text(nomeColaborador, style: const pw.TextStyle(fontSize: 10)),
              pw.Text('Colaborador(a)', style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey700)),
            ],
          ),
        ),
      ],
    );
  }
}