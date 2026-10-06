import 'package:flutter/material.dart';
import '../../../core/widgets/custom_text_field.dart';
import '../../../core/widgets/primary_button.dart';
import '../../../core/errors/app_exception.dart';
import '../models/empresa_model.dart';
import '../controllers/empresa_controller.dart';

class CadastroEmpresaScreen extends StatefulWidget {
  final EmpresaModel? empresa;

  const CadastroEmpresaScreen({super.key, this.empresa});

  @override
  State<CadastroEmpresaScreen> createState() => _CadastroEmpresaScreenState();
}

class _CadastroEmpresaScreenState extends State<CadastroEmpresaScreen> {
  final _controller = EmpresaController();
  
  final _nomeController = TextEditingController();
  final _cnpjController = TextEditingController();
  final _latitudeController = TextEditingController();
  final _longitudeController = TextEditingController();
  final _raioController = TextEditingController(text: '50');

  @override
  void initState() {
    super.initState();
    if (widget.empresa != null) {
      final e = widget.empresa!;
      _nomeController.text = e.nome ?? '';
      _cnpjController.text = e.cnpj ?? '';
      _latitudeController.text = e.latitude?.toString() ?? ''; // Corrigido
      _longitudeController.text = e.longitude?.toString() ?? ''; // Corrigido
      _raioController.text = e.raioPermitido?.toString() ?? ''; // Corrigido
    }
  }

  @override
  void dispose() {
    _nomeController.dispose();
    _cnpjController.dispose();
    _latitudeController.dispose();
    _longitudeController.dispose();
    _raioController.dispose();
    _controller.dispose();
    super.dispose();
  }

  Future<void> _salvar() async {
    FocusScope.of(context).unfocus();

    try {
      await _controller.submeterFormulario(
        idAtual: widget.empresa?.id,
        nome: _nomeController.text,
        cnpj: _cnpjController.text,
        latTexto: _latitudeController.text,
        lngTexto: _longitudeController.text,
        raioTexto: _raioController.text,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Empresa salva com sucesso!'), backgroundColor: Colors.green),
        );
        Navigator.pop(context);
      }
    } on AppException catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.mensagem), backgroundColor: e.cor, behavior: SnackBarBehavior.floating),
      );
    } catch (_) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Erro inesperado.'), backgroundColor: Colors.red, behavior: SnackBarBehavior.floating),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final ehEdicao = widget.empresa != null;

    return Scaffold(
      appBar: AppBar(
        title: Text(ehEdicao ? 'Editar Empresa' : 'Cadastrar Empresa'),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Dados da Organização', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: theme.textTheme.bodyLarge?.color)),
            const SizedBox(height: 24),

            CustomTextField(controller: _nomeController, labelText: 'Nome da Empresa', prefixIcon: Icons.business_outlined),
            const SizedBox(height: 16),
            CustomTextField(controller: _cnpjController, labelText: 'CNPJ (Somente números)', prefixIcon: Icons.badge_outlined),
            
            const SizedBox(height: 24),
            Text('Geolocalização (Sede Principal)', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: theme.textTheme.bodyLarge?.color)),
            const SizedBox(height: 16),

            Row(
              children: [
                Expanded(child: CustomTextField(controller: _latitudeController, labelText: 'Latitude', prefixIcon: Icons.map_outlined)),
                const SizedBox(width: 16),
                Expanded(child: CustomTextField(controller: _longitudeController, labelText: 'Longitude', prefixIcon: Icons.map_outlined)),
              ],
            ),
            const SizedBox(height: 16),
            CustomTextField(controller: _raioController, labelText: 'Raio de Tolerância (Metros)', prefixIcon: Icons.radar_outlined),
            
            const SizedBox(height: 32),

            ListenableBuilder(
              listenable: _controller,
              builder: (context, _) {
                return PrimaryButton(
                  onPressed: _controller.isLoading ? null : _salvar,
                  isLoading: _controller.isLoading,
                  text: ehEdicao ? 'Salvar Alterações' : 'Cadastrar Empresa',
                );
              }
            ),
          ],
        ),
      ),
    );
  }
}