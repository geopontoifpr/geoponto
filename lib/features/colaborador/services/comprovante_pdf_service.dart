import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import '../../usuarios/models/usuario_model.dart';
import '../../admin/models/empresa_model.dart';
import '../models/registro_ponto_model.dart';

class ComprovantePdfService {
  static Future<void> gerarEImprimirComprovante({
    required UsuarioModel usuario,
    required EmpresaModel empresa,
    required RegistroPontoModel registro,
  }) async {
    final pdf = pw.Document();

    final dataHora = registro.criadoEm.toLocal();
    final dataFormatada = "${dataHora.day.toString().padLeft(2, '0')}/${dataHora.month.toString().padLeft(2, '0')}/${dataHora.year}";
    final horaFormatada = "${dataHora.hour.toString().padLeft(2, '0')}:${dataHora.minute.toString().padLeft(2, '0')}:${dataHora.second.toString().padLeft(2, '0')}";
    final font = await PdfGoogleFonts.robotoRegular();
    final fontBold = await PdfGoogleFonts.robotoBold();

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a5,
        margin: const pw.EdgeInsets.all(32),
        theme: pw.ThemeData.withFont(
          base: font,
          bold: fontBold,
        ),
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Center(
                child: pw.Text(
                  'Comprovante de Registro de Ponto do Trabalhador\n(CRPT)',
                  // 2. Agora você pode usar FontWeight normal, o pacote puxa o fontBold do tema
                  style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold),
                  textAlign: pw.TextAlign.center,
                ),
              ),
              pw.SizedBox(height: 20),
              pw.Divider(),
              pw.SizedBox(height: 10),
              
              pw.Text('EMPREGADOR', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 10)),
              // O restante do seu código permanece igual, 
              // mas agora todos suportam acentos automaticamente!
              pw.Text('Razão Social: ${empresa.nome ?? "Não informado"}', style: const pw.TextStyle(fontSize: 12)),
              pw.Text('CNPJ: ${empresa.cnpj ?? "Não informado"}', style: const pw.TextStyle(fontSize: 12)),
              pw.SizedBox(height: 16),
              
              pw.Text('TRABALHADOR', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 10)),
              pw.Text('Nome: ${usuario.nome}', style: const pw.TextStyle(fontSize: 12)),
              pw.Text('CPF: ${usuario.cpf}', style: const pw.TextStyle(fontSize: 12)),
              pw.SizedBox(height: 16),
              
              pw.Text('DADOS DO REGISTRO', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 10)),
              pw.Text('Data: $dataFormatada', style: const pw.TextStyle(fontSize: 12)),
              pw.Text('Hora: $horaFormatada', style: const pw.TextStyle(fontSize: 12)),
              pw.Text('Fuso Horário: UTC-3 (Horário de Brasília)', style: const pw.TextStyle(fontSize: 12)),
              pw.Text('Tipo de Batida: ${registro.tipoRegistro.titulo}', style: const pw.TextStyle(fontSize: 12)),
              pw.SizedBox(height: 30),
              
              pw.Divider(),
              pw.SizedBox(height: 10),
              pw.Center(
                child: pw.Text(
                  'Documento gerado eletronicamente. Não requer assinatura.',
                  style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey700),
                ),
              ),
            ],
          );
        },
      ),
    );

    await Printing.sharePdf(
      bytes: await pdf.save(),
      filename: 'Comprontante Ponto - _${usuario.cpf}_${dataHora.millisecondsSinceEpoch}.pdf',
    );
  }
}