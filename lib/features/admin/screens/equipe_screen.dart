import 'package:flutter/material.dart';
import '../../../core/themes/app_themes.dart';
import '../../../core/utils/snackbar_util.dart';
import '../../../core/widgets/usuario_list.dart';
import '../../gestor/screens/extrato_mensal_screen.dart';
import '../../usuarios/controllers/usuario_controller.dart';
import '../../usuarios/models/usuario_model.dart';
import '../../usuarios/screens/cadastro_usuario_screen.dart';

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

class _EquipeScreenState extends State<EquipeScreen> {
  final _controller = UsuarioController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (widget.empresaId.isNotEmpty) {
        _controller.carregarUsuarios(widget.usuarioLogado, widget.empresaId);
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _irParaCadastro({UsuarioModel? membroEmEdicao}) async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => CadastroUsuarioScreen(
          empresaId: widget.empresaId,
          usuarioLogado: widget.usuarioLogado,
          membroEmEdicao: membroEmEdicao,
        ),
      ),
    );
    if (widget.empresaId.isNotEmpty) {
      _controller.carregarUsuarios(widget.usuarioLogado, widget.empresaId);
    }
  }

  void _abrirExtratoColaborador(UsuarioModel membro) {
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

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: widget.mostrarAppBar
          ? AppBar(title: const Text('Gestão de Equipe'))
          : null,
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _irParaCadastro(),
        icon: const Icon(Icons.person_add),
        label: const Text('Novo Membro'),
      ),
      body: ListenableBuilder(
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
                onTap: () => _abrirExtratoColaborador(membro),
                onEdit: () => _irParaCadastro(membroEmEdicao: membro),
                onToggleStatus: () async {
                  final sucesso = await _controller.alternarStatus(
                    membro,
                    widget.usuarioLogado,
                  );

                  if (!mounted) return;

                  if (!sucesso) {
                    SnackbarUtil.showError(
                      context,
                      _controller.erroMensagem ?? 'Erro ao alterar status.',
                    );
                  } else {
                    _controller.carregarUsuarios(
                      widget.usuarioLogado,
                      widget.empresaId,
                    );
                  }
                },
              );
            },
          );
        },
      ),
    );
  }
}