import 'package:flutter/material.dart';
import '../models/usuario_model.dart';
import '../controllers/usuario_controller.dart';
import '../../admin/controllers/setor_controller.dart';
import '../../../core/utils/snackbar_util.dart';
import '../../../core/themes/app_themes.dart';
import '../../../core/widgets/custom_text_field.dart';

class CadastroUsuarioScreen extends StatefulWidget {
  final String empresaId;
  final UsuarioModel? membroEmEdicao;

  const CadastroUsuarioScreen({
    Key? key,
    required this.empresaId,
    this.membroEmEdicao,
  }) : super(key: key);

  @override
  State<CadastroUsuarioScreen> createState() => _CadastroUsuarioScreenState();
}

class _CadastroUsuarioScreenState extends State<CadastroUsuarioScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nomeController = TextEditingController();
  final _emailController = TextEditingController();
  
  String? _tipoSelecionado;
  String? _setorSelecionado;

  final _usuarioController = UsuarioController();
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

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _setorController.carregarSetores(widget.empresaId);
    });
  }

  @override
  void dispose() {
    _nomeController.dispose();
    _emailController.dispose();
    _usuarioController.dispose();
    _setorController.dispose();
    super.dispose();
  }

  Future<void> _salvar() async {
    if (!_formKey.currentState!.validate()) return;

    final sucesso = await _usuarioController.salvarUsuario(
      idEdicao: widget.membroEmEdicao?.id,
      empresaId: widget.empresaId,
      nome: _nomeController.text,
      email: _emailController.text,
      tipoUsuario: _tipoSelecionado!,
      setorId: _setorSelecionado,
    );

    if (!mounted) return;

    if (sucesso) {
      // Como o SnackbarUtil só tem o showError por enquanto, mantemos o nativo para sucesso
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(ehEdicao ? 'Dados atualizados com sucesso!' : 'Membro cadastrado com sucesso!\nSenha padrão: 123456'),
          backgroundColor: Colors.green, // Ou AppThemes.successColor se você criou
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 4),
        ),
      );
      Navigator.pop(context);
    } else {
      SnackbarUtil.showError(
        context, 
        _usuarioController.erroMensagem ?? 'Erro ao salvar',
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

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
              CustomTextField(
                controller: _nomeController,
                labelText: 'Nome Completo',
                prefixIcon: Icons.person,
                validator: (value) => value == null || value.trim().length < 3 ? 'Informe um nome válido' : null,
              ),
              const SizedBox(height: 16),

              // E-MAIL
              CustomTextField(
                controller: _emailController,
                labelText: 'E-mail',
                prefixIcon: Icons.email,
                enabled: !ehEdicao, // Passando o bloqueio para o widget!
                validator: (value) => value == null || !value.contains('@') ? 'Informe um e-mail válido' : null,
              ),
              if (ehEdicao) 
                Padding(
                  padding: const EdgeInsets.only(top: 4, left: 12),
                  child: Text(
                    'O e-mail de acesso não pode ser alterado.', 
                    style: TextStyle(fontSize: 12, color: theme.disabledColor),
                  ),
                ),
              const SizedBox(height: 16),

              // TIPO DE USUÁRIO
              DropdownButtonFormField<String>(
                value: _tipoSelecionado,
                decoration: InputDecoration(
                  labelText: 'Tipo de Acesso',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  prefixIcon: Icon(Icons.badge, color: theme.primaryColor),
                  filled: true,
                  fillColor: theme.cardColor,
                ),
                items: const [
                  DropdownMenuItem(value: 'GESTOR', child: Text('Gestor (Admin do Setor)')),
                  DropdownMenuItem(value: 'FUNCIONARIO', child: Text('Funcionário')),
                ],
                onChanged: (value) => setState(() => _tipoSelecionado = value),
                validator: (value) => value == null ? 'Selecione o tipo de acesso' : null,
              ),
              const SizedBox(height: 16),

              // SETOR (Dinâmico do banco de dados com ListenableBuilder)
              ListenableBuilder(
                listenable: _setorController,
                builder: (context, _) {
                  if (_setorController.isLoading) {
                    return Center(child: CircularProgressIndicator(color: theme.primaryColor));
                  }

                  if (_setorController.setores.isEmpty) {
                    return const Text(
                      'Nenhum setor cadastrado na empresa. Cadastre um setor primeiro.', 
                      style: TextStyle(color: AppThemes.errorColor),
                    );
                  }

                  return DropdownButtonFormField<String>(
                    value: _setorSelecionado,
                    decoration: InputDecoration(
                      labelText: 'Setor',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      prefixIcon: Icon(Icons.account_tree, color: theme.primaryColor),
                      filled: true,
                      fillColor: theme.cardColor,
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

              // BOTÃO SALVAR (ListenableBuilder)
              ListenableBuilder(
                listenable: _usuarioController,
                builder: (context, _) {
                  if (_usuarioController.isLoading) {
                    return Center(child: CircularProgressIndicator(color: theme.primaryColor));
                  }
                  return ElevatedButton(
                    onPressed: _setorController.setores.isEmpty ? null : _salvar,
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      backgroundColor: theme.primaryColor,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text('Salvar Membro da Equipe', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
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