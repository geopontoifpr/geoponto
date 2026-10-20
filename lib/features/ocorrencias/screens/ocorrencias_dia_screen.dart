import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/themes/app_themes.dart';
import '../../../core/utils/snackbar_util.dart';
import '../../../core/widgets/primary_button.dart';
import '../../colaborador/models/registro_ponto_model.dart';
import '../../usuarios/models/usuario_model.dart';
import '../controllers/ocorrencia_controller.dart';
import '../models/ocorrencia_model.dart';

class OcorrenciasDiaScreen extends StatefulWidget {
  final UsuarioModel usuario;
  final DateTime dataSelecionada;
  final List<RegistroPontoModel> batidasDoDia;
  final List<OcorrenciaModel> ocorrenciasDoDia;
  final Duration totalTrabalhado;

  const OcorrenciasDiaScreen({
    super.key,
    required this.usuario,
    required this.dataSelecionada,
    required this.batidasDoDia,
    required this.ocorrenciasDoDia,
    required this.totalTrabalhado,
  });

  @override
  State<OcorrenciasDiaScreen> createState() => _OcorrenciasDiaScreenState();
}

class _OcorrenciasDiaScreenState extends State<OcorrenciasDiaScreen> {
  final _controller = OcorrenciaController();
  final _assuntoController = TextEditingController();
  final _observacoesController = TextEditingController();

  String? _tipoSelecionado;

  @override
  void dispose() {
    _assuntoController.dispose();
    _observacoesController.dispose();
    _controller.dispose();
    super.dispose();
  }

  String _formatarDataSubtitulo(DateTime d) {
    const meses = [
      'Janeiro', 'Fevereiro', 'Março', 'Abril', 'Maio', 'Junho',
      'Julho', 'Agosto', 'Setembro', 'Outubro', 'Novembro', 'Dezembro'
    ];
    return '${meses[d.month - 1]} ${d.day}, ${d.year}';
  }

  String _formatarHoraMinuto(DateTime? dt) {
    if (dt == null) return '--:--';
    return '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
  }

  String _formatarDuracao(Duration d) {
    final horas = d.inHours.toString().padLeft(2, '0');
    final minutos = (d.inMinutes % 60).toString().padLeft(2, '0');
    return '${horas}h$minutos';
  }

  Future<void> _salvarOcorrencia() async {
    final sucesso = await _controller.salvarOcorrencia(
      usuarioId: widget.usuario.id,
      dataReferencia: widget.dataSelecionada,
      tipoSelecionado: _tipoSelecionado,
      assunto: _assuntoController.text,
      observacoes: _observacoesController.text,
    );

    if (!mounted) return;

    if (sucesso) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Ocorrência registrada com sucesso!'),
          backgroundColor: AppColors.success,
        ),
      );
      Navigator.pop(context, true);
    } else {
      SnackbarUtil.showError(
        context,
        _controller.erroMensagem ?? 'Erro ao registrar ocorrência.',
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    final batidas = List<RegistroPontoModel>.from(widget.batidasDoDia)
      ..sort((a, b) => a.criadoEm.compareTo(b.criadoEm));

    final entrada = batidas.isNotEmpty ? batidas[0].criadoEm : null;
    final inicioIntervalo = batidas.length > 1 ? batidas[1].criadoEm : null;
    final retorno = batidas.length > 2 ? batidas[2].criadoEm : null;
    final saida = batidas.length > 3 ? batidas[3].criadoEm : null;

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Ocorrências',
              style: TextStyle(
                color: colorScheme.onSurface,
                fontWeight: FontWeight.bold,
                fontSize: 18,
              ),
            ),
            Text(
              _formatarDataSubtitulo(widget.dataSelecionada),
              style: TextStyle(
                color: colorScheme.onSurfaceVariant,
                fontSize: 13,
              ),
            ),
          ],
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Registros do dia',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: theme.cardColor,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [AppThemes.cardShadow(context)],
              ),
              child: Column(
                children: [
                  _buildLinhaRegistro(context, 'Entrada', _formatarHoraMinuto(entrada)),
                  const SizedBox(height: 14),
                  _buildLinhaRegistro(context, 'Início do intervalo', _formatarHoraMinuto(inicioIntervalo)),
                  const SizedBox(height: 14),
                  _buildLinhaRegistro(context, 'Retorno', _formatarHoraMinuto(retorno)),
                  const SizedBox(height: 14),
                  _buildLinhaRegistro(context, 'Saída', _formatarHoraMinuto(saida)),
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    child: Divider(height: 1, thickness: 1, color: theme.dividerColor),
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Total trabalhado',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: colorScheme.onSurface,
                        ),
                      ),
                      Text(
                        _formatarDuracao(widget.totalTrabalhado),
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: colorScheme.onSurface,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            if (widget.ocorrenciasDoDia.isNotEmpty) ...[
              const SizedBox(height: 24),
              Text(
                'Solicitações enviadas neste dia',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: colorScheme.onSurface,
                ),
              ),
              const SizedBox(height: 8),
              ...widget.ocorrenciasDoDia.map((oc) {
                final corStatus = oc.aprovada ? AppColors.success : AppColors.warning;
                return Card(
                  color: theme.cardColor,
                  margin: const EdgeInsets.only(bottom: 8),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  child: ListTile(
                    leading: Icon(
                      oc.aprovada ? Icons.check_circle : Icons.pending_actions,
                      color: corStatus,
                    ),
                    title: Text(
                      _controller.tiposOcorrencia[oc.tipoOcorrencia] ?? oc.tipoOcorrencia,
                      style: TextStyle(color: colorScheme.onSurface, fontWeight: FontWeight.bold),
                    ),
                    subtitle: Text(
                      oc.justificativa,
                      style: TextStyle(color: colorScheme.onSurfaceVariant),
                    ),
                    trailing: Text(
                      oc.aprovada ? 'Aprovada' : 'Pendente',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: corStatus,
                      ),
                    ),
                  ),
                );
              }),
            ],
            const SizedBox(height: 24),
            Text(
              'Registrar ocorrência',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: theme.cardColor,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [AppThemes.cardShadow(context)],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Tipo de ocorrência',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: colorScheme.onSurface,
                    ),
                  ),
                  const SizedBox(height: 8),
                  DropdownButtonFormField<String>(
                    value: _tipoSelecionado,
                    dropdownColor: theme.cardColor,
                    style: TextStyle(color: colorScheme.onSurface, fontSize: 16),
                    hint: Text(
                      'Selecione uma ocorrência',
                      style: TextStyle(color: colorScheme.onSurfaceVariant),
                    ),
                    decoration: InputDecoration(
                      fillColor: theme.scaffoldBackgroundColor,
                      filled: true,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: colorScheme.outline),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: colorScheme.outline),
                      ),
                    ),
                    items: _controller.tiposOcorrencia.entries
                        .map((e) => DropdownMenuItem(
                              value: e.key,
                              child: Text(e.value),
                            ))
                        .toList(),
                    onChanged: (val) => setState(() => _tipoSelecionado = val),
                  ),
                  const SizedBox(height: 18),
                  Text(
                    'Assunto',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: colorScheme.onSurface,
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _assuntoController,
                    style: TextStyle(color: colorScheme.onSurface),
                    decoration: InputDecoration(
                      fillColor: theme.scaffoldBackgroundColor,
                      filled: true,
                      hintText: 'Informe o assunto',
                      hintStyle: TextStyle(color: colorScheme.onSurfaceVariant),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: colorScheme.outline),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: colorScheme.outline),
                      ),
                    ),
                  ),
                  const SizedBox(height: 18),
                  Text(
                    'Observações',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: colorScheme.onSurface,
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _observacoesController,
                    style: TextStyle(color: colorScheme.onSurface),
                    maxLines: 4,
                    decoration: InputDecoration(
                      fillColor: theme.scaffoldBackgroundColor,
                      filled: true,
                      hintText: 'Descreva a ocorrência...',
                      hintStyle: TextStyle(color: colorScheme.onSurfaceVariant),
                      contentPadding: const EdgeInsets.all(16),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: colorScheme.outline),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: colorScheme.outline),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  ListenableBuilder(
                    listenable: _controller,
                    builder: (context, _) {
                      return SizedBox(
                        width: double.infinity,
                        child: PrimaryButton(
                          onPressed: _controller.salvando ? null : _salvarOcorrencia,
                          isLoading: _controller.salvando,
                          text: 'Enviar Ocorrência',
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLinhaRegistro(BuildContext context, String label, String valor) {
    final colorScheme = Theme.of(context).colorScheme;
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 15,
            color: colorScheme.onSurfaceVariant,
          ),
        ),
        Text(
          valor,
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w600,
            color: colorScheme.onSurface,
          ),
        ),
      ],
    );
  }
}