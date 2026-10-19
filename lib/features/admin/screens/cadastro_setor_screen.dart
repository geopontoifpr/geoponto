import 'package:flutter/material.dart';
import '../controllers/setor_controller.dart';
import '../models/setor_model.dart';

class CadastroSetorScreen extends StatefulWidget {
  final String empresaId;

  const CadastroSetorScreen({Key? key, required this.empresaId}) : super(key: key);

  @override
  State<CadastroSetorScreen> createState() => _CadastroSetorScreenState();
}

class _CadastroSetorScreenState extends State<CadastroSetorScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nomeController = TextEditingController();
  final _setorController = SetorController();
  
  String? _setorIdEmEdicao; // Controla se estamos criando ou editando

  @override
  void initState() {
    super.initState();
    // Carrega a lista de setores assim que a tela abre
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _setorController.carregarSetores(widget.empresaId);
    });
  }

  @override
  void dispose() {
    _nomeController.dispose();
    _setorController.dispose();
    super.dispose();
  }

  void _iniciarEdicao(SetorModel setor) {
    setState(() {
      _setorIdEmEdicao = setor.id;
      _nomeController.text = setor.nome;
    });
  }

  void _cancelarEdicao() {
    setState(() {
      _setorIdEmEdicao = null;
      _nomeController.clear();
    });
  }

  Future<void> _salvar() async {
    if (!_formKey.currentState!.validate()) return;

    final ehEdicao = _setorIdEmEdicao != null;
    
    final sucesso = await _setorController.salvarSetor(
      id: _setorIdEmEdicao ?? '', 
      empresaId: widget.empresaId,
      gestorId: null, 
      nome: _nomeController.text,
      ehEdicao: ehEdicao,
    );

    if (!mounted) return;

    if (sucesso) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(ehEdicao ? 'Setor atualizado!' : 'Setor cadastrado!'), 
          backgroundColor: Colors.green
        ),
      );
      _cancelarEdicao(); // Limpa o formulário
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(_setorController.erroMensagem ?? 'Erro'), backgroundColor: Colors.red),
      );
    }
  }

  Future<void> _excluir(SetorModel setor) async {
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Excluir Setor?'),
        content: Text('Tem certeza que deseja excluir o setor "${setor.nome}"?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancelar')),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true), 
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Excluir')
          ),
        ],
      ),
    );

    if (confirmar != true || !mounted) return;

    final sucesso = await _setorController.excluirSetor(setor.id, widget.empresaId);
    if (!mounted) return;

    if (sucesso) {
       // Se o usuário excluiu o setor que estava editando, limpa a edição
      if (_setorIdEmEdicao == setor.id) _cancelarEdicao();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Setor excluído.'), backgroundColor: Colors.green),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(_setorController.erroMensagem ?? 'Erro ao excluir'), backgroundColor: Colors.red),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Gerenciar Setores')),
      body: AnimatedBuilder(
        animation: _setorController,
        builder: (context, _) {
          return Column(
            children: [
              // PARTE SUPERIOR: O Formulário
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      TextFormField(
                        controller: _nomeController,
                        decoration: const InputDecoration(
                          labelText: 'Nome do Setor',
                          border: OutlineInputBorder(),
                        ),
                        validator: (value) => 
                            value == null || value.trim().isEmpty ? 'Informe o nome' : null,
                      ),
                      const SizedBox(height: 16),
                      
                      if (_setorController.isLoading)
                        const Center(child: CircularProgressIndicator())
                      else
                        Row(
                          children: [
                            Expanded(
                              child: ElevatedButton(
                                onPressed: _salvar,
                                child: Text(_setorIdEmEdicao == null ? 'Adicionar Setor' : 'Salvar Alterações'),
                              ),
                            ),
                            if (_setorIdEmEdicao != null) ...[
                              const SizedBox(width: 8),
                              OutlinedButton(
                                onPressed: _cancelarEdicao,
                                child: const Text('Cancelar'),
                              )
                            ]
                          ],
                        ),
                    ],
                  ),
                ),
              ),
              
              const Divider(thickness: 2),

              // PARTE INFERIOR: A Lista de Setores Cadastrados
              Expanded(
                child: _setorController.setores.isEmpty
                    ? const Center(child: Text('Nenhum setor cadastrado.'))
                    : ListView.builder(
                        itemCount: _setorController.setores.length,
                        itemBuilder: (context, index) {
                          final setor = _setorController.setores[index];
                          final editandoEsse = _setorIdEmEdicao == setor.id;

                          return ListTile(
                            tileColor: editandoEsse ? Colors.blue.withOpacity(0.1) : null,
                            leading: const CircleAvatar(
                              child: Icon(Icons.account_tree_outlined),
                            ),
                            title: Text(setor.nome, style: const TextStyle(fontWeight: FontWeight.bold)),
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                IconButton(
                                  icon: const Icon(Icons.edit, color: Colors.blue),
                                  onPressed: () => _iniciarEdicao(setor),
                                ),
                                IconButton(
                                  icon: const Icon(Icons.delete, color: Colors.red),
                                  onPressed: () => _excluir(setor),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
              ),
            ],
          );
        },
      ),
    );
  }
}