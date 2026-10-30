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
      final sucesso = await _usuarioController.desvincularDispositivo(widget.usuario.id);
      
      if (!mounted) return;

      if (sucesso) {
        // ADICIONE ESTE BLOCO PARA A TELA REAGIR IMEDIATAMENTE
        setState(() {
          widget.usuario.dispositivoUsuario = ''; // ou '' dependendo de como está no seu model
        });

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
    final ehAdmin = widget.usuario.tipoUsuario == TipoUsuario.administrador;

    // Dinâmica de cores baseada no perfil
    final corIconeETexto = temDispositivo 
        ? (ehAdmin ? Colors.red[700] : Colors.green[600]) 
        : theme.disabledColor;
    final corFundoBanner = temDispositivo 
        ? (ehAdmin ? Colors.red.withOpacity(0.08) : Colors.green.withOpacity(0.08)) 
        : theme.disabledColor.withOpacity(0.08);
    final corBordaBanner = temDispositivo 
        ? (ehAdmin ? Colors.red.withOpacity(0.3) : Colors.green.withOpacity(0.3)) 
        : theme.dividerColor;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Meu Perfil', style: TextStyle(fontWeight: FontWeight.bold)),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context, widget.usuario.nome),
        ),
      ),
      body: Stack(
        children: [
          SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Dados Pessoais', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                const SizedBox(height: 12),
                
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const CircleAvatar(child: Icon(Icons.person_outline)),
                  title: const Text('Nome Completo'),
                  subtitle: Text(widget.usuario.nome, style: const TextStyle(fontWeight: FontWeight.w600)),                  
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
                  title: const Text('CPF'),
                  subtitle: Text(widget.usuario.cpf),
                ),
                const Divider(),
                
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const CircleAvatar(
                    backgroundColor: Colors.transparent,
                    child: Icon(Icons.email_outlined, color: Colors.grey),
                  ),
                  title: const Text('E-mail corporativo'),
                  subtitle: Text(widget.usuario.email),                  
                ),
                const SizedBox(height: 32),

                // --- DISPOSITIVO VINCULADO ---
                Text('Segurança de Acesso', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                const SizedBox(height: 16),
                
                Material(
                  color: Colors.transparent,
                  child: InkWell(
                    // O clique só é liberado se tiver dispositivo E for administrador
                    onTap: (temDispositivo && ehAdmin && !_usuarioController.isLoading) 
                        ? _confirmarDesvinculacao 
                        : null,
                    borderRadius: BorderRadius.circular(20),
                    child: ClipRRect(
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
                                color: corFundoBanner,
                              ),
                            ),
                          ),
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(20.0),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(color: corBordaBanner, width: 1.5),
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
                                      color: corIconeETexto,
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Text(
                                        temDispositivo ? 'Aparelho Vinculado' : 'Sem Dispositivo',
                                        style: TextStyle(
                                          fontSize: 18,
                                          fontWeight: FontWeight.w900,
                                          color: corIconeETexto,
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
                                
                                // O texto instrucional de desvinculação só aparece se for admin e tiver dispositivo
                                if (temDispositivo && ehAdmin) ...[
                                  const SizedBox(height: 12),
                                  Row(
                                    children: [
                                      Icon(Icons.touch_app, size: 16, color: Colors.red[400]),
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
                const SizedBox(height: 32),

                // --- BOTÃO DE ALTERAR SENHA ---
                PrimaryButton(
                  text: 'Alterar Minha Senha',
                  isLoading: false, 
                  onPressed: _abrirModalSenha,
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