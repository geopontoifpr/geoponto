import 'package:flutter/material.dart';
import '../../usuarios/models/usuario_model.dart';
import '../controllers/ocorrencia_controller.dart';
import '../models/ocorrencia_model.dart';
import '../widgets/ocorrencia_card.dart';
import '../widgets/filtro_ocorrencias_chips.dart';
import '../../../core/widgets/estado_async.dart';
import '../../../core/utils/snackbar_util.dart';
import '../../../core/widgets/custom_app_bar.dart';

// Extensão utilitária para filtrar facilmente
extension FiltroOcorrencias on Iterable<OcorrenciaModel> {
  List<OcorrenciaModel> filtrar({required bool pendentes}) =>
      where((o) => pendentes ? o.isPendente : o.foiAvaliada).toList();
}

class OcorrenciasGestorScreen extends StatefulWidget {
  final UsuarioModel usuarioLogado;
  final UsuarioModel pessoa;

  const OcorrenciasGestorScreen({
    super.key,
    required this.usuarioLogado,
    required this.pessoa,
  });

  @override
  State<OcorrenciasGestorScreen> createState() => _OcorrenciasGestorScreenState();
}

class _OcorrenciasGestorScreenState extends State<OcorrenciasGestorScreen> {
  final _c = OcorrenciaController();
  bool _pendentes = true;

  Future<void> _carregar() =>
      _c.selecionarPessoa(usuarioLogado: widget.usuarioLogado, pessoa: widget.pessoa);

  @override
  void initState() {
    super.initState();
    _carregar();
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  void _aviso(bool ok, String sucesso, String falha) => ok
      ? SnackbarUtil.showSuccess(context, sucesso)
      : SnackbarUtil.showError(context, _c.erroMensagem ?? falha);

  Future<void> _avaliar(OcorrenciaModel oc, bool aprovar) async {
    final obs = TextEditingController();
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(aprovar ? 'Aprovar ocorrência' : 'Recusar ocorrência'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(aprovar
                ? 'Confirmar abono de ${oc.minutosPropostos} minutos?'
                : 'Confirma a recusa desta ocorrência?'),
            const SizedBox(height: 12),
            TextField(
              controller: obs,
              maxLines: 3,
              decoration: const InputDecoration(labelText: 'Observação (opcional)', border: OutlineInputBorder()),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancelar')),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: Text(aprovar ? 'Aprovar' : 'Recusar')),
        ],
      ),
    );
    if (ok != true || !mounted) {
      obs.dispose();
      return;
    }
    
    final sucesso = await _c.avaliarOcorrencia(
      ocorrencia: oc,
      aprovar: aprovar,
      usuarioLogado: widget.usuarioLogado,
      pessoaSelecionada: widget.pessoa,
      observacaoGestor: obs.text.trim(),
    );
    obs.dispose();
    if (mounted) _aviso(sucesso, aprovar ? 'Ocorrência aprovada.' : 'Ocorrência recusada.', 'Não foi possível avaliar.');
  }

  Future<void> _reabrir(OcorrenciaModel oc) async {
    final okDialog = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Tornar ocorrência pendente?'),
        content: const Text('A avaliação será desfeita e os minutos abonados deixam de contar no extrato.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancelar')),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Tornar pendente')),
        ],
      ),
    );
    if (okDialog != true || !mounted) return;

    final sucesso = await _c.reabrirOcorrencia(
      ocorrencia: oc,
      usuarioLogado: widget.usuarioLogado,
      pessoaSelecionada: widget.pessoa,
    );
    
    if (!mounted) return;
    if (sucesso) setState(() => _pendentes = true);
    _aviso(sucesso, 'Ocorrência voltou para pendente.', 'Não foi possível reabrir.');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomAppBar(usuario: widget.usuarioLogado),
      body: ListenableBuilder(
        listenable: _c,
        builder: (_, __) {
          final lista = _c.ocorrenciasDaPessoa.filtrar(pendentes: _pendentes);
          return Column(
            children: [
              ListTile(
                leading: const BackButton(),
                title: Text(widget.pessoa.nome, style: const TextStyle(fontWeight: FontWeight.bold)),
                subtitle: Text(widget.pessoa.tipoUsuario == TipoUsuario.gestor ? 'Ocorrências do gestor' : 'Ocorrências do colaborador'),
              ),
              FiltroOcorrenciasChips(pendentes: _pendentes, onChanged: (v) => setState(() => _pendentes = v)),
              Expanded(
                child: EstadoAsync(
                  carregando: _c.carregando,
                  erro: _c.erroMensagem,
                  onTentarNovamente: _carregar,
                  vazio: lista.isEmpty,
                  mensagemVazio: _pendentes ? 'Nenhuma ocorrência pendente neste mês.' : 'Nenhuma ocorrência respondida neste mês.',
                  child: RefreshIndicator(
                    onRefresh: _carregar,
                    child: ListView.separated(
                      padding: const EdgeInsets.all(16),
                      itemCount: lista.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 12),
                      itemBuilder: (_, i) => OcorrenciaCard(
                        ocorrencia: lista[i],
                        dataFormatada: '${lista[i].dataInicio.day.toString().padLeft(2, '0')}/${lista[i].dataInicio.month.toString().padLeft(2, '0')}/${lista[i].dataInicio.year}',
                        onAvaliar: (oc, a) => _avaliar(oc, a),
                        onReabrir: _reabrir,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}