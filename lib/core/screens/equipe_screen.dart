import 'package:flutter/material.dart';
import '../themes/app_themes.dart';
import '../utils/snackbar_util.dart';
import '../widgets/usuario_list.dart';
import 'extrato_mensal_screen.dart';
import '../../features/ocorrencias/screens/ocorrencias_gestor_screen.dart';
import '../../features/ocorrencias/controllers/ocorrencia_controller.dart';
import '../../features/usuarios/controllers/usuario_controller.dart';
import '../../features/usuarios/models/usuario_model.dart';
import '../../features/usuarios/screens/cadastro_usuario_screen.dart';

enum ModoEquipe { cadastrar, extrato, ocorrencias }

class EquipeScreen extends StatefulWidget {
  final String empresaId;
  final UsuarioModel usuarioLogado;
  final bool mostrarAppBar;
  final VoidCallback? onAtualizarNotificacoes;
  final bool temPendencias; 

  const EquipeScreen({
    super.key,
    required this.empresaId,
    required this.usuarioLogado,
    this.mostrarAppBar = true,
    this.onAtualizarNotificacoes,
    this.temPendencias = false,
  });

  @override
  State<EquipeScreen> createState() => _EquipeScreenState();
}

class _EquipeScreenState extends State<EquipeScreen>
    with SingleTickerProviderStateMixin {
  final _controller = UsuarioController();
  final _ocorrenciaController = OcorrenciaController();
  late final TabController _tabController;

  ModoEquipe get _modo => ModoEquipe.values[_tabController.index];


  @override
  void initState() {
    super.initState();

    _tabController = TabController(
      length: ModoEquipe.values.length,
      vsync: this,
    )..addListener(() {
        if (!_tabController.indexIsChanging) {
          setState(() {});
        }
      });

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _recarregar();
    });
  }


  @override
  void dispose() {
    _tabController.dispose();
    _controller.dispose();
    _ocorrenciaController.dispose();
    super.dispose();
  }

  void _recarregar() {
    if (widget.empresaId.isNotEmpty) {
      _controller.carregarUsuarios(widget.usuarioLogado, widget.empresaId);
    }
    _ocorrenciaController.carregarPessoasComPendencias(widget.usuarioLogado);
  }
  void _aoAtualizarPainel() {
    if (mounted) setState(() {});
  }

  List<UsuarioModel> _obterListaExibicao(bool isAbaOcorrencias) {
    if (isAbaOcorrencias) {
      final idsPendentes = _ocorrenciaController.pessoasComPendencias
          .map((p) => p.id)
          .toSet();
          
      return _controller.usuario
          .where((u) => idsPendentes.contains(u.id))
          .toList();
    }
    return _controller.usuario;
  }

  Future<void> _irParaCadastro({UsuarioModel? membroEmEdicao}) async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => CadastroUsuarioScreen(
          empresaId: widget.empresaId,
          usuarioLogado: widget.usuarioLogado,
          membroEmEdicao: membroEmEdicao,
        ),
      ),
    );
    _recarregar();
  }

  void _abrirExtrato(UsuarioModel membro) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ExtratoMensalScreen(
          colaborador: membro,
          gestorLogado: widget.usuarioLogado,
        ),
      ),
    );
  }


  void _abrirOcorrencias(UsuarioModel membro) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => OcorrenciasGestorScreen(
          usuarioLogado: widget.usuarioLogado,
          pessoaInicial: membro,
        ),
      ),
    );
    widget.onAtualizarNotificacoes?.call();
    _recarregar();
  }


  void _aoTocarNoMembro(UsuarioModel membro) {
    switch (_modo) {
      case ModoEquipe.cadastrar:
        break; // no modo cadastro, as ações ficam nos botões editar/inativar
      case ModoEquipe.extrato:
        _abrirExtrato(membro);
        break;
      case ModoEquipe.ocorrencias:
        _abrirOcorrencias(membro);
        break;
    }
  }

  Future<void> _alternarStatus(UsuarioModel membro) async {
    final sucesso =
        await _controller.alternarStatus(membro, widget.usuarioLogado);
    if (!mounted) return;

    if (!sucesso) {
      SnackbarUtil.showError(
        context,
        _controller.erroMensagem ?? 'Erro ao alterar status.',
      );
    } else {
      _recarregar();
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final modoCadastro = _modo == ModoEquipe.cadastrar;

    return Scaffold(
      backgroundColor: Colors.transparent,   // <- adicione
      appBar: widget.mostrarAppBar
          ? AppBar(title: const Text('Gestão de Equipe'))
          : null,
      floatingActionButton: modoCadastro
          ? FloatingActionButton.extended(
              onPressed: () => _irParaCadastro(),
              icon: const Icon(Icons.person_add),
              label: const Text('Novo Membro'),
            )
          : null,
      body: Column(
        children: [
          Material(
            color: theme.scaffoldBackgroundColor,
            child: TabBar(
              controller: _tabController,
              tabs: [
                const Tab(icon: Icon(Icons.person_add_alt_1), text: 'Cadastrar'),
                const Tab(icon: Icon(Icons.receipt_long), text: 'Extrato Mensal'),
                Tab(
                  icon: Badge(
                    isLabelVisible: widget.temPendencias,
                    backgroundColor: AppThemes.errorColor,
                    label: const Text('!', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 10)),
                    child: const Icon(Icons.report_problem_outlined),
                  ),
                  text: 'Ocorrências',
                ),
              ],
            ),
          ),
          Expanded(
            child: ListenableBuilder(
              listenable: Listenable.merge([_controller, _ocorrenciaController]),
              builder: (context, _) {
                final isAbaOcorrencias = _modo == ModoEquipe.ocorrencias;
                
                final carregando = isAbaOcorrencias 
                    ? _ocorrenciaController.carregando 
                    : (_controller.isLoading && _controller.usuario.isEmpty);
                    
                final erro = isAbaOcorrencias 
                    ? _ocorrenciaController.erroMensagem 
                    : _controller.erroMensagem;
                    
                // Chamada limpa para o método que criamos
                final listaExibicao = _obterListaExibicao(isAbaOcorrencias);

                if (carregando) {
                  return Center(
                    child: CircularProgressIndicator(color: theme.primaryColor),
                  );
                }

                if (erro != null) {
                  return Center(
                    child: Text(
                      erro,
                      style: const TextStyle(color: AppThemes.errorColor),
                      textAlign: TextAlign.center,
                    ),
                  );
                }

                if (listaExibicao.isEmpty) {
                  return Center(
                    child: Text(isAbaOcorrencias 
                        ? 'Nenhuma ocorrência pendente na equipe.' 
                        : 'Ninguém na equipe ainda.'),
                  );
                }

                return ListView.builder(
                  itemCount: listaExibicao.length,
                  itemBuilder: (context, index) {
                    final membro = listaExibicao[index];

                    return UsuarioList(
                      membro: membro,
                      onTap: modoCadastro ? null : () => _aoTocarNoMembro(membro),
                      // editar/inativar só aparecem na aba Cadastrar
                      onEdit: modoCadastro
                          ? () => _irParaCadastro(membroEmEdicao: membro)
                          : null,
                      onToggleStatus:
                          modoCadastro ? () => _alternarStatus(membro) : null,
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}