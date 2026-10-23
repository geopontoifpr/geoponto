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
  final _justificativaController = TextEditingController();
  final _minutosController = TextEditingController(text: '60');

  TipoOcorrenciaEnum? _tipoSelecionado;
  OcorrenciaModel? _ocorrenciaExistente;

  @override
  void initState() {
    super.initState();
    // Se já houver ocorrência no dia, carrega para edição (1 por dia)
    if (widget.ocorrenciasDoDia.isNotEmpty) {
      _ocorrenciaExistente = widget.ocorrenciasDoDia.first;
      _tipoSelecionado = _ocorrenciaExistente!.tipoOcorrencia;
      _justificativaController.text = _ocorrenciaExistente!.justificativa;
      final minProp = _ocorrenciaExistente!.minutosPropostos;
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

  String _formatarDataSubtitulo(DateTime d) {
    const meses = [
      'Janeiro', 'Fevereiro', 'Março', 'Abril', 'Maio', 'Junho',
      'Julho', 'Agosto', 'Setembro', 'Outubro', 'Novembro', 'Dezembro'
    ];
    return '${meses[d.month - 1]} ${d.day}, ${d.year}';
  }

  String _formatarHoraMinuto(DateTime? dt) {
    if (dt == null) return '--:--';
    final local = dt.toLocal();
    return '${local.hour.toString().padLeft(2, '0')}:${local.minute.toString().padLeft(2, '0')}';
  }

  String _formatarDuracao(Duration d) {
    final horas = d.inHours.toString().padLeft(2, '0');
    final minutos = (d.inMinutes % 60).toString().padLeft(2, '0');
    return '${horas}h$minutos';
  }

  Future<void> _salvarOcorrencia() async {
    final sucesso = await _controller.salvarOcorrencia(
      idEdicao: _ocorrenciaExistente?.id,
      usuarioId: widget.usuario.id,
      dataReferencia: widget.dataSelecionada,
      tipoSelecionado: _tipoSelecionado,
      justificativa: _justificativaController.text,
      minutosTexto: _minutosController.text,
    );

    if (!mounted) return;

    if (sucesso) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            _ocorrenciaExistente != null
                ? 'Ocorrência atualizada com sucesso!'
                : 'Ocorrência registrada com sucesso!',
          ),
          backgroundColor: AppColors.success,
        ),
      );
      Navigator.pop(context, true);
    } else {
      SnackbarUtil.showError(
        context,
        _controller.erroMensagem ?? 'Erro ao salvar ocorrência.',
      );
    }
  }

  Future<void> _confirmarExclusao() async {
    if (_ocorrenciaExistente == null) return;

    final confirmar = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Excluir Ocorrência?'),
        content: const Text(
          'Tem certeza que deseja excluir a ocorrência registrada neste dia?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
              foregroundColor: Colors.white,
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Excluir'),
          ),
        ],
      ),
    );

    if (confirmar != true || !mounted) return;

    final sucesso = await _controller.excluirOcorrencia(_ocorrenciaExistente!);
    if (!mounted) return;

    if (sucesso) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Ocorrência excluída com sucesso.'),
          backgroundColor: AppColors.success,
        ),
      );
      Navigator.pop(context, true);
    } else {
      SnackbarUtil.showError(
        context,
        _controller.erroMensagem ?? 'Erro ao excluir ocorrência.',
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

    final jaAvaliada = _ocorrenciaExistente?.foiAvaliada ?? false;

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

            if (_ocorrenciaExistente != null) ...[
              const SizedBox(height: 24),
              _buildCardStatusAtual(context, _ocorrenciaExistente!),
            ],
            const SizedBox(height: 24),
            Text(
              _ocorrenciaExistente == null
                  ? 'Registrar ocorrência'
                  : (jaAvaliada ? 'Detalhes da ocorrência' : 'Editar ocorrência do dia'),
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
                  DropdownButtonFormField<TipoOcorrenciaEnum>(
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
                    items: _controller.tiposOcorrencia
                        .map((tipo) => DropdownMenuItem(
                              value: tipo,
                              child: Text(tipo.titulo),
                            ))
                        .toList(),
                    onChanged: jaAvaliada
                        ? null
                        : (val) => setState(() => _tipoSelecionado = val),
                  ),
                  const SizedBox(height: 18),
                  Text(
                    'Minutos solicitados para abono',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: colorScheme.onSurface,
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _minutosController,
                    enabled: !jaAvaliada,
                    keyboardType: TextInputType.number,
                    style: TextStyle(color: colorScheme.onSurface),
                    decoration: InputDecoration(
                      fillColor: theme.scaffoldBackgroundColor,
                      filled: true,
                      hintText: 'Ex: 60 (será salvo como 01:00 em horário proposto)',
                      hintStyle: TextStyle(color: colorScheme.onSurfaceVariant),
                      suffixText: 'min',
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
                    'Observações / Justificativa',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: colorScheme.onSurface,
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _justificativaController,
                    enabled: !jaAvaliada,
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
                  if (!jaAvaliada) ...[
                    const SizedBox(height: 20),
                    ListenableBuilder(
                      listenable: _controller,
                      builder: (context, _) {
                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            PrimaryButton(
                              onPressed: _controller.salvando ? null : _salvarOcorrencia,
                              isLoading: _controller.salvando,
                              text: _ocorrenciaExistente == null
                                  ? 'Enviar Ocorrência'
                                  : 'Salvar Alterações',
                            ),
                            if (_ocorrenciaExistente != null) ...[
                              const SizedBox(height: 12),
                              OutlinedButton.icon(
                                onPressed: _controller.salvando ? null : _confirmarExclusao,
                                icon: const Icon(Icons.delete_outline, color: AppColors.error),
                                label: const Text(
                                  'Excluir Ocorrência',
                                  style: TextStyle(
                                    color: AppColors.error,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                style: OutlinedButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(vertical: 14),
                                  side: const BorderSide(color: AppColors.error),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                              ),
                            ],
                          ],
                        );
                      },
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCardStatusAtual(BuildContext context, OcorrenciaModel oc) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    final Color corStatus;
    final String textoStatus;
    final IconData iconeStatus;

    if (oc.aprovada) {
      corStatus = AppColors.success;
      textoStatus = 'Aprovada (${oc.minutosAbonados ?? oc.minutosPropostos} min abonados)';
      iconeStatus = Icons.check_circle;
    } else if (oc.isRecusada) {
      corStatus = AppColors.error;
      textoStatus = 'Recusada pelo gestor';
      iconeStatus = Icons.cancel;
    } else {
      corStatus = AppColors.warning;
      textoStatus = 'Pendente de avaliação';
      iconeStatus = Icons.pending_actions;
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: corStatus.withOpacity(0.4)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(iconeStatus, color: corStatus),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  textoStatus,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: corStatus,
                  ),
                ),
              ),
            ],
          ),
          if (oc.observacaoGestor != null && oc.observacaoGestor!.trim().isNotEmpty) ...[
            const SizedBox(height: 12),
            Text(
              'Observação do Gestor:',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              oc.observacaoGestor!,
              style: TextStyle(color: colorScheme.onSurface),
            ),
          ],
        ],
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