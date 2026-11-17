import 'package:material_ui/material_ui.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/themes/app_themes.dart';
import '../../../core/utils/formatadores.dart';
import '../../ponto/models/registro_ponto_model.dart';
import '../../usuarios/models/usuario_model.dart';
import '../models/ocorrencia_model.dart';
import '../widgets/ocorrencia_form.dart';

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
  OcorrenciaModel? _ocorrenciaExistente;
  late DateTime _dataReferencia;

  @override
  void initState() {
    super.initState();
    _dataReferencia = widget.dataSelecionada;
    if (widget.ocorrenciasDoDia.isNotEmpty) {
      _ocorrenciaExistente = widget.ocorrenciasDoDia.first;
    }
  }

  String _formatarDataSubtitulo(DateTime d) {
    return '${Formatadores.meses[d.month - 1]} ${d.day}, ${d.year}';
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
            
            // O FORMULÁRIO ENCAPSULADO TOMA CONTA DE TUDO DAQUI PRA FRENTE
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: theme.cardColor,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [AppThemes.cardShadow(context)],
              ),
              child: OcorrenciaForm(
                usuario: widget.usuario,
                dataReferencia: _dataReferencia,
                ocorrenciaExistente: _ocorrenciaExistente,
                permitirAlterarData: !jaAvaliada, 
                onConcluido: () => Navigator.pop(context, true),
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

    // TODO: Caso você tenha passado o "StatusOcorrencia get status" para o Model 
    // conforme sugerido na Seção 7 da sua análise, você pode simplificar esses ifs futuramente.
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
        border: Border.all(color: corStatus.withValues(alpha: 0.4)),
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