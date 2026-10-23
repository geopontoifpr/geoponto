import 'package:flutter/material.dart';
import '../themes/app_themes.dart';
import '../utils/snackbar_util.dart';
import '../widgets/usuario_list.dart';
import 'extrato_mensal_screen.dart';
import '../../features/ocorrencias/screens/ocorrencia_do_usuario_screen.dart';
import '../../features/usuarios/controllers/usuario_controller.dart';
import '../../features/usuarios/models/usuario_model.dart';
import '../../features/usuarios/screens/cadastro_usuario_screen.dart';

enum ModoEquipe { cadastrar, extrato, ocorrencias }

class EquipeScreen extends StatefulWidget {
  final String empresaId;
  final UsuarioModel usuarioLogado;
  final bool mostrarAppBar;

  const EquipeScreen({
    super.key,
    required this.empresaId,
    required this.usuarioLogado,
    this.mostrarAppBar = true,
  });

  @override
  State<EquipeScreen> createState() => _EquipeScreenState();
}

class _EquipeScreenState extends State<EquipeScreen>
    with SingleTickerProviderStateMixin {
  final _controller = UsuarioController();
  late final TabController _tabController;

  ModoEquipe get _modo => ModoEquipe.values[_tabController.index];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: ModoEquipe.values.length, vsync: this)
      ..addListener(() {
        // reconstrói só quando a troca de aba termina (evita rebuild duplo)
        if (!_tabController.indexIsChanging) setState(() {});
      });

    WidgetsBinding.instance.addPostFrameCallback((_) => _recarregar());
  }

  @override
  void dispose() {
    _tabController.dispose();
    _controller.dispose();
    super.dispose();
  }

  void _recarregar() {
    if (widget.empresaId.isNotEmpty) {
      _controller.carregarUsuarios(widget.usuarioLogado, widget.empresaId);
    }
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
        builder: (_) => OcorrenciaDoUsuarioScreen(
          colaborador: membro,
          gestorLogado: widget.usuarioLogado,
        ),
      ),
    );
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
              tabs: const [
                Tab(icon: Icon(Icons.person_add_alt_1), text: 'Cadastrar'),
                Tab(icon: Icon(Icons.receipt_long), text: 'Extrato Mensal'),
                Tab(icon: Icon(Icons.report_problem_outlined), text: 'Ocorrências'),
              ],
            ),
          ),
          Expanded(
            child: ListenableBuilder(
              listenable: _controller,
              builder: (context, _) {
                if (_controller.isLoading && _controller.usuario.isEmpty) {
                  return Center(
                    child: CircularProgressIndicator(color: theme.primaryColor),
                  );
                }

                if (_controller.erroMensagem != null) {
                  return Center(
                    child: Text(
                      _controller.erroMensagem!,
                      style: const TextStyle(color: AppThemes.errorColor),
                      textAlign: TextAlign.center,
                    ),
                  );
                }

                if (_controller.usuario.isEmpty) {
                  return const Center(child: Text('Ninguém na equipe ainda.'));
                }

                return ListView.builder(
                  itemCount: _controller.usuario.length,
                  itemBuilder: (context, index) {
                    final membro = _controller.usuario[index];

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