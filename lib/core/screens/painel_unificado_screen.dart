import 'package:flutter/material.dart';
import '../controllers/painel_unificado_controller.dart';
import '../../features/admin/screens/cadastro_setor_screen.dart';
import '../../features/admin/screens/painel_empresa_screen.dart';
import '../../features/colaborador/screens/bater_ponto_screen.dart';
import '../../features/colaborador/screens/historico_mensal_screen.dart';
import '../../features/ocorrencias/screens/ocorrencias_gestor_screen.dart';
import '../../features/usuarios/models/usuario_model.dart';
import '../constants/app_colors.dart';
import '../widgets/custom_app_bar.dart';
import '../screens/equipe_screen.dart';


class _AbaItem {
  final String label;
  final IconData icon;
  final Widget page;
  final bool mostrarAlerta;

  const _AbaItem({
    required this.label,
    required this.icon,
    required this.page,
    this.mostrarAlerta = false,
  });
}

class PainelUnificadoScreen extends StatefulWidget {
  final UsuarioModel usuario;

  const PainelUnificadoScreen({
    super.key,
    required this.usuario,
  });

  @override
  State<PainelUnificadoScreen> createState() => _PainelUnificadoScreenState();
}

class _PainelUnificadoScreenState extends State<PainelUnificadoScreen> {
  final PageController _pageController = PageController();
  int _abaAtual = 0;

  late final PainelUnificadoController _controller;

  @override
  void initState() {
    super.initState();
    _controller = PainelUnificadoController(usuario: widget.usuario)
      ..addListener(_aoAtualizarPainel);
    _controller.inicializar();
  }

  void _aoAtualizarPainel() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _controller.removeListener(_aoAtualizarPainel);
    _controller.dispose();
    _pageController.dispose();
    super.dispose();
  }

  void _irParaAba(int index) {
    setState(() => _abaAtual = index);
    _pageController.animateToPage(
      index,
      duration: const Duration(milliseconds: 280),
      curve: Curves.easeOutCubic,
    );
  }

  List<_AbaItem> _construirAbasPorCargo() {
    switch (widget.usuario.tipoUsuario) {
      // 1. COLABORADOR: Abre direto em Bater Ponto + Histórico (sem aba redundante de ocorrências)
      case TipoUsuario.funcionario:
        return [
          _AbaItem(
            label: 'PONTO',
            icon: Icons.access_time,
            page: BaterPontoScreen(
              usuario: widget.usuario,
              mostrarAppBar: false,
            ),
          ),
          _AbaItem(
            label: 'MEU HISTÓRICO',
            icon: Icons.history,
            page: HistoricoMensalScreen(
              usuario: widget.usuario,
              mostrarAppBar: false,
            ),
          ),
        ];

      // 2. GESTOR: Ponto + Histórico + Minha Equipe (clicar abre Extrato/Fechar Mês) + Ocorrências (!)
      case TipoUsuario.gestor:
        final temPendentes = _controller.temOcorrenciasPendentes;
        return [
          _AbaItem(
            label: 'PONTO',
            icon: Icons.access_time,
            page: BaterPontoScreen(
              usuario: widget.usuario,
              mostrarAppBar: false,
            ),
          ),
          _AbaItem(
            label: 'MEU HISTÓRICO',
            icon: Icons.history,
            page: HistoricoMensalScreen(
              usuario: widget.usuario,
              mostrarAppBar: false,
            ),
          ),
          _AbaItem(
            label: 'GERENCIAR EQUIPE',
            icon: Icons.people_outline,
            page: EquipeScreen(
              empresaId: widget.usuario.empresaId ?? '',
              usuarioLogado: widget.usuario,
              mostrarAppBar: false,
            ),
          ),
          _AbaItem(
            label: 'OCORRÊNCIAS',
            icon: Icons.fact_check_outlined,
            page: OcorrenciasGestorScreen(usuarioLogado: widget.usuario),
            mostrarAlerta: temPendentes,
          ),
        ];

      // 3. ADMINISTRADOR (DONO): Painel (5ª imagem) + Setores + Equipe
      case TipoUsuario.administrador:
        final empId = _controller.empresaIdAdmin ?? widget.usuario.empresaId ?? ''; 
        return [
          _AbaItem(
            label: 'PAINEL',
            icon: Icons.dashboard_outlined,
            page: PainelEmpresaScreen(
              usuario: widget.usuario,
              mostrarAppBar: false,
              onIrParaSetores: () => _irParaAba(1),
              onIrParaEquipe: () => _irParaAba(2),
            ),
          ),
          _AbaItem(
            label: 'CADASTRO DE SETORES',
            icon: Icons.account_tree_outlined,
            page: empId.isEmpty
                ? const Center(
                    child: Text('Cadastre a empresa na aba Painel primeiro.'),
                  )
                : CadastroSetorScreen(
                    empresaId: empId,
                    mostrarAppBar: false,
                  ),
          ),
          _AbaItem(
            label: 'GERENCIAR FUNCIONÁRIOS',
            icon: Icons.people_outline,
            page: empId.isEmpty
                ? const Center(
                    child: Text('Cadastre a empresa na aba Painel primeiro.'),
                  )
                : EquipeScreen(
                    empresaId: empId,
                    usuarioLogado: widget.usuario,
                    mostrarAppBar: false,
                  ),
          ),
          _AbaItem(
            label: 'OCORRÊNCIAS',
            icon: Icons.fact_check_outlined,
            page: OcorrenciasGestorScreen(usuarioLogado: widget.usuario),
          ),
        ];
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final abas = _construirAbasPorCargo();

    return Scaffold(
      appBar: CustomAppBar(
        usuario: widget.usuario,
        onPerfilPressed: () {},
      ),
      body: PageView(
        controller: _pageController,
        physics: const BouncingScrollPhysics(),
        onPageChanged: (index) {
          setState(() => _abaAtual = index);
        },
        children: abas.map((a) => a.page).toList(),
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: theme.cardColor,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 12,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: List.generate(abas.length, (index) {
                final aba = abas[index];
                final ativo = _abaAtual == index;
                final corAtiva = AppColors.progressGreen;
                final corInativa = theme.colorScheme.onSurfaceVariant;

                return Expanded(
                  child: InkWell(
                    onTap: () => _irParaAba(index),
                    borderRadius: BorderRadius.circular(12),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Stack(
                            clipBehavior: Clip.none,
                            children: [
                              Icon(
                                aba.icon,
                                size: 24,
                                color: ativo ? corAtiva : corInativa,
                              ),
                              // Símbolo de alerta (!) no cantinho acima de Ocorrências
                              if (aba.mostrarAlerta)
                                Positioned(
                                  top: -5,
                                  right: -8,
                                  child: Container(
                                    width: 16,
                                    height: 16,
                                    decoration: BoxDecoration(
                                      color: AppColors.error,
                                      shape: BoxShape.circle,
                                      border: Border.all(
                                        color: theme.cardColor,
                                        width: 1.5,
                                      ),
                                    ),
                                    child: const Center(
                                      child: Text(
                                        '!',
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontSize: 10,
                                          fontWeight: FontWeight.w900,
                                          height: 1.0,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(
                            aba.label,
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight:
                                  ativo ? FontWeight.w800 : FontWeight.w600,
                              letterSpacing: 0.4,
                              color: ativo ? corAtiva : corInativa,
                            ),
                          ),
                          const SizedBox(height: 4),
                          AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            width: 5,
                            height: 5,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: ativo ? corAtiva : Colors.transparent,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              }),
            ),
          ),
        ),
      ),
    );
  }
}