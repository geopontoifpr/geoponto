import 'package:flutter/material.dart';
import '../../usuarios/models/usuario_model.dart';
import '../controllers/equipe_controller.dart';
import '../controllers/setor_controller.dart';

class CadastroEquipeScreen extends StatefulWidget {
  final String empresaId;
  final UsuarioModel? membroEmEdicao;

  const CadastroEquipeScreen({
    Key? key,
    required this.empresaId,
    this.membroEmEdicao,
  }) : super(key: key);

  @override
  State<CadastroEquipeScreen> createState() => _CadastroEquipeScreenState();
}

class _CadastroEquipeScreenState extends State<CadastroEquipeScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nomeController = TextEditingController();
  final _emailController = TextEditingController();
  
  String? _tipoSelecionado;
  String? _setorSelecionado;

  final _equipeController = EquipeController();
  final _setorController = SetorController();

  bool get ehEdicao => widget.membroEmEdicao != null;

  @override
  void initState() {
    super.initState();
    
    if (ehEdicao) {
      _nomeController.text = widget.membroEmEdicao!.nome;
      _emailController.text = widget.membroEmEdicao!.email;
      _tipoSelecionado = widget.membroEmEdicao!.tipoUsuario.name.toUpperCase();
      _setorSelecionado = widget.membroEmEdicao!.setorId;
    }

    // Carrega os setores da empresa para popular o Dropdown
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _setorController.carregarSetores(widget.empresaId);
    });
  }

  @override
  void dispose() {
    _nomeController.dispose();
    _emailController.dispose();
    _equipeController.dispose();
    _setorController.dispose();
    super.dispose();
  }

  Future<void> _salvar() async {
    if (!_formKey.currentState!.validate()) return;

    final sucesso = await _equipeController.salvarMembro(
      idEdicao: widget.membroEmEdicao?.id,
      empresaId: widget.empresaId,
      nome: _nomeController.text,
      email: _emailController.text, // Vai mandar o e-mail mesmo na edição, mas o service pode ignorar
      tipoUsuario: _tipoSelecionado!,
      setorId: _setorSelecionado,
    );

    if (!mounted) return;

    if (sucesso) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(ehEdicao ? 'Dados atualizados com sucesso!' : 'Membro cadastrado com sucesso!\nSenha padrão: 123456'),
          backgroundColor: Colors.green,
          duration: const Duration(seconds: 4),
        ),
      );
      Navigator.pop(context); // Volta para a lista
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(_equipeController.erroMensagem ?? 'Erro ao salvar'), backgroundColor: Colors.red),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(ehEdicao ? 'Editar Membro' : 'Novo Membro'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // NOME
              TextFormField(
                controller: _nomeController,
                decoration: const InputDecoration(
                  labelText: 'Nome Completo',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.person),
                ),
                validator: (value) => value == null || value.trim().length < 3 ? 'Informe um nome válido' : null,
              ),
              const SizedBox(height: 16),

              // E-MAIL (Travado se for edição)
              TextFormField(
                controller: _emailController,
                enabled: !ehEdicao, // <-- A MÁGICA: Desativa o input se for edição
                decoration: InputDecoration(
                  labelText: 'E-mail',
                  border: const OutlineInputBorder(),
                  prefixIcon: const Icon(Icons.email),
                  filled: ehEdicao,
                  fillColor: ehEdicao ? Colors.grey.shade200 : null,
                ),
                validator: (value) => value == null || !value.contains('@') ? 'Informe um e-mail válido' : null,
              ),
              if (ehEdicao) 
                const Padding(
                  padding: EdgeInsets.only(top: 4, left: 12),
                  child: Text('O e-mail de acesso não pode ser alterado.', style: TextStyle(fontSize: 12, color: Colors.grey)),
                ),
              const SizedBox(height: 16),

              // TIPO DE USUÁRIO
              DropdownButtonFormField<String>(
                value: _tipoSelecionado,
                decoration: const InputDecoration(
                  labelText: 'Tipo de Acesso',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.badge),
                ),
                items: const [
                  DropdownMenuItem(value: 'GESTOR', child: Text('Gestor (Admin do Setor)')),
                  DropdownMenuItem(value: 'FUNCIONARIO', child: Text('Funcionário')),
                ],
                onChanged: (value) => setState(() => _tipoSelecionado = value),
                validator: (value) => value == null ? 'Selecione o tipo de acesso' : null,
              ),
              const SizedBox(height: 16),

              // SETOR (Dinâmico do banco de dados)
              AnimatedBuilder(
                animation: _setorController,
                builder: (context, _) {
                  if (_setorController.isLoading) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  if (_setorController.setores.isEmpty) {
                    return const Text('Nenhum setor cadastrado na empresa. Cadastre um setor primeiro.', style: TextStyle(color: Colors.red));
                  }

                  return DropdownButtonFormField<String>(
                    value: _setorSelecionado,
                    decoration: const InputDecoration(
                      labelText: 'Setor',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.account_tree),
                    ),
                    items: _setorController.setores.map((setor) {
                      return DropdownMenuItem(
                        value: setor.id,
                        child: Text(setor.nome),
                      );
                    }).toList(),
                    onChanged: (value) => setState(() => _setorSelecionado = value),
                    validator: (value) => value == null ? 'Selecione um setor' : null,
                  );
                },
              ),
              const SizedBox(height: 32),

              // BOTÃO SALVAR
              AnimatedBuilder(
                animation: _equipeController,
                builder: (context, _) {
                  if (_equipeController.isLoading) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  return ElevatedButton(
                    onPressed: _setorController.setores.isEmpty ? null : _salvar, // Trava se não houver setores
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                    child: const Text('Salvar Membro da Equipe', style: TextStyle(fontSize: 16)),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}