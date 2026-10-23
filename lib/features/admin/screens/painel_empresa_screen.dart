import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/themes/app_themes.dart';
import '../../../core/widgets/custom_app_bar.dart';
import '../../../core/screens/equipe_screen.dart';
import '../../usuarios/models/usuario_model.dart';
import '../controllers/empresa_controller.dart';
import 'cadastro_empresa_screen.dart';
import 'cadastro_setor_screen.dart';


class PainelEmpresaScreen extends StatefulWidget {
  final UsuarioModel usuario;
  final bool mostrarAppBar;
  final VoidCallback? onIrParaSetores;
  final VoidCallback? onIrParaEquipe;

  const PainelEmpresaScreen({
    super.key,
    required this.usuario,
    this.mostrarAppBar = true,
    this.onIrParaSetores,
    this.onIrParaEquipe,
  });

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

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _carregarPainel() async {
    await _controller.carregarDadosDoPainel();
  }

  Future<void> _abrirDadosEmpresa() async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => CadastroEmpresaScreen(
          empresa: _controller.empresaAtual,
          usuario: widget.usuario,
        ),
      ),
    );
    _carregarPainel();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    final conteudo = ListenableBuilder(
      listenable: _controller,
      builder: (context, _) {
        if (_controller.isLoading) {
          return Center(
            child: CircularProgressIndicator(color: theme.primaryColor),
          );
        }

        final empresa = _controller.empresaAtual;
        final temEmpresa = empresa != null;

        return SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Card Principal Clicável da Empresa (5ª imagem do protótipo)
              
              Material(
                color: theme.cardColor,
                borderRadius: BorderRadius.circular(28),
                child: InkWell(
                  onTap: _abrirDadosEmpresa,
                  borderRadius: BorderRadius.circular(28),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(28),
                    child: Stack(
                      children: [
                        Positioned(
                          top: -40,
                          right: -40,
                          child: Container(
                            width: 150,
                            height: 150,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: AppColors.progressGreen.withOpacity(0.12),
                            ),
                          ),
                        ),
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(26.0),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(28),
                            boxShadow: [AppThemes.cardShadow(context)],
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                temEmpresa
                                    ? (empresa.nome ?? 'Sem nome')
                                    : 'Cadastrar Empresa',
                                style: TextStyle(
                                  fontSize: 24,
                                  fontWeight: FontWeight.w900,
                                  color: colorScheme.onSurface,
                                ),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                temEmpresa
                                    ? 'CNPJ: ${empresa.cnpj}'
                                    : 'Toque neste cartão para configurar os dados da empresa',
                                style: TextStyle(
                                  fontSize: 15,
                                  color: colorScheme.onSurfaceVariant,
                                ),
                              ),
                              if (temEmpresa) ...[
                                const SizedBox(height: 8),
                                Row(
                                  children: [
                                    Icon(
                                      Icons.location_on_outlined,
                                      size: 16,
                                      color: colorScheme.onSurfaceVariant,
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      'Raio permitido: ${empresa.raioPermitido ?? 50}m',
                                      style: TextStyle(
                                        fontSize: 13,
                                        color: colorScheme.onSurfaceVariant,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                              const SizedBox(height: 28),
                              Row(
                                children: [
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          '${_controller.totalGestores}',
                                          style: const TextStyle(
                                            fontSize: 34,
                                            fontWeight: FontWeight.w900,
                                            color: Color(0xFF4CAF50),
                                            height: 1.0,
                                          ),
                                        ),
                                        const SizedBox(height: 6),
                                        Text(
                                          'GESTORES',
                                          style: TextStyle(
                                            fontSize: 11,
                                            fontWeight: FontWeight.w700,
                                            letterSpacing: 1.0,
                                            color: colorScheme.onSurfaceVariant,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          '${_controller.totalColaboradores}',
                                          style: const TextStyle(
                                            fontSize: 34,
                                            fontWeight: FontWeight.w900,
                                            color: Color(0xFF64A6BD),
                                            height: 1.0,
                                          ),
                                        ),
                                        const SizedBox(height: 6),
                                        Text(
                                          'COLABORADORES',
                                          style: TextStyle(
                                            fontSize: 11,
                                            fontWeight: FontWeight.w700,
                                            letterSpacing: 1.0,
                                            color: colorScheme.onSurfaceVariant,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );

    if (!widget.mostrarAppBar) {
      return conteudo;
    }

    return Scaffold(
      appBar: CustomAppBar(
        usuario: widget.usuario,
        onPerfilPressed: () {},
      ),
      body: conteudo,
    );
  }
}