import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/themes/app_themes.dart';
import '../../../core/utils/snackbar_util.dart';
import '../../../core/widgets/primary_button.dart';
import '../../usuarios/models/usuario_model.dart';
import '../controllers/ocorrencia_controller.dart';
import '../models/ocorrencia_model.dart';

class OcorrenciaFormWidget extends StatefulWidget {
  final UsuarioModel usuario;
  final DateTime dataReferencia;
  final OcorrenciaModel? ocorrenciaExistente;
  final VoidCallback onConcluido;
  final bool permitirAlterarData;

  const OcorrenciaFormWidget({
    super.key,
    required this.usuario,
    required this.dataReferencia,
    this.ocorrenciaExistente,
    required this.onConcluido,
    this.permitirAlterarData = false,
  });

  @override
  State<OcorrenciaFormWidget> createState() => _OcorrenciaFormWidgetState();
}

class _OcorrenciaFormWidgetState extends State<OcorrenciaFormWidget> {
  final _controller = OcorrenciaController();
  final _justificativaController = TextEditingController();
  final _minutosController = TextEditingController(text: '60');
  
  TipoOcorrenciaEnum? _tipoSelecionado;
  late DateTime _dataAtual;

  @override
  void initState() {
    super.initState();
    _dataAtual = widget.dataReferencia;
    
    if (widget.ocorrenciaExistente != null) {
      _tipoSelecionado = widget.ocorrenciaExistente!.tipoOcorrencia;
      _justificativaController.text = widget.ocorrenciaExistente!.justificativa;
      final minProp = widget.ocorrenciaExistente!.minutosPropostos;
      _minutosController.text = (minProp > 0 ? minProp : 60).toString();
    }
  }

  @override
  void dispose() {
    _justificativaController.dispose();
    _minutosController.dispose();
    _controller.dispose();
    super.dispose();
  }

  Future<void> _salvar() async {
    final sucesso = await _controller.salvarOcorrencia(
      idEdicao: widget.ocorrenciaExistente?.id,
      usuarioId: widget.usuario.id,
      dataReferencia: _dataAtual,
      tipoSelecionado: _tipoSelecionado,
      justificativa: _justificativaController.text,
      minutosTexto: _minutosController.text,
    );

    if (!mounted) return;

    if (sucesso) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(widget.ocorrenciaExistente != null
              ? 'Ocorrência atualizada!'
              : 'Ocorrência registrada!'),
          backgroundColor: AppColors.success,
        ),
      );
      widget.onConcluido();
    } else {
      SnackbarUtil.showError(context, _controller.erroMensagem ?? 'Erro ao salvar.');
    }
  }

  Future<void> _excluir() async {
    if (widget.ocorrenciaExistente == null) return;
    final sucesso = await _controller.excluirOcorrencia(widget.ocorrenciaExistente!);
    if (!mounted) return;

    if (sucesso) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Excluída com sucesso.'), backgroundColor: AppColors.success),
      );
      widget.onConcluido();
    } else {
      SnackbarUtil.showError(context, _controller.erroMensagem ?? 'Erro ao excluir.');
    }
  }

  Future<void> _escolherData() async {
    if (!widget.permitirAlterarData) return;
    final selecionada = await showDatePicker(
      context: context,
      initialDate: _dataAtual,
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
    );
    if (selecionada != null && mounted) {
      setState(() => _dataAtual = selecionada);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final jaAvaliada = widget.ocorrenciaExistente?.foiAvaliada ?? false;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          'Data da ocorrência',
          style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: cs.onSurface),
        ),
        const SizedBox(height: 8),
        OutlinedButton.icon(
          onPressed: (jaAvaliada || !widget.permitirAlterarData) ? null : _escolherData,
          icon: const Icon(Icons.calendar_today),
          label: Text('${_dataAtual.day.toString().padLeft(2, '0')}/${_dataAtual.month.toString().padLeft(2, '0')}/${_dataAtual.year}'),
        ),
        const SizedBox(height: 18),
        Text(
          'Tipo de ocorrência',
          style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: cs.onSurface),
        ),
        const SizedBox(height: 8),
        DropdownButtonFormField<TipoOcorrenciaEnum>(
          value: _tipoSelecionado,
          dropdownColor: theme.cardColor,
          decoration: InputDecoration(
            filled: true, fillColor: theme.scaffoldBackgroundColor,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          ),
          items: _controller.tiposOcorrencia.map((t) => DropdownMenuItem(value: t, child: Text(t.titulo))).toList(),
          onChanged: jaAvaliada ? null : (val) => setState(() => _tipoSelecionado = val),
        ),
        const SizedBox(height: 18),
        Text(
          'Minutos solicitados para abono',
          style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: cs.onSurface),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: _minutosController,
          enabled: !jaAvaliada,
          keyboardType: TextInputType.number,
          decoration: InputDecoration(
            filled: true, fillColor: theme.scaffoldBackgroundColor,
            suffixText: 'min',
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          ),
        ),
        const SizedBox(height: 18),
        Text(
          'Observações / Justificativa',
          style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: cs.onSurface),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: _justificativaController,
          enabled: !jaAvaliada,
          maxLines: 4,
          decoration: InputDecoration(
            filled: true, fillColor: theme.scaffoldBackgroundColor,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          ),
        ),
        if (!jaAvaliada) ...[
          const SizedBox(height: 24),
          ListenableBuilder(
            listenable: _controller,
            builder: (context, _) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  PrimaryButton(
                    onPressed: _controller.salvando ? null : _salvar,
                    isLoading: _controller.salvando,
                    text: widget.ocorrenciaExistente == null ? 'Enviar Ocorrência' : 'Salvar Alterações',
                  ),
                  if (widget.ocorrenciaExistente != null) ...[
                    const SizedBox(height: 12),
                    OutlinedButton.icon(
                      onPressed: _controller.salvando ? null : _excluir,
                      icon: const Icon(Icons.delete_outline, color: AppColors.error),
                      label: const Text('Excluir Ocorrência', style: TextStyle(color: AppColors.error)),
                    ),
                  ],
                ],
              );
            },
          ),
        ],
      ],
    );
  }
}