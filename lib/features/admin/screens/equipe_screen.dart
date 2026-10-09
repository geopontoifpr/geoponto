import 'package:flutter/material.dart';
import '../../usuarios/controllers/usuario_controller.dart';
import '../../usuarios/screens/cadastro_usuario_adm_screen.dart';
import '../../usuarios/models/usuario_model.dart';
import '../../../core/themes/app_themes.dart'; 
import '../../../core/utils/snackbar_util.dart';
import '../../../core/widgets/usuario_list.dart';

class EquipeScreen extends StatefulWidget {
  final String empresaId;
  const EquipeScreen({Key? key, required this.empresaId}) : super(key: key);

  @override
  State<EquipeScreen> createState() => _EquipeScreenState();
}

class _EquipeScreenState extends State<EquipeScreen> {
  final _controller = UsuarioController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _controller.carregarUsuarios(widget.empresaId);
    });
  }

  void _irParaCadastro({UsuarioModel? membroEmEdicao}) async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => CadastroUsuarioScreen(
          empresaId: widget.empresaId,
          membroEmEdicao: membroEmEdicao,
        ),
      ),
    );
    _controller.carregarUsuarios(widget.empresaId); // Recarrega ao voltar
  }

  @override
  Widget build(BuildContext context) {
    // Puxa o tema atual (Claro ou Escuro) para adaptar as fontes e cores base
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Gestão de Equipe')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _irParaCadastro(),
        icon: const Icon(Icons.person_add),
        label: const Text('Novo Membro'),
      ),
      body: AnimatedBuilder(
        animation: _controller,
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
                 style: const TextStyle(color: AppThemes.errorColor), // Usa a cor de erro do seu Theme
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
              
              // Aqui nós chamamos o seu novo componente lindão!
              return UsuarioList(
                membro: membro,
                
                // O que acontece ao clicar em Editar
                onEdit: () => _irParaCadastro(membroEmEdicao: membro),
                
                // O que acontece ao clicar em Bloquear/Desbloquear
                onToggleStatus: () async {
                  final sucesso = await _controller.alternarStatus(membro, widget.empresaId);
                  
                  if (!mounted) return;
                  
                  if (!sucesso) {
                    SnackbarUtil.showError(
                      context, 
                      _controller.erroMensagem ?? 'Erro ao alterar status.',
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