import 'package:flutter/material.dart';
import '../../../core/themes/app_themes.dart';
import '../../../core/utils/snackbar_util.dart';
import '../../../core/widgets/action_card.dart';
import '../../../core/widgets/custom_app_bar.dart';
import '../../usuarios/models/usuario_model.dart';
import '../controllers/empresa_controller.dart';
import 'cadastro_empresa_screen.dart';
import 'cadastro_setor_screen.dart';
import 'equipe_screen.dart';

class PainelEmpresaScreen extends StatefulWidget {
  final UsuarioModel usuario;

  const PainelEmpresaScreen({super.key, required this.usuario});

  @override
  State<PainelEmpresaScreen> createState() => _PainelEmpresaScreenState();
}

class _PainelEmpresaScreenState extends State<PainelEmpresaScreen> {
  late final EmpresaController _controller;

  @override
  void initState() {
    super.initState();
    _controller = EmpresaController(usuario: widget.usuario);
    _carregarPainel();
  }

  Future<void> _carregarPainel() async {
    await _controller.carregarDadosDoPainel();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      appBar: CustomAppBar(
        nomeUsuario: widget.usuario.nome,
        onPerfilPressed: () {},
      ),
      body: ListenableBuilder(
        listenable: _controller,
        builder: (context, _) {
          if (_controller.isLoading) {
            return Center(child: CircularProgressIndicator(color: theme.primaryColor));
          }

          final empresa = _controller.empresaAtual;
          final temEmpresa = empresa != null;

          return SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(24.0),
                  decoration: BoxDecoration(
                    color: theme.cardColor,
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: [AppThemes.cardShadow(context)],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Painel do Administrador',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1.2,
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        temEmpresa ? (empresa.nome ?? 'Sem nome') : 'Nenhuma empresa vinculada',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: colorScheme.onSurface,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        temEmpresa ? 'CNPJ: ${empresa.cnpj}' : 'Cadastre sua empresa no botão abaixo',
                        style: TextStyle(color: colorScheme.onSurfaceVariant),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 32),
                Text(
                  'Acesso Rápido',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: colorScheme.onSurface,
                  ),
                ),
                const SizedBox(height: 16),
                GridView.count(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  crossAxisCount: 2,
                  crossAxisSpacing: 16,
                  mainAxisSpacing: 16,
                  children: [
                    ActionCard(
                      title: temEmpresa ? 'Dados da\nEmpresa' : 'Cadastrar\nEmpresa',
                      icon: Icons.business_outlined,
                      onTap: () async {
                        await Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => CadastroEmpresaScreen(
                              empresa: empresa,
                              usuario: widget.usuario,
                            ),
                          ),
                        );
                        _carregarPainel();
                      },
                    ),
                    ActionCard(
                      title: 'Gerenciar\nSetores',
                      icon: Icons.account_tree_outlined,
                      onTap: () async {
                        if (!temEmpresa) {
                          SnackbarUtil.showError(context, 'Por favor, cadastre a empresa primeiro.');
                          return;
                        }
                        await Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => CadastroSetorScreen(empresaId: empresa.id),
                          ),
                        );
                      },
                    ),
                    ActionCard(
                      title: 'Gerenciar\nEquipe',
                      icon: Icons.people_alt_outlined,
                      onTap: () async {
                        if (!temEmpresa) {
                          SnackbarUtil.showError(context, 'Por favor, cadastre a empresa primeiro.');
                          return;
                        }
                        await Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => EquipeScreen(
                              empresaId: empresa.id,
                              usuarioLogado: widget.usuario,
                            ),
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}