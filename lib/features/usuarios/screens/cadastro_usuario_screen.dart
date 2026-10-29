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
  final _cpfController = TextEditingController();
  
  // Controllers
  final _usuarioController = UsuarioController();
  final _setorController = SetorController();
  final _jornadaController = JornadaController();
  
  String? _tipoSelecionado;
  String? _setorSelecionado;
  String? _jornadaSelecionada;  
  bool _dadosAlterados = false;
  bool get ehEdicao => widget.membroEmEdicao != null;
  bool get ehAdmin => widget.usuarioLogado.tipoUsuario == TipoUsuario.administrador;


  @override
  void initState() {
    super.initState();
    
    if (ehEdicao) {
      _nomeController.text = widget.membroEmEdicao!.nome;
      _emailController.text = widget.membroEmEdicao!.email;
      _cpfController.text = widget.membroEmEdicao!.cpf;
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
    _cpfController.dispose();
    _usuarioController.dispose();
    _setorController.dispose();
    super.dispose();
  }
  void _verificarAlteracoes() {
    if (!ehEdicao) return;

    final membro = widget.membroEmEdicao!;

    final alterado =
        _nomeController.text.trim() != membro.nome.trim() ||
        _cpfController.text.trim() != membro.cpf.trim() ||
        _tipoSelecionado != membro.tipoUsuario.name.toUpperCase() ||
        _setorSelecionado != membro.setorId;

    if (_dadosAlterados != alterado) {
      setState(() {
        _dadosAlterados = alterado;
      });
    }
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
      cpf: _cpfController.text,
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
                onChanged: (_) => _verificarAlteracoes(),
                validator: (value) => value == null || value.trim().length < 3 ? 'Informe um nome válido' : null,
              ),
              const SizedBox(height: 16),
              CustomTextField(
                controller: _cpfController,
                labelText: 'CPF',
                prefixIcon: Icons.badge,
                onChanged: (_) => _verificarAlteracoes(),                              
                validator: (value) {
                  if (value == null || value.trim().length != 11) {
                    return 'Informe um CPF válido (11 dígitos)';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              CustomTextField(
                controller: _emailController,
                labelText: 'E-mail',
                prefixIcon: Icons.email,
                enabled: !ehEdicao,
                validator: (value) => value == null || !value.contains('@') ? 'Informe um e-mail válido' : null,
              ),
              const SizedBox(height: 16),
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
                  onChanged: (value) {setState(() {_tipoSelecionado = value; }); _verificarAlteracoes();},
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
                      onChanged: (value) {setState(() {_setorSelecionado = value; }); _verificarAlteracoes();},
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
                        const SizedBox(height: 24),
                        
                        // Banner Interativo de Dispositivo
                        Material(
                          color: Colors.transparent,
                          child: InkWell(
                            onTap: _usuarioController.isLoading || !temDispositivo
                                ? null 
                                : _confirmarDesvinculacao,
                            borderRadius: BorderRadius.circular(20),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(20),
                              child: Stack(
                                children: [
                                  // Círculo decorativo de fundo (Design)
                                  Positioned(
                                    top: -40,
                                    right: -40,
                                    child: Container(
                                      width: 130,
                                      height: 130,
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        color: temDispositivo 
                                            ? Colors.red.withOpacity(0.08)
                                            : theme.disabledColor.withOpacity(0.08),
                                      ),
                                    ),
                                  ),
                                  
                                  // Conteúdo do Banner
                                  Container(
                                    width: double.infinity,
                                    padding: const EdgeInsets.all(20.0),
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(20),
                                      border: Border.all(
                                        color: temDispositivo 
                                            ? Colors.red.withOpacity(0.3) 
                                            : theme.dividerColor,
                                        width: 1.5,
                                      ),
                                      color: theme.cardColor,
                                    ),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          children: [
                                            Icon(
                                              temDispositivo ? Icons.phonelink_setup : Icons.phonelink_erase,
                                              size: 26,
                                              color: temDispositivo ? Colors.red[700] : theme.disabledColor,
                                            ),
                                            const SizedBox(width: 12),
                                            Expanded(
                                              child: Text(
                                                temDispositivo ? 'Aparelho Vinculado' : 'Sem Dispositivo',
                                                style: TextStyle(
                                                  fontSize: 18,
                                                  fontWeight: FontWeight.w900,
                                                  color: temDispositivo ? Colors.red[700] : theme.disabledColor,
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 12),
                                        
                                        Text(
                                          temDispositivo 
                                              ? widget.membroEmEdicao!.dispositivoUsuario!
                                              : 'Nenhum aparelho celular vinculado a esta conta de usuário no momento.',
                                          style: TextStyle(
                                            fontSize: 15,
                                            fontWeight: temDispositivo ? FontWeight.w600 : FontWeight.normal,
                                            color: theme.colorScheme.onSurfaceVariant,
                                          ),
                                        ),
                                        
                                        if (temDispositivo) ...[
                                          const SizedBox(height: 12),
                                          Row(
                                            children: [
                                              Icon(
                                                Icons.touch_app, 
                                                size: 16, 
                                                color: Colors.red[400]
                                              ),
                                              const SizedBox(width: 6),
                                              Expanded(
                                                child: Text(
                                                  'Toque neste banner para descadastrar o dispositivo.',
                                                  style: TextStyle(
                                                    fontSize: 13,
                                                    color: Colors.red[400],
                                                    fontWeight: FontWeight.w600,
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ),
                                        ],
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
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