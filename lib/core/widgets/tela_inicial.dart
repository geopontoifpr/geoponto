import 'package:flutter/material.dart';
import '../../features/usuarios/models/usuario_model.dart';

class TelaInicialWidget extends StatelessWidget {
  final UsuarioModel usuario;

  const TelaInicialWidget({
    Key? key,
    required this.usuario,
  }) : super(key: key);

  void _navegarOuAvisar(BuildContext context, String funcionalidade) {
    // TODO: Substituir pelos Navigators reais quando as telas existirem
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('$funcionalidade em breve!'),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Define todos os cards possíveis no sistema
    final List<Map<String, dynamic>> todosCards = [
      {
        'title': 'Cadastro Empresa',
        'icon': Icons.business,
        'color': Colors.blueGrey,
        'onTap': () => _navegarOuAvisar(context, 'Cadastro de Empresa'),
        'allowedRoles': [TipoUsuario.administrador],
      },
      {
        'title': 'Cadastro Setor',
        'icon': Icons.account_tree,
        'color': Colors.deepPurple,
        'onTap': () => _navegarOuAvisar(context, 'Cadastro de Setores'),
        'allowedRoles': [TipoUsuario.administrador],
      },
      {
        'title': 'Gerenciar Equipe',
        'icon': Icons.people,
        'color': Colors.blue,
        // TODO: Mudar para a sua rota real de EquipeScreen
        'onTap': () => _navegarOuAvisar(context, 'Gerenciar Equipe'), 
        'allowedRoles': [TipoUsuario.administrador, TipoUsuario.gestor],
      },
      {
        'title': 'Bater Ponto',
        'icon': Icons.fingerprint,
        'color': Colors.teal,
        'onTap': () => _navegarOuAvisar(context, 'Bater Ponto'),
        'allowedRoles': [TipoUsuario.administrador, TipoUsuario.gestor, TipoUsuario.funcionario],
      },
      {
        'title': 'Ocorrências',
        'icon': Icons.assignment_late_outlined,
        'color': Colors.orange,
        'onTap': () => _navegarOuAvisar(context, 'Ocorrências'),
        'allowedRoles': [TipoUsuario.administrador, TipoUsuario.gestor, TipoUsuario.funcionario],
      },
      {
        'title': 'Extrato Mensal',
        'icon': Icons.request_quote,
        'color': Colors.indigo,
        'onTap': () => _navegarOuAvisar(context, 'Extrato e Folha'),
        'allowedRoles': [TipoUsuario.administrador, TipoUsuario.gestor, TipoUsuario.funcionario],
      },
    ];

    // Filtra os cards permitidos com base no cargo do utilizador logado
    final cardsPermitidos = todosCards.where((card) {
      final roles = card['allowedRoles'] as List<TipoUsuario>;
      return roles.contains(usuario.tipoUsuario);
    }).toList();

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(), // Evita conflito se estiver dentro de uma SingleChildScrollView
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
      ),
      itemCount: cardsPermitidos.length,
      itemBuilder: (context, index) {
        final card = cardsPermitidos[index];
        return _buildActionCard(
          title: card['title'],
          icon: card['icon'],
          color: card['color'],
          onTap: card['onTap'],
        );
      },
    );
  }

  Widget _buildActionCard({
    required String title,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, size: 40, color: color),
              ),
              const SizedBox(height: 16),
              Text(
                title,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}