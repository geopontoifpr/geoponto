import 'package:flutter/material.dart';
import '../models/usuario_model.dart';
import '../controllers/usuario_controller.dart';
import '../../admin/controllers/setor_controller.dart';
import '../../../core/utils/snackbar_util.dart';
import '../../../core/themes/app_themes.dart';
import '../../../core/widgets/custom_text_field.dart';
import '../../jornadas/controllers/jornada_controller.dart';

class CadastroUsuarioScreen extends StatefulWidget {
  final String empresaId;
  final UsuarioModel? membroEmEdicao;
  final UsuarioModel usuarioLogado;
  
  const CadastroUsuarioScreen({
    Key? key,
    required this.empresaId,
    this.membroEmEdicao,
    required this.usuarioLogado,
  }) : super(key: key);

  @override
  State<CadastroUsuarioScreen> createState() => _CadastroUsuarioScreenState();
}

class _CadastroUsuarioScreenState extends State<CadastroUsuarioScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nomeController = TextEditingController();
  final _emailController = TextEditingController();
  
  // Controllers
  final _usuarioController = UsuarioController();
  final _setorController = SetorController();
  final _jornadaController = JornadaController();
  
  String? _tipoSelecionado;
  String? _setorSelecionado;
  String? _jornadaSelecionada;  

  bool get ehEdicao => widget.membroEmEdicao != null;
  bool get ehAdmin => widget.usuarioLogado.tipoUsuario == TipoUsuario.administrador;

  @override
  void initState() {
    super.initState();
    
    if (ehEdicao) {
      _nomeController.text = widget.membroEmEdicao!.nome;
      _emailController.text = widget.membroEmEdicao!.email;
      _tipoSelecionado = widget.membroEmEdicao!.tipoUsuario.name.toUpperCase();
      _setorSelecionado = widget.membroEmEdicao!.setorId;
    }
    
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await _jornadaController.carregarJornadas();
      
      if (ehEdicao) {
        final jornadaId = await _jornadaController.buscarJornadaSelecionada(widget.membroEmEdicao!.id);
        if (jornadaId != null && mounted) {
          setState(() {
            _jornadaSelecionada = jornadaId;
          });
        }
      }

      if (ehAdmin && mounted) {
        _setorController.carregarSetores(widget.empresaId);
      }
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

    final String tipoAEnviar;
    final String? setorAEnviar;

    if (ehAdmin) {
      tipoAEnviar = _tipoSelecionado!;
      setorAEnviar = _setorSelecionado;
    } else {
      tipoAEnviar = TipoUsuario.funcionario.name.toUpperCase();
      setorAEnviar = widget.usuarioLogado.setorId;
    }

    final sucesso = await _usuarioController.salvarUsuario(
      idEdicao: widget.membroEmEdicao?.id,
      empresaId: widget.empresaId,
      usuarioLogado: widget.usuarioLogado,
      nome: _nomeController.text,
      email: _emailController.text,
      tipoUsuario: tipoAEnviar,
      setorId: setorAEnviar,
    );

    if (!mounted) return;

    if (sucesso) {
      if (_jornadaSelecionada != null) {
        String? usuarioAlvoId;
        
        if (ehEdicao) {
           usuarioAlvoId = widget.membroEmEdicao!.id;
        } else {
           // Delegamos a responsabilidade de buscar o ID para o Controller, mantendo o MVC intacto.
           usuarioAlvoId = await _usuarioController.obterIdPorEmail(_emailController.text.trim());
        }
        
        if (usuarioAlvoId != null) {
          await _jornadaController.salvarJornadaUsuario(usuarioAlvoId, _jornadaSelecionada!);
        }
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(ehEdicao ? 'Dados atualizados com sucesso!' : 'Membro cadastrado com sucesso!\nSenha padrão: 123456'),
          backgroundColor: Colors.green,
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
  Future<void> _confirmarDesvinculacao() async {
    final confirmou = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Desvincular Aparelho?'),
        content: const Text(
          'O celular atual deste funcionário será removido. '
          'Ele precisará vincular o novo aparelho no próximo login.\n\nDeseja continuar?'
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Desvincular', style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );

    if (confirmou == true && mounted) {
      final sucesso = await _usuarioController.desvincularDispositivo(widget.membroEmEdicao!.id);
      
      if (!mounted) return;

      if (sucesso) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Dispositivo desvinculado com sucesso!'),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        SnackbarUtil.showError(context, _usuarioController.erroMensagem ?? 'Erro ao desvincular dispositivo.');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

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
              CustomTextField(
                controller: _nomeController,
                labelText: 'Nome Completo',
                prefixIcon: Icons.person,
                validator: (value) => value == null || value.trim().length < 3 ? 'Informe um nome válido' : null,
              ),
              const SizedBox(height: 16),

              CustomTextField(
                controller: _emailController,
                labelText: 'E-mail',
                prefixIcon: Icons.email,
                enabled: !ehEdicao,
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

              if (ehAdmin) ...[
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
                const SizedBox(height: 16),
              ] else ...[
                const SizedBox(height: 4),
              ],

              ListenableBuilder(
                listenable: _jornadaController,
                builder: (context, _) {
                  if (_jornadaController.isLoading) {
                    return Center(child: CircularProgressIndicator(color: theme.primaryColor));
                  }

                  if (_jornadaController.jornadas.isEmpty) {
                    return const Padding(
                      padding: EdgeInsets.symmetric(vertical: 8.0),
                      child: Text(
                        'Nenhuma jornada cadastrada no banco de dados.', 
                        style: TextStyle(color: AppThemes.errorColor),
                      ),
                    );
                  }

                  return DropdownButtonFormField<String>(
                    value: _jornadaSelecionada,
                    decoration: InputDecoration(
                      labelText: 'Jornada de Trabalho',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      prefixIcon: Icon(Icons.schedule, color: theme.primaryColor),
                      filled: true,
                      fillColor: theme.cardColor,
                    ),
                    items: _jornadaController.jornadas.map((jornada) {
                      return DropdownMenuItem(
                        value: jornada.id,
                        child: Text('${jornada.cargaHorariaSem} Horas Semanais'), 
                      );
                    }).toList(),
                    onChanged: (value) => setState(() => _jornadaSelecionada = value),
                    validator: (value) => value == null ? 'Selecione uma jornada' : null,
                  );
                },
              ),
              const SizedBox(height: 32),

             ListenableBuilder(
                listenable: _usuarioController,
                builder: (context, _) {
                  if (_usuarioController.isLoading) {
                    return Center(child: CircularProgressIndicator(color: theme.primaryColor));
                  }
                  
                  final botaoBloqueado = ehAdmin && _setorController.setores.isEmpty;
                  final temDispositivo = widget.membroEmEdicao?.dispositivoUsuario != null && 
                                         widget.membroEmEdicao!.dispositivoUsuario!.trim().isNotEmpty;

                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      ElevatedButton(
                        onPressed: botaoBloqueado ? null : _salvar,
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          backgroundColor: theme.primaryColor,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: const Text('Salvar Membro da Equipe', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                      ),
                      
                      // Exibe os controles de dispositivo APENAS se for edição
                      if (ehEdicao) ...[
                        const SizedBox(height: 16),
                        OutlinedButton.icon(
                          onPressed: _usuarioController.isLoading 
                            ? null 
                            : () {
                                if (!temDispositivo) {
                                  SnackbarUtil.showError(context, 'Este usuário não possui nenhum dispositivo cadastrado no momento.');
                                  return;
                                }
                                _confirmarDesvinculacao();
                              },
                          icon: const Icon(Icons.phonelink_erase, color: Colors.red),
                          label: const Text(
                            'Desvincular Dispositivo', 
                            style: TextStyle(color: Colors.red, fontSize: 16, fontWeight: FontWeight.bold)
                          ),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            side: const BorderSide(color: Colors.red),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                        
                        const SizedBox(height: 8),
                        
                        // Novo: Texto informando o status do dispositivo
                        Text(
                          temDispositivo 
                              ? 'Dispositivo vinculado: ${widget.membroEmEdicao!.dispositivoUsuario}'
                              : 'Nenhum dispositivo vinculado a esta conta.',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 13,
                            color: temDispositivo ? theme.textTheme.bodySmall?.color : Colors.orange[700],
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                      ],
                    ],
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