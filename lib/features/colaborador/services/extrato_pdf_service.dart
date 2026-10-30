import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import '../models/registro_ponto_model.dart';
import '../../ocorrencias/models/ocorrencia_model.dart';

class ExtratoPdfService {
  static Future<void> gerarEImprimirPdf({
    required String nomeColaborador,
    required String cpf,
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

    final font = await PdfGoogleFonts.robotoRegular();
    final fontBold = await PdfGoogleFonts.robotoBold();
   

    pdf.addPage(
      // 1. Trocamos MultiPage por Page
      pw.Page(
        pageFormat: PdfPageFormat.a4, 
        margin: const pw.EdgeInsets.symmetric(vertical: 24, horizontal: 24),
        theme: pw.ThemeData.withFont(
          base: font,
          bold: fontBold,
        ),
        build: (context) {
          // 2. Envolvemos tudo no FittedBox
          return pw.FittedBox(
            fit: pw.BoxFit.fill, // Escala o conteúdo para baixo se for maior que a página
            child: pw.Container(
              // 3. Fixamos a largura do container para a área útil do A4 em modo paisagem
              width: PdfPageFormat.a4.width - 48, // 48 é a soma das margens (24 + 24)
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.stretch,
                children: [
                  _buildCabecalho(nomeMes, ano),
                  pw.SizedBox(height: 12),
                  _buildResumo(nomeSetor, cpf, nomeColaborador, jornadasText, horasPrevistas, horasTrabalhadas, horasAbonadas, saldoFinal),
                  pw.SizedBox(height: 12),
                  _buildTabela(dias, ano, nomeMes), 
                  pw.SizedBox(height: 40),
                  _buildAssinaturas(nomeColaborador, nomeGestor),
                ],
              ),
            ),
          );
        },
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
    String cpf,
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
                'CPF: $cpf', 
                style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold),
              ),
              pw.Text(
                'Funcionário(a): $nome', 
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
              pw.Text('Horas Previstas no mês: $prev', style: const pw.TextStyle(fontSize: 10)),
              pw.Text('Horas Trabalhadas no mês: $trab', style: const pw.TextStyle(fontSize: 10)),
              pw.Text('Horas Abonadas pelo gestor: $abon', style: const pw.TextStyle(fontSize: 10)),
            ],
          ),
          pw.SizedBox(height: 4),
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Text('Saldo Final do Mês:', style: pw.TextStyle(fontSize: 11, fontWeight: pw.FontWeight.bold)),
              pw.Text(saldo, style: pw.TextStyle(fontSize: 11, fontWeight: pw.FontWeight.bold)),
            ],
          ),
        ],
      ),
    );
  }

  static pw.Widget _buildTabela(List<Map<String, dynamic>> dias, int ano, String mesNome) {
    // Definimos os cabeçalhos
    final headers = [
      'Data', 
      'Horários Registrados\n(Batidas / Ocorrências)', 
      'Carga\nHorária\nDiária', 
      'Horas\nTrabalhadas', 
      'Horas\nAbonadas', 
      'Débito\n(Atraso)', 
      'Crédito\n(Extra)', 
      'Saldo\ndo Dia', 
      'Saldo\nAcumulado'
    ];

    return pw.Table(
      border: pw.TableBorder.all(color: PdfColors.grey400, width: 0.5),
      columnWidths: {
        0: const pw.FixedColumnWidth(50),
        1: const pw.FlexColumnWidth(2),
        2: const pw.FlexColumnWidth(1),
        3: const pw.FlexColumnWidth(1),
        4: const pw.FlexColumnWidth(1),
        5: const pw.FlexColumnWidth(1),
        6: const pw.FlexColumnWidth(1),
        7: const pw.FlexColumnWidth(1),
        8: const pw.FlexColumnWidth(1),
      },
      children: [
        // 1. CABEÇALHO DA TABELA
        pw.TableRow(
          decoration: const pw.BoxDecoration(color: PdfColor.fromInt(0xFF3B4A6B)),
          children: headers.map((h) => pw.Container(
            padding: const pw.EdgeInsets.symmetric(vertical: 4, horizontal: 4),
            alignment: pw.Alignment.center,
            child: pw.Text(
              h,
              textAlign: pw.TextAlign.center,
              style: pw.TextStyle(
                fontSize: 9,
                fontWeight: pw.FontWeight.bold,
                color: PdfColors.white, // Fonte branca no fundo azul
              ),
            ),
          )).toList(),
        ),
        
        // 2. LINHAS DOS DIAS
        ...dias.map((info) {
          final diaStr = '${info['dia'].toString().padLeft(2, '0')}/${mesNome == "Setembro" ? "09" : "10"}/$ano';
          
          final batidas = info['batidas'] as List<RegistroPontoModel>;
          final ocorrencias = info['ocorrencias'] as List<dynamic>;

          String txtRegistros = '';

          // Verifica se é final de semana ou se tem nome de feriado
          final bool isFimDeSemana = info['isFimDeSemana'] == true;
          final bool isFeriado = info['nomeFeriado'] != null;

          if (batidas.isEmpty && ocorrencias.isEmpty) {
              txtRegistros = isFimDeSemana 
                  ? (info['nomeFeriado'] ?? 'Fim de semana') 
                  : (info['nomeFeriado'] ?? '---');
          } else {
              if (batidas.isNotEmpty) {
                txtRegistros = batidas.map((p) => '${p.dataHoraPonto.toLocal().hour.toString().padLeft(2, '0')}:${p.dataHoraPonto.toLocal().minute.toString().padLeft(2, '0')}').join(' - ');
              }
              if (ocorrencias.isNotEmpty) {
                 final textoOcorrencia = ocorrencias.map((o) => '${o.tipoOcorrencia.titulo}').join(', ');
                 txtRegistros += txtRegistros.isEmpty ? textoOcorrencia : '\n($textoOcorrencia)';
              }
          }

          // LÓGICA DA COR: Se for fim de semana ou feriado, pinta de vermelho escuro
          final textColor = (isFimDeSemana || isFeriado) ? PdfColors.red800 : PdfColors.black;
          final textStyle = pw.TextStyle(fontSize: 8, color: textColor);

          // Dados exatos que irão preencher a linha
          final rowData = [
            diaStr,
            txtRegistros,
            info['hrPrevistas'],
            info['hrTrabalhadas'],
            info['hrAbonadas'],
            info['atrasosFaltas'],
            info['hrExtras'],
            info['saldoDia'],
            info['saldoAcumulado'],
          ];

          return pw.TableRow(
            children: rowData.map((cellData) => pw.Container(
              padding: const pw.EdgeInsets.symmetric(vertical: 4, horizontal: 4),
              alignment: pw.Alignment.center,
              child: pw.Text(
                cellData.toString(),
                textAlign: pw.TextAlign.center,
                style: textStyle, // Aplica o estilo colorido na célula
              ),
            )).toList(),
          );
        }),
      ],
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