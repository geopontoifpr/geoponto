import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/widgets/custom_app_bar.dart';
import '../../usuarios/models/usuario_model.dart';
import '../controllers/ocorrencia_controller.dart';
import '../models/ocorrencia_model.dart';
import '../widgets/ocorrencia_card.dart';
import '../widgets/ocorrencia_form_widget.dart';

class MinhasOcorrenciasScreen extends StatefulWidget {
  final UsuarioModel usuario;
  final bool mostrarAppBar;

  const MinhasOcorrenciasScreen({
    super.key,
    required this.usuario,
    this.mostrarAppBar = true,
  });

  @override
  State<MinhasOcorrenciasScreen> createState() => _MinhasOcorrenciasScreenState();
}

class _MinhasOcorrenciasScreenState extends State<MinhasOcorrenciasScreen> {
  final _controller = OcorrenciaController();
  DateTime _mesAtual = DateTime(DateTime.now().year, DateTime.now().month, 1);
  bool _mostrarPendentes = true;

  static const _nomesMeses = [
    'Janeiro', 'Fevereiro', 'Março', 'Abril', 'Maio', 'Junho',
    'Julho', 'Agosto', 'Setembro', 'Outubro', 'Novembro', 'Dezembro'
  ];

  @override
  void initState() {
    super.initState();
    _carregar();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _carregar() => _controller.carregarDoMes(
        widget.usuario.id,
        _mesAtual,
        usuarioLogado: widget.usuario,
      );

  void _mudarMes(int delta) {
    setState(() {
      _mesAtual = DateTime(_mesAtual.year, _mesAtual.month + delta, 1);
    });
    _carregar();
  }

  void _abrirModalEdicao(OcorrenciaModel oc) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Theme.of(context).cardColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(ctx).viewInsets.bottom,
          left: 24, right: 24, top: 24,
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Editar Ocorrência',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Theme.of(ctx).colorScheme.onSurface),
              ),
              const SizedBox(height: 16),
              OcorrenciaFormWidget(
                usuario: widget.usuario,
                dataReferencia: oc.dataInicio,
                ocorrenciaExistente: oc,
                permitirAlterarData: false, // Bloqueia troca de dia na edição
                onConcluido: () {
                  Navigator.pop(ctx);
                  _carregar();
                },
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    final conteudo = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Seletor de Mês
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          color: theme.cardColor,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              IconButton(icon: const Icon(Icons.chevron_left), onPressed: () => _mudarMes(-1)),
              Text(
                '${_nomesMeses[_mesAtual.month - 1]} ${_mesAtual.year}',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: cs.onSurface),
              ),
              IconButton(icon: const Icon(Icons.chevron_right), onPressed: () => _mudarMes(1)),
            ],
          ),
        ),
        // Filtros (Chips)
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Wrap(
            spacing: 8,
            children: [
              ChoiceChip(
                label: const Text('Pendentes'),
                selected: _mostrarPendentes,
                onSelected: (val) { if (val) setState(() => _mostrarPendentes = true); },
              ),
              ChoiceChip(
                label: const Text('Respondidas'),
                selected: !_mostrarPendentes,
                onSelected: (val) { if (val) setState(() => _mostrarPendentes = false); },
              ),
            ],
          ),
        ),
        // Lista
        Expanded(
          child: ListenableBuilder(
            listenable: _controller,
            builder: (context, _) {
              if (_controller.carregando) {
                return const Center(child: CircularProgressIndicator());
              }
              if (_controller.erroMensagem != null) {
                return Center(child: Text(_controller.erroMensagem!, style: const TextStyle(color: AppColors.error)));
              }

              final lista = _controller.ocorrenciasDoMes
                  .where((oc) => _mostrarPendentes ? oc.isPendente : oc.foiAvaliada)
                  .toList();

              if (lista.isEmpty) {
                return Center(
                  child: Text(
                    _mostrarPendentes ? 'Você não possui ocorrências pendentes neste mês.' : 'Você não possui ocorrências respondidas.',
                    style: TextStyle(color: cs.onSurfaceVariant),
                  ),
                );
              }

              return RefreshIndicator(
                onRefresh: _carregar,
                child: ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: lista.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 12),
                  itemBuilder: (context, index) {
                    final oc = lista[index];
                    return OcorrenciaCard(
                      ocorrencia: oc,
                      dataFormatada: '${oc.dataInicio.day.toString().padLeft(2, '0')}/${oc.dataInicio.month.toString().padLeft(2, '0')}/${oc.dataInicio.year}',
                      onEditar: oc.isPendente ? () => _abrirModalEdicao(oc) : null,
                    );
                  },
                ),
              );
            },
          ),
        ),
      ],
    );

    if (!widget.mostrarAppBar) return conteudo;
    return Scaffold(appBar: CustomAppBar(usuario: widget.usuario), body: conteudo);
  }
}