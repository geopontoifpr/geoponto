import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/themes/app_themes.dart';
import '../../../core/widgets/custom_app_bar.dart';
import '../../colaborador/controllers/frequencia_controller.dart';
import '../../usuarios/models/usuario_model.dart';

class ExtratoMensalScreen extends StatefulWidget {
  final UsuarioModel colaborador;
  final UsuarioModel gestorLogado;

  const ExtratoMensalScreen({
    super.key,
    required this.colaborador,
    required this.gestorLogado,
  });

  @override
  State<ExtratoMensalScreen> createState() => _ExtratoMensalScreenState();
}

class _ExtratoMensalScreenState extends State<ExtratoMensalScreen> {
  late final FrequenciaController _controller;

  @override
  void initState() {
    super.initState();
    _controller = FrequenciaController(usuarioId: widget.colaborador.id);
    _controller.carregarDadosMes();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  String _formatarHorasMinutos(int totalMinutos, {bool mostrarSinal = false}) {
    final negativo = totalMinutos < 0;
    final absMin = totalMinutos.abs();
    final h = (absMin ~/ 60).toString().padLeft(2, '0');
    final m = (absMin % 60).toString().padLeft(2, '0');
    final sinal = mostrarSinal ? (negativo ? '-' : '+') : '';
    return '$sinal${h}h$m';
  }

  Future<void> _confirmarFechamentoFolha() async {
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Fechar folha do mês?'),
        content: Text(
          'Tem certeza que deseja fechar a folha de ${_controller.nomeMesAtual} ${_controller.mesAtual.year} para ${widget.colaborador.nome}?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.progressGreen,
              foregroundColor: Colors.white,
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Confirmar'),
          ),
        ],
      ),
    );

    if (confirmar == true && mounted) {
      _controller.fecharFolhaMes();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Folha de ${_controller.nomeMesAtual} fechada para ${widget.colaborador.nome}!',
          ),
          backgroundColor: AppColors.success,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      appBar: CustomAppBar(nomeUsuario: widget.gestorLogado.nome),
      body: ListenableBuilder(
        listenable: _controller,
        builder: (context, _) {
          if (_controller.carregando) {
            return const Center(child: CircularProgressIndicator());
          }

          final extrato = _controller.calcularExtratoDetalhado();
          final saldoPositivo = extrato.saldoMinutos >= 0;
          final trabMinTotal = extrato.totalTrabalhado.inMinutes;
          final trabFormatado =
              '${extrato.totalTrabalhado.inHours}h${(trabMinTotal % 60).toString().padLeft(2, '0')}';

          return SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Botão "← Voltar" (3ª imagem do protótipo)
                Align(
                  alignment: Alignment.centerLeft,
                  child: InkWell(
                    onTap: () => Navigator.pop(context),
                    borderRadius: BorderRadius.circular(8),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 4),
                      child: Text(
                        '← Voltar',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w500,
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 12),

                // Card 1: Dados do Colaborador e Saldo do Mês
                Container(
                  padding: const EdgeInsets.all(22),
                  decoration: BoxDecoration(
                    color: theme.cardColor,
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: [AppThemes.cardShadow(context)],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.colaborador.nome,
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w800,
                          color: colorScheme.onSurface,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            '${_controller.nomeMesAtual} ${_controller.mesAtual.year}',
                            style: TextStyle(
                              fontSize: 15,
                              color: colorScheme.onSurfaceVariant,
                            ),
                          ),
                          Row(
                            children: [
                              IconButton(
                                visualDensity: VisualDensity.compact,
                                onPressed: () => _controller.mudarMes(-1),
                                icon: const Icon(Icons.chevron_left, size: 20),
                              ),
                              IconButton(
                                visualDensity: VisualDensity.compact,
                                onPressed: () => _controller.mudarMes(1),
                                icon: const Icon(Icons.chevron_right, size: 20),
                              ),
                            ],
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),

                      // Caixas: Horas previstas | Horas trabalhadas
                      Row(
                        children: [
                          Expanded(
                            child: Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: colorScheme.surfaceContainerHighest.withOpacity(0.5),
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Horas previstas',
                                    style: TextStyle(
                                      fontSize: 13,
                                      color: colorScheme.onSurfaceVariant,
                                    ),
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    '${extrato.horasPrevistas}h',
                                    style: TextStyle(
                                      fontSize: 22,
                                      fontWeight: FontWeight.w800,
                                      color: colorScheme.onSurface,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: colorScheme.surfaceContainerHighest.withOpacity(0.5),
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Horas trabalhadas',
                                    style: TextStyle(
                                      fontSize: 13,
                                      color: colorScheme.onSurfaceVariant,
                                    ),
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    trabFormatado,
                                    style: TextStyle(
                                      fontSize: 22,
                                      fontWeight: FontWeight.w800,
                                      color: colorScheme.onSurface,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),

                      // Caixa Grande: Saldo do mês
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(18),
                        decoration: BoxDecoration(
                          color: saldoPositivo
                              ? const Color(0xFFE8F5E9)
                              : const Color(0xFFFFEBEE),
                          borderRadius: BorderRadius.circular(18),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Saldo do mês',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: saldoPositivo
                                    ? const Color(0xFF4CAF50)
                                    : const Color(0xFFE53935),
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              _formatarHorasMinutos(
                                extrato.saldoMinutos,
                                mostrarSinal: true,
                              ),
                              style: TextStyle(
                                fontSize: 32,
                                fontWeight: FontWeight.w900,
                                color: saldoPositivo
                                    ? const Color(0xFF43A047)
                                    : const Color(0xFFD32F2F),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 20),

                // Card 2: Resumo da jornada
                Container(
                  padding: const EdgeInsets.all(22),
                  decoration: BoxDecoration(
                    color: theme.cardColor,
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: [AppThemes.cardShadow(context)],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Resumo da jornada',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: colorScheme.onSurface,
                        ),
                      ),
                      const SizedBox(height: 18),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Dias trabalhados',
                            style: TextStyle(
                              fontSize: 15,
                              color: colorScheme.onSurfaceVariant,
                            ),
                          ),
                          Text(
                            '${extrato.diasTrabalhados}',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: colorScheme.onSurface,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Horas em crédito',
                            style: TextStyle(
                              fontSize: 15,
                              color: colorScheme.onSurfaceVariant,
                            ),
                          ),
                          Text(
                            '+${_formatarHorasMinutos(extrato.minutosCredito)}',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: AppColors.progressGreen,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Horas em débito',
                            style: TextStyle(
                              fontSize: 15,
                              color: colorScheme.onSurfaceVariant,
                            ),
                          ),
                          Text(
                            '-${_formatarHorasMinutos(extrato.minutosDebito)}',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: AppColors.accentOrange,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 20),

                // Botão: Fechar folha do mês (3ª imagem do protótipo)
                SizedBox(
                  height: 54,
                  child: ElevatedButton(
                    onPressed:
                        _controller.folhaFechada ? null : _confirmarFechamentoFolha,
                    style: ElevatedButton.styleFrom(
                      elevation: 0,
                      backgroundColor: const Color(0xFFA8D5BA),
                      foregroundColor: const Color(0xFF1E293B),
                      disabledBackgroundColor: colorScheme.surfaceContainerHighest,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(18),
                      ),
                    ),
                    child: Text(
                      _controller.folhaFechada
                          ? 'Folha do mês fechada ✓'
                          : 'Fechar folha do mês',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}