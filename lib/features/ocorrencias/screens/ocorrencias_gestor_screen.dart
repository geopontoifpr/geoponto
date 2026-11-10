import 'package:flutter/material.dart';
import '../../usuarios/models/usuario_model.dart';
import '../controllers/ocorrencia_controller.dart';
import '../models/ocorrencia_model.dart';
import '../widgets/ocorrencia_card.dart';
import '../widgets/pessoa_pendencia_tile.dart';
import '../../../core/widgets/custom_app_bar.dart';

class OcorrenciasGestorScreen extends StatefulWidget {
  final UsuarioModel usuarioLogado;
  final UsuarioModel? pessoaInicial;
  final OcorrenciaController? controller;

  const OcorrenciasGestorScreen({
    super.key,
    required this.usuarioLogado,
    this.pessoaInicial,
    this.controller,
  });

  @override
  State<OcorrenciasGestorScreen> createState() =>
      _OcorrenciasGestorScreenState();
}

class _OcorrenciasGestorScreenState extends State<OcorrenciasGestorScreen> {
  late final OcorrenciaController _controller;
  late final bool _possuiControllerExterno;
  bool _mostrarPendentes = true;

  @override
  void initState() {
    super.initState();

    _possuiControllerExterno = widget.controller != null;
    _controller = widget.controller ?? OcorrenciaController();

    if (widget.pessoaInicial != null) {
      _controller.selecionarPessoa(
        usuarioLogado: widget.usuarioLogado,
        pessoa: widget.pessoaInicial!,
      );
    } else {
      _controller.carregarPessoasComPendencias(widget.usuarioLogado);
    }
  }

  @override
  void dispose() {
    if (!_possuiControllerExterno) {
      _controller.dispose();
    }
    super.dispose();
  }

  String _formatarData(DateTime data) =>
      '${data.day.toString().padLeft(2, '0')}/${data.month.toString().padLeft(2, '0')}/${data.year}';

  String get _tituloPessoas =>
      widget.usuarioLogado.tipoUsuario == TipoUsuario.administrador
          ? 'Gestores com ocorrências neste mês'
          : 'Colaboradores com ocorrências neste mês';

  String get _tituloOcorrencias =>
      widget.usuarioLogado.tipoUsuario == TipoUsuario.administrador
          ? 'Ocorrências do gestor'
          : 'Ocorrências do colaborador';

  Future<void> _abrirPessoa(UsuarioModel pessoa) async {
    setState(() => _mostrarPendentes = true);

    await _controller.selecionarPessoa(
      usuarioLogado: widget.usuarioLogado,
      pessoa: pessoa,
    );
  }

  Future<void> _avaliarOcorrencia(
    OcorrenciaModel ocorrencia,
    UsuarioModel pessoa,
    bool aprovar,
  ) async {
    final observacaoController = TextEditingController();

    final confirmar = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(aprovar ? 'Aprovar ocorrência' : 'Recusar ocorrência'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              aprovar
                  ? 'Confirmar abono de ${ocorrencia.minutosPropostos} minutos?'
                  : 'Confirma a recusa desta ocorrência?',
            ),
            const SizedBox(height: 12),
            TextField(
              controller: observacaoController,
              maxLines: 3,
              decoration: const InputDecoration(
                labelText: 'Observação (opcional)',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: Text(aprovar ? 'Aprovar' : 'Recusar'),
          ),
        ],
      ),
    );

    if (confirmar == true && mounted) {
      final sucesso = await _controller.avaliarOcorrencia(
        ocorrencia: ocorrencia,
        aprovar: aprovar,
        usuarioLogado: widget.usuarioLogado,
        pessoaSelecionada: pessoa,
        observacaoGestor: observacaoController.text.trim(),
      );

      if (!mounted) {
        observacaoController.dispose();
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            sucesso
                ? (aprovar
                    ? 'Ocorrência aprovada.'
                    : 'Ocorrência recusada.')
                : _controller.erroMensagem ??
                    'Não foi possível avaliar a ocorrência.',
          ),
        ),
      );
    }

    observacaoController.dispose();
  }

  Future<void> _reabrirOcorrencia(
    OcorrenciaModel ocorrencia,
    UsuarioModel pessoa,
  ) async {
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Tornar ocorrência pendente?'),
        content: const Text(
          'A avaliação será desfeita. Os minutos abonados deixarão de contar no extrato até que a ocorrência seja avaliada novamente.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Tornar pendente'),
          ),
        ],
      ),
    );

    if (confirmar != true || !mounted) return;

    final sucesso = await _controller.reabrirOcorrencia(
      ocorrencia: ocorrencia,
      usuarioLogado: widget.usuarioLogado,
      pessoaSelecionada: pessoa,
    );

    if (!mounted) return;

    if (sucesso) {
      setState(() => _mostrarPendentes = true);
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          sucesso
              ? 'Ocorrência voltou para pendente.'
              : _controller.erroMensagem ??
                  'Não foi possível reabrir a ocorrência.',
        ),
      ),
    );
  }

  Widget _mensagemVazia(String mensagem, Color cor) => Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text(
            mensagem,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: cor,
              fontSize: 15,
            ),
          ),
        ),
      );

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
        appBar: CustomAppBar(
          usuario: widget.usuarioLogado,
        ),
      body: Material(
        color: theme.scaffoldBackgroundColor,
        child: SafeArea(
          child: ListenableBuilder(
            listenable: _controller,
            builder: (context, _) {
              final pessoa = _controller.pessoaSelecionada;

              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (pessoa == null)
                    Padding(
                      padding: const EdgeInsets.fromLTRB(20, 20, 20, 8),
                      child: Text(
                        _tituloPessoas,
                        style: theme.textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: colorScheme.onSurface,
                        ),
                      ),
                    )
                  else
                    Padding(
                      padding: const EdgeInsets.fromLTRB(12, 12, 20, 8),
                      child: Row(
                        children: [
                          IconButton(
                            tooltip: 'Voltar para a lista',
                            onPressed: widget.pessoaInicial != null
                                ? () => Navigator.of(context).pop()
                                : _controller.voltarParaPessoas,
                            icon: const Icon(Icons.arrow_back),
                          ),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  pessoa.nome,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style:
                                      theme.textTheme.titleLarge?.copyWith(
                                    fontWeight: FontWeight.bold,
                                    color: colorScheme.onSurface,
                                  ),
                                ),
                                Text(
                                  _tituloOcorrencias,
                                  style: theme.textTheme.bodySmall?.copyWith(
                                    color: colorScheme.onSurfaceVariant,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),

                  if (_controller.carregando)
                    const Expanded(
                      child: Center(
                        child: CircularProgressIndicator(),
                      ),
                    )
                  else if (_controller.erroMensagem != null)
                    Expanded(
                      child: Center(
                        child: Padding(
                          padding: const EdgeInsets.all(24),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                _controller.erroMensagem!,
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  color: colorScheme.error,
                                  height: 1.4,
                                ),
                              ),
                              const SizedBox(height: 16),
                              OutlinedButton.icon(
                                onPressed: pessoa == null
                                    ? () => _controller
                                        .carregarPessoasComPendencias(
                                          widget.usuarioLogado,
                                        )
                                    : () => _controller.selecionarPessoa(
                                          usuarioLogado:
                                              widget.usuarioLogado,
                                          pessoa: pessoa,
                                        ),
                                icon: const Icon(Icons.refresh),
                                label: const Text('Tentar novamente'),
                              ),
                            ],
                          ),
                        ),
                      ),
                    )
                  else if (pessoa == null)
                    Expanded(
                      child: RefreshIndicator(
                        onRefresh: () =>
                            _controller.carregarPessoasComPendencias(
                          widget.usuarioLogado,
                        ),
                        child: _controller.pessoasComPendencias.isEmpty
                            ? ListView(
                                children: [
                                  SizedBox(
                                    height: 280,
                                    child: _mensagemVazia(
                                      'Nenhuma pessoa possui ocorrências neste mês.',
                                      colorScheme.onSurfaceVariant,
                                    ),
                                  ),
                                ],
                              )
                            : ListView.separated(
                                padding: const EdgeInsets.fromLTRB(
                                  16,
                                  8,
                                  16,
                                  20,
                                ),
                                itemCount:
                                    _controller.pessoasComPendencias.length,
                                separatorBuilder: (_, __) =>
                                    const SizedBox(height: 10),
                                itemBuilder: (context, index) {
                                  final pessoaPendencia =
                                      _controller.pessoasComPendencias[index];

                                  return PessoaPendenciaTile(
                                    pessoa: pessoaPendencia,
                                    onTap: () =>
                                        _abrirPessoa(pessoaPendencia),
                                  );
                                },
                              ),
                      ),
                    )
                  else ...[
                    Padding(
                      padding: const EdgeInsets.fromLTRB(20, 4, 20, 12),
                      child: Wrap(
                        spacing: 8,
                        children: [
                          ChoiceChip(
                            label: const Text('Pendentes'),
                            selected: _mostrarPendentes,
                            onSelected: (selecionado) {
                              if (selecionado) {
                                setState(() => _mostrarPendentes = true);
                              }
                            },
                          ),
                          ChoiceChip(
                            label: const Text('Respondidas'),
                            selected: !_mostrarPendentes,
                            onSelected: (selecionado) {
                              if (selecionado) {
                                setState(() => _mostrarPendentes = false);
                              }
                            },
                          ),
                        ],
                      ),
                    ),
                    Expanded(
                      child: Builder(
                        builder: (context) {
                          final lista = _controller.ocorrenciasDaPessoa
                              .where(
                                (ocorrencia) => _mostrarPendentes
                                    ? ocorrencia.isPendente
                                    : ocorrencia.foiAvaliada,
                              )
                              .toList();

                          if (lista.isEmpty) {
                            return _mensagemVazia(
                              _mostrarPendentes
                                  ? 'Esta pessoa não possui ocorrências pendentes neste mês.'
                                  : 'Esta pessoa não possui ocorrências respondidas neste mês.',
                              colorScheme.onSurfaceVariant,
                            );
                          }

                          return RefreshIndicator(
                            onRefresh: () => _controller.selecionarPessoa(
                              usuarioLogado: widget.usuarioLogado,
                              pessoa: pessoa,
                            ),
                            child: ListView.separated(
                              padding: const EdgeInsets.fromLTRB(
                                16,
                                4,
                                16,
                                20,
                              ),
                              itemCount: lista.length,
                              separatorBuilder: (_, __) =>
                                  const SizedBox(height: 12),
                              itemBuilder: (context, index) {
                                return OcorrenciaCard(
                                  ocorrencia: lista[index],
                                  dataFormatada: _formatarData(
                                    lista[index].dataInicio,
                                  ),
                                  onAvaliar: (ocorrencia, aprovar) =>
                                      _avaliarOcorrencia(
                                    ocorrencia,
                                    pessoa,
                                    aprovar,
                                  ),
                                  onReabrir: (ocorrencia) =>
                                      _reabrirOcorrencia(
                                    ocorrencia,
                                    pessoa,
                                  ),
                                );
                              },
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}