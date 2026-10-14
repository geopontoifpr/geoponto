import 'package:flutter/material.dart';
import '../../usuarios/controllers/usuario_controller.dart';
import '../../usuarios/screens/cadastro_usuario_screen.dart';
import '../../usuarios/models/usuario_model.dart';
import '../../../core/themes/app_themes.dart'; 
import '../../../core/utils/snackbar_util.dart';
import '../../../core/widgets/usuario_list.dart';

class EquipeScreen extends StatefulWidget {
  final String empresaId;
  final UsuarioModel usuarioLogado; // 1. ADICIONADO: Agora a tela recebe quem está a aceder!

  const EquipeScreen({
    Key? key, 
    required this.empresaId,
    required this.usuarioLogado, // 1. ADICIONADO NO CONSTRUTOR
  }) : super(key: key);

  @override
  State<EquipeScreen> createState() => _EquipeScreenState();
}

class _EquipeScreenState extends State<EquipeScreen> {
  final _controller = UsuarioController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      // 2. CORRIGIDO: Agora passa o utilizador logado para o filtro do Controller
      _controller.carregarUsuarios(widget.usuarioLogado, widget.empresaId); 
    });
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
    // 3. CORRIGIDO: Recarrega passando o utilizador correto
    _controller.carregarUsuarios(widget.usuarioLogado, widget.empresaId); 
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Gestão de Equipe'),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _irParaCadastro(),
        icon: const Icon(Icons.person_add),
        label: const Text('Novo Membro'),
      ),
      body: ListenableBuilder(
        listenable: _controller,
        builder: (context, _) {
          // 4. CORRIGIDO: Padronizado para "_controller.usuarios" (no plural)
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
                onEdit: () => _irParaCadastro(membroEmEdicao: membro),
                onToggleStatus: () async {
                  final sucesso = await _controller.alternarStatus(membro, widget.usuarioLogado); // 5. CORRIGIDO: Passa o usuário logado para a função
                  
                  if (!mounted) return;
                  
                  if (!sucesso) {
                    SnackbarUtil.showError(
                      context, 
                      _controller.erroMensagem ?? 'Erro ao alterar status.',
                    );
                  } else {
                     // Recarrega a lista para mostrar o novo status imediatamente
                     _controller.carregarUsuarios(widget.usuarioLogado, widget.empresaId);
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