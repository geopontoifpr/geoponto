import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/utils/snackbar_util.dart';
import '../../../core/widgets/custom_text_field.dart';
import '../../../core/widgets/primary_button.dart';
import '../models/usuario_model.dart';
import '../controllers/usuario_controller.dart';
import '../../auth/controllers/login_controller.dart';

class PerfilUsuarioScreen extends StatefulWidget {
  final UsuarioModel usuario;

  const PerfilUsuarioScreen({super.key, required this.usuario});

  @override
  State<PerfilUsuarioScreen> createState() => _PerfilUsuarioScreenState();
}

class _PerfilUsuarioScreenState extends State<PerfilUsuarioScreen> {
  final _usuarioController = UsuarioController();
  final _loginController = LoginController();

  void _atualizarTela() {
    if (mounted) setState(() {});
  }

  @override
  void initState() {
    super.initState();
    _usuarioController.addListener(_atualizarTela);
    _loginController.addListener(_atualizarTela);
  }

  @override
  void dispose() {
    _usuarioController.removeListener(_atualizarTela);
    _loginController.removeListener(_atualizarTela);
    _usuarioController.dispose();
    _loginController.dispose();
    super.dispose();
  }

  // --- MODAL PARA EDITAR O NOME ---
  Future<void> _abrirModalNome() async {
    final nomeController = TextEditingController(text: widget.usuario.nome);

    await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Editar Nome'),
        content: CustomTextField(
          controller: nomeController,
          labelText: 'Nome Completo',
          prefixIcon: Icons.person_outline,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (nomeController.text.trim().isEmpty) {
                SnackbarUtil.showError(ctx, 'O nome não pode ser vazio.');
                return;
              }
              
              final sucesso = await _usuarioController.atualizarNome(
                widget.usuario, 
                nomeController.text,
              );
              
              if (!ctx.mounted) return;
              
              if (sucesso) {
                Navigator.pop(ctx);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Nome atualizado!'), backgroundColor: Colors.green),
                );
              } else {
                SnackbarUtil.showError(ctx, _usuarioController.erroMensagem ?? 'Erro ao salvar');
              }
            },
            child: const Text('Salvar'),
          ),
        ],
      ),
    );
  }

  // --- MODAL PARA EDITAR A SENHA ---
  Future<void> _abrirModalSenha() async {
    final novaSenhaController = TextEditingController();
    final confirmarSenhaController = TextEditingController();

    await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Alterar Senha'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CustomTextField(
              controller: novaSenhaController,
              labelText: 'Nova Senha',
              prefixIcon: Icons.lock_outline,
              obscureText: true,
            ),
            const SizedBox(height: 16),
            CustomTextField(
              controller: confirmarSenhaController,
              labelText: 'Confirmar Senha',
              prefixIcon: Icons.lock_reset,
              obscureText: true,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () async {
              final nova = novaSenhaController.text;
              final confirma = confirmarSenhaController.text;

              if (nova.length < 6) {
                SnackbarUtil.showError(ctx, 'A senha deve ter no mínimo 6 caracteres.');
                return;
              }
              if (nova != confirma) {
                SnackbarUtil.showError(ctx, 'As senhas não coincidem.');
                return;
              }

              // Reaproveitando o seu método existente no LoginController
              final sucesso = await _loginController.configurarPrimeiroAcesso(
                nova, 
                confirma, 
                widget.usuario.id!,
              );

              if (!ctx.mounted) return;

              if (sucesso) {
                Navigator.pop(ctx);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Senha alterada com sucesso!'), backgroundColor: Colors.green),
                );
              } else {
                SnackbarUtil.showError(ctx, _loginController.erro ?? 'Erro ao alterar senha');
              }
            },
            child: const Text('Salvar'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final temDispositivo = widget.usuario.dispositivoUsuario != null && widget.usuario.dispositivoUsuario!.isNotEmpty;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Meu Perfil', style: TextStyle(fontWeight: FontWeight.bold)),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context, widget.usuario.nome), // Retorna o nome atualizado para a AppBar
        ),
      ),
      // Overlay de carregamento caso os controllers estejam ocupados
      body: Stack(
        children: [
          SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // --- INFORMAÇÕES PESSOAIS ---
                Text('Dados Pessoais', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                const SizedBox(height: 12),
                
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const CircleAvatar(child: Icon(Icons.person_outline)),
                  title: Text(widget.usuario.nome, style: const TextStyle(fontWeight: FontWeight.w600)),
                  subtitle: const Text('Nome Completo'),
                  trailing: IconButton(
                    icon: const Icon(Icons.edit, color: AppColors.primary),
                    onPressed: _abrirModalNome,
                  ),
                ),
                const Divider(),

                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const CircleAvatar(
                    backgroundColor: Colors.transparent,
                    child: Icon(Icons.badge_outlined, color: Colors.grey),
                  ),
                  title: Text(widget.usuario.cpf),
                  subtitle: const Text('CPF'),
                ),
                const Divider(),
                
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const CircleAvatar(
                    backgroundColor: Colors.transparent,
                    child: Icon(Icons.email_outlined, color: Colors.grey),
                  ),
                  title: Text(widget.usuario.email),
                  subtitle: const Text('E-mail corporativo'),
                ),
                const SizedBox(height: 32),

                // --- DISPOSITIVO VINCULADO ---
                Text('Segurança de Acesso', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                const SizedBox(height: 16),
                ClipRRect(
                  borderRadius: BorderRadius.circular(20),
                  child: Stack(
                    children: [
                      Positioned(
                        top: -40,
                        right: -40,
                        child: Container(
                          width: 130,
                          height: 130,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: temDispositivo ? Colors.green.withOpacity(0.08) : theme.disabledColor.withOpacity(0.08),
                          ),
                        ),
                      ),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(20.0),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: temDispositivo ? Colors.green.withOpacity(0.3) : theme.dividerColor,
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
                                  color: temDispositivo ? Colors.green[600] : theme.disabledColor,
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Text(
                                    temDispositivo ? 'Aparelho Vinculado' : 'Sem Dispositivo',
                                    style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.w900,
                                      color: temDispositivo ? Colors.green[600] : theme.disabledColor,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            Text(
                              temDispositivo 
                                  ? widget.usuario.dispositivoUsuario!
                                  : 'Nenhum aparelho celular vinculado a esta conta no momento.',
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: temDispositivo ? FontWeight.w600 : FontWeight.normal,
                                color: theme.colorScheme.onSurfaceVariant,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 32),

                // --- BOTÃO DE ALTERAR SENHA ---
                PrimaryButton(
                  text: 'Alterar Minha Senha',
                  isLoading: false, 
                  onPressed: _abrirModalSenha,
                  // Opcional: Você pode mudar a cor deste botão para diferenciar de uma ação primária
                ),
              ],
            ),
          ),
          
          if (_usuarioController.isLoading || _loginController.carregando)
            Container(
              color: Colors.black.withOpacity(0.3),
              child: const Center(child: CircularProgressIndicator()),
            ),
        ],
      ),
    );
  }
}