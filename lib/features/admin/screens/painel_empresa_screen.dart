import 'package:flutter/material.dart';
import '../../usuarios/models/usuario_model.dart';
import '../../../core/widgets/custom_app_bar.dart';
import '../controllers/empresa_controller.dart';
import 'cadastro_empresa_screen.dart';

class PainelEmpresaScreen extends StatefulWidget {
  final UsuarioModel usuario;

  const PainelEmpresaScreen({super.key, required this.usuario});

  @override
  State<PainelEmpresaScreen> createState() => _PainelEmpresaScreenState();
}

class _PainelEmpresaScreenState extends State<PainelEmpresaScreen> {
  // Instanciamos o controller da empresa aqui no painel
  late final EmpresaController _controller;

  @override
  void initState() {
  super.initState();

  _controller = EmpresaController(
    usuario: widget.usuario,
  );

  _carregarPainel();
  }

  // Busca no banco de dados a empresa atrelada a este administrador
  Future<void> _carregarPainel() async {
    await _controller.carregarDadosDoPainel();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      appBar: CustomAppBar(
        nomeUsuario: widget.usuario.nome,
        onPerfilPressed: () {
          // Futuramente abrirá a edição de perfil
        },
      ),
      // ListenableBuilder fica "escutando" o controller e reconstrói a tela 
      // quando o isLoading muda ou quando a empresaAtual é encontrada
      body: ListenableBuilder(
        listenable: _controller,
        builder: (context, _) {
          
          if (_controller.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          final empresa = _controller.empresaAtual;
          final temEmpresa = empresa != null;

          return SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // --- Card Principal da Empresa ---
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(24.0),
                  decoration: BoxDecoration(
                    color: theme.cardColor,
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(isDark ? 0.2 : 0.05),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
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
                          color: isDark ? Colors.blueGrey[300] : Colors.grey[600],
                        ),
                      ),
                      const SizedBox(height: 12),
                      
                      // Mostra o nome real ou um aviso para cadastrar
                      Text(
                        temEmpresa ? (empresa.nome ?? 'Sem nome') : 'Nenhuma empresa vinculada',
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      
                      // Mostra o CNPJ real
                      Text(
                        temEmpresa ? 'CNPJ: ${empresa.cnpj}' : 'Cadastre sua empresa no botão abaixo',
                        style: TextStyle(color: isDark ? Colors.grey[400] : Colors.grey[600]),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 32),
                const Text(
                  'Acesso Rápido',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 16),

                // --- Grid de Funcionalidades ---
                GridView.count(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  crossAxisCount: 2,
                  crossAxisSpacing: 16,
                  mainAxisSpacing: 16,
                  children: [
                    _buildActionCard(
                      context: context,
                      // Se já tem empresa, o botão vira "Editar Empresa"
                      title: temEmpresa ? 'Dados da\nEmpresa' : 'Cadastrar\nEmpresa',
                      icon: Icons.business_outlined,
                      onTap: () async {
                        // Navega para a tela passando a empresa atual. Se for null, vira cadastro.
                        await Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => CadastroEmpresaScreen(empresa: empresa, usuario: widget.usuario),
                          ),
                        );
                        // Quando voltar da tela de cadastro/edição, recarrega o painel automaticamente!
                        _carregarPainel();
                      },
                    ),
                    _buildActionCard(
                      context: context,
                      title: 'Gerenciar\nSetores',
                      icon: Icons.account_tree_outlined,
                      onTap: () {
                        if (!temEmpresa) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Por favor, cadastre a empresa primeiro.'), backgroundColor: Colors.orange),
                          );
                          return;
                        }
                        // TODO: Navegar para Lista/Cadastro de Setores
                      },
                    ),
                    _buildActionCard(
                      context: context,
                      title: 'Gestão da\nEquipe',
                      icon: Icons.people_outline,
                      onTap: () {
                        if (!temEmpresa) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Por favor, cadastre a empresa primeiro.'), backgroundColor: Colors.orange),
                          );
                          return;
                        }
                        // TODO: Navegar para CadastroUsuarioScreen
                      },
                    ),
                  ],
                ),
              ],
            ),
          );
        }
      ),
    );
  }

  // --- Widget de Botão/Card Reutilizável ---
  Widget _buildActionCard({
    required BuildContext context,
    required String title,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Material(
      color: theme.cardColor,
      borderRadius: BorderRadius.circular(20),
      elevation: isDark ? 2 : 0,
      shadowColor: Colors.black.withOpacity(0.2),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: isDark ? Colors.white10 : Colors.black.withOpacity(0.05),
            ),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: theme.primaryColor.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, size: 32, color: theme.primaryColor),
              ),
              const SizedBox(height: 16),
              Text(
                title,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}