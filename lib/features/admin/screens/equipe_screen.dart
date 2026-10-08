import 'package:flutter/material.dart';
import '../controllers/equipe_controller.dart';
import 'cadastro_equipe_screen.dart';
import '../../usuarios/models/usuario_model.dart';

class EquipeScreen extends StatefulWidget {
  final String empresaId;
  const EquipeScreen({Key? key, required this.empresaId}) : super(key: key);

  @override
  State<EquipeScreen> createState() => _EquipeScreenState();
}

class _EquipeScreenState extends State<EquipeScreen> {
  final _controller = EquipeController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _controller.carregarEquipe(widget.empresaId);
    });
  }

  void _irParaCadastro({UsuarioModel? membroEmEdicao}) async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => CadastroEquipeScreen(
          empresaId: widget.empresaId,
          membroEmEdicao: membroEmEdicao, // Passa nulo se for novo
        ),
      ),
    );
    _controller.carregarEquipe(widget.empresaId); // Recarrega ao voltar
  }

  @override
  Widget build(BuildContext context) {
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
          if (_controller.isLoading && _controller.equipe.isEmpty) {
            return const Center(child: CircularProgressIndicator());
          }
          
          if (_controller.equipe.isEmpty) {
             return const Center(child: Text('Ninguém na equipe ainda.'));
          }

          return ListView.builder(
            itemCount: _controller.equipe.length,
            itemBuilder: (context, index) {
              final membro = _controller.equipe[index];
              return ListTile(
                leading: CircleAvatar(
                  backgroundColor: membro.ativo ? Colors.blue : Colors.grey,
                  child: Icon(membro.tipoUsuario == 'GESTOR' ? Icons.manage_accounts : Icons.person),
                ),
                title: Text(membro.nome, style: TextStyle(
                  decoration: membro.ativo ? null : TextDecoration.lineThrough,
                  color: membro.ativo ? Colors.black : Colors.grey,
                )),
                subtitle: Text('${membro.tipoUsuario} • ${membro.email}'),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.edit, color: Colors.blue),
                      onPressed: () => _irParaCadastro(membroEmEdicao: membro),
                    ),
                    IconButton(
                      icon: Icon(membro.ativo ? Icons.block : Icons.check_circle, 
                        color: membro.ativo ? Colors.red : Colors.green),
                      tooltip: membro.ativo ? 'Inativar Usuário' : 'Reativar Usuário',
                      onPressed: () => _controller.alternarStatus(membro.id, membro.ativo, widget.empresaId),
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }
}