import 'package:flutter/material.dart';

import '../constants/app_colors.dart';
import '../../features/usuarios/models/usuario_model.dart';
import '../../features/admin/models/empresa_model.dart';
import '../../features/colaborador/models/registro_ponto_model.dart';
import '../../features/colaborador/services/comprovante_pdf_service.dart'; 

class ComprovanteDialog extends StatelessWidget {
  final UsuarioModel usuario;
  final EmpresaModel empresa;
  final RegistroPontoModel registro;

  const ComprovanteDialog({
    super.key,
    required this.usuario,
    required this.empresa,
    required this.registro,
  });

  @override
  Widget build(BuildContext context) {
    final dataHora = registro.criadoEm.toLocal();
    final hora = '${dataHora.hour.toString().padLeft(2, '0')}:${dataHora.minute.toString().padLeft(2, '0')}';
    final data = '${dataHora.day.toString().padLeft(2, '0')}/${dataHora.month.toString().padLeft(2, '0')}/${dataHora.year}';

    return AlertDialog(
      title: const Row(
        children: [
          Icon(Icons.check_circle, color: AppColors.success),
          SizedBox(width: 10),
          Expanded(
            child: Text(
              'Ponto Registrado!',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
      content: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Comprovante de Registro (CRPT)',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            const Divider(),
            const SizedBox(height: 8),
            const Text('EMPREGADOR', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
            Text(empresa.nome ?? 'Não informado', style: const TextStyle(fontSize: 14)),
            Text('CNPJ: ${empresa.cnpj ?? "Não informado"}', style: const TextStyle(fontSize: 12)),
            const SizedBox(height: 12),
            const Text('TRABALHADOR', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
            Text(usuario.nome, style: const TextStyle(fontSize: 14)),
            Text('CPF: ${usuario.cpf}', style: const TextStyle(fontSize: 12)),
            const SizedBox(height: 12),
            const Text('DADOS DO REGISTRO', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
            Text('Data: $data', style: const TextStyle(fontSize: 14)),
            Text('Hora: $hora', style: const TextStyle(fontSize: 14)),
            const Text('Fuso: UTC-3', style: TextStyle(fontSize: 12)),
            const SizedBox(height: 4),
            Text('Tipo: ${registro.tipoRegistro.titulo}', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Fechar'),
        ),
        ElevatedButton.icon(
          icon: const Icon(Icons.download),
          label: const Text('Comprovante PDF'),
          onPressed: () {
            // Chamada limpa e direta ao serviço externo
            ComprovantePdfService.gerarEImprimirComprovante(
              usuario: usuario,
              empresa: empresa,
              registro: registro,
            );
          },
        ),
      ],
    );
  }
}