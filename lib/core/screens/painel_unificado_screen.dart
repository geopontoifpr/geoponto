import 'package:flutter/material.dart';
import '../../features/admin/screens/cadastro_setor_screen.dart';
import '../../features/admin/screens/painel_empresa_screen.dart';
import '../../features/colaborador/screens/bater_ponto_screen.dart';
import '../../features/colaborador/screens/historico_mensal_screen.dart';
import '../../features/ocorrencias/screens/minhas_ocorrencias_screen.dart';
import '../../features/usuarios/models/usuario_model.dart';
import '../widgets/custom_app_bar.dart';
import '../widgets/fundo_futurista.dart';
import '../widgets/barra_navegacao.dart';
import 'equipe_screen.dart';
import '../controllers/painel_unificado_controller.dart';

class _Aba {
  final String label;
  final IconData icon;
  final Widget page;
  final bool alerta;
  const _Aba(this.label, this.icon, this.page, {this.alerta = false});
}

class PainelUnificadoScreen extends StatefulWidget {
  final UsuarioModel usuario;
  const PainelUnificadoScreen({super.key, required this.usuario});

  @override
  State<PainelUnificadoScreen> createState() => _PainelUnificadoScreenState();
}

class _PainelUnificadoScreenState extends State<PainelUnificadoScreen> {
  final _page = PageController();
  late final PainelUnificadoController _ctrl;
  int _aba = 0;
  UsuarioModel get _u => widget.usuario;

  @override
  void initState() {
    super.initState();
    _ctrl = PainelUnificadoController(usuario: _u)..inicializar();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    _page.dispose();
    super.dispose();
  }

  void _irParaAba(int i) {
    setState(() => _aba = i);
    _page.animateToPage(i, duration: const Duration(milliseconds: 280), curve: Curves.easeOutCubic);
  }

  List<_Aba> get _abasPessoais => [
    _Aba('PONTO', Icons.access_time, BaterPontoScreen(usuario: _u, mostrarAppBar: false)),
    _Aba('MEU HISTÓRICO', Icons.history, HistoricoMensalScreen(usuario: _u, mostrarAppBar: false)),
    _Aba('MINHAS OCORRÊNCIAS', Icons.report_problem_outlined, MinhasOcorrenciasScreen(usuario: _u, mostrarAppBar: false)),
  ];

  _Aba _abaEquipe(String label) {
    final empId = _ctrl.empresaId ?? '';
    return _Aba(
      label,
      Icons.people_outline,
      empId.isEmpty
          ? const Center(child: Text('Cadastre a empresa na aba Painel primeiro.'))
          : EquipeScreen(
              empresaId: empId,
              usuarioLogado: _u,
              mostrarAppBar: false,
              temPendencias: _ctrl.temPendencias,
              onAtualizarNotificacoes: _ctrl.atualizarPendencias,
            ),
      alerta: _ctrl.temPendencias,
    );
  }

  List<_Aba> _construirAbas() {
    switch (_u.tipoUsuario) {
      case TipoUsuario.funcionario:
        return _abasPessoais;
      case TipoUsuario.gestor:
        return [..._abasPessoais, _abaEquipe('EQUIPE')];
      case TipoUsuario.administrador:
        return [
          _Aba('PAINEL', Icons.dashboard_outlined, PainelEmpresaScreen(usuario: _u, mostrarAppBar: false, onIrParaSetores: () => _irParaAba(1), onIrParaEquipe: () => _irParaAba(2))),
          _Aba('SETORES', Icons.account_tree_outlined, _ctrl.empresaId?.isEmpty ?? true ? const Center(child: Text('Cadastre a empresa primeiro.')) : CadastroSetorScreen(empresaId: _ctrl.empresaId!, mostrarAppBar: false)),
          _abaEquipe('FUNCIONÁRIOS'),
        ];
    }
  }

  @override
  Widget build(BuildContext context) {
    final escuro = Theme.of(context).brightness == Brightness.dark;

    return ListenableBuilder(
      listenable: _ctrl,
      builder: (context, _) {
        final abas = _construirAbas();
        return Scaffold(
          appBar: CustomAppBar(
            key: ValueKey(_u.nome),
            usuario: _u,
            onPerfilPressed: () => setState(() {}),
          ),
          body: Stack(
            fit: StackFit.expand,
            children: [
              if (escuro) const FundoFuturista(child: SizedBox.shrink()),
              PageView(
                controller: _page,
                physics: const BouncingScrollPhysics(),
                onPageChanged: (i) => setState(() => _aba = i),
                children: abas.map((a) => a.page).toList(),
              ),
            ],
          ),
          bottomNavigationBar: BarraNavegacao(
            itens: [for (final a in abas) ItemNavegacao(a.label, a.icon, alerta: a.alerta)],
            atual: _aba,
            onTap: _irParaAba,
          ),
        );
      },
    );
  }
}