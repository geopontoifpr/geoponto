import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/themes/app_themes.dart';
import '../../../core/widgets/custom_app_bar.dart';
import '../../colaborador/controllers/frequencia_controller.dart';
import '../../usuarios/models/usuario_model.dart';
import '../../colaborador/screens/relatorio_extrato_screen.dart';


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

  String _formatarMinutos(int totalMinutos, {bool mostrarSinal = false}) {
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
          'Tem certeza que deseja fechar a folha de ${_controller.nomeMesAtual} ${_controller.mesAtual.year} para ${widget.colaborador.nome}? Após o fechamento, os dados não poderão mais ser alterados.',
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
      final sucesso = await _controller.fecharFolhaMes();
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            sucesso
                ? 'Folha de ${_controller.nomeMesAtual} fechada com sucesso!'
                : (_controller.erroMensagem ?? 'Erro ao salvar fechamento.'),
          ),
          backgroundColor: sucesso ? AppColors.success : AppColors.error,
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

          // Requisito 16: Tratamento visual em caso de falha no carregamento
          if (_controller.erroMensagem != null && _controller.pontosPorDia.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.error_outline, size: 48, color: AppColors.error),
                    const SizedBox(height: 12),
                    Text(
                      _controller.erroMensagem!,
                      textAlign: TextAlign.center,
                      style: TextStyle(color: colorScheme.onSurface),
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton.icon(
                      onPressed: _controller.carregarDadosMes,
                      icon: const Icon(Icons.refresh),
                      label: const Text('Tentar novamente'),
                    ),
                  ],
                ),
              ),
            );
          }

          final extrato = _controller.calcularExtratoDetalhado();
          final saldoPositivo = extrato.saldoMinutos >= 0;

          return SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
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

                // Card 1: Resumo Mensal Completo
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
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
                              widget.colaborador.nome,
                              style: TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.w800,
                                color: colorScheme.onSurface,
                              ),
                            ),
                          ),
                          if (_controller.folhaFechada)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: AppColors.progressGreen.withOpacity(0.15),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Text(
                                'FOLHA FECHADA',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.progressGreen,
                                ),
                              ),
                            ),
                        ],
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

                      // Linha 1 de indicadores: Previsto x Trabalhado x Abonado
                      Row(
                        children: [
                          Expanded(
                            child: _buildMiniResumo(
                              context,
                              titulo: 'Previsto',
                              valor: _formatarMinutos(extrato.minutosPrevistos),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: _buildMiniResumo(
                              context,
                              titulo: 'Trabalhado',
                              valor: _formatarMinutos(extrato.minutosTrabalhados),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: _buildMiniResumo(
                              context,
                              titulo: 'Abonado',
                              valor: _formatarMinutos(extrato.minutosAbonados),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),

                      // Linha 2 de indicadores: Dias Trab. x Créditos x Débitos (Requisito 4)
                      Row(
                        children: [
                          Expanded(
                            child: _buildMiniResumo(
                              context,
                              titulo: 'Dias trab.',
                              valor: '${extrato.diasTrabalhados}d',
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: _buildMiniResumo(
                              context,
                              titulo: 'Créditos',
                              valor: _formatarMinutos(
                                extrato.minutosCredito,
                                mostrarSinal: true,
                              ),
                              corValor: const Color(0xFF43A047),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: _buildMiniResumo(
                              context,
                              titulo: 'Débitos',
                              valor: _formatarMinutos(
                                -extrato.minutosDebito,
                                mostrarSinal: true,
                              ),
                              corValor: const Color(0xFFD32F2F),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),

                      // Card de Saldo Final
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
                              'Saldo do mês (Trab + Abono - Prev)',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: saldoPositivo
                                    ? const Color(0xFF4CAF50)
                                    : const Color(0xFFE53935),
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              _formatarMinutos(
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

                // Card 2: Extrato Diário Detalhado (Requisitos 1, 2 e 3)
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
                        'Extrato Diário do Mês',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: colorScheme.onSurface,
                        ),
                      ),
                      const SizedBox(height: 14),
                      ListView.separated(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: _controller.totalDiasMes,
                        separatorBuilder: (_, __) => const Divider(height: 20),
                        itemBuilder: (context, index) {
                          final dia = index + 1;
                          final info = _controller.obterDadosDia(dia);
                          final saldoDiaPositivo = info.saldoMinutos >= 0;

                          final textoBatidas = info.batidas.isEmpty
                              ? (info.isFimDeSemana ? 'Fim de semana' : 'Sem registros')
                              : info.batidas
                                  .map((p) {
                                    final dtLocal = p.dataHoraPonto.toLocal();
                                    final h = dtLocal.hour.toString().padLeft(2, '0');
                                    final m = dtLocal.minute.toString().padLeft(2, '0');
                                    return '$h:$m';
                                  })
                                  .join(' • ');

                          return Row(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              Container(
                                width: 36,
                                height: 36,
                                decoration: BoxDecoration(
                                  color: info.isFimDeSemana
                                      ? colorScheme.surfaceContainerHighest
                                      : colorScheme.primary.withOpacity(0.1),
                                  shape: BoxShape.circle,
                                ),
                                child: Center(
                                  child: Text(
                                    '$dia',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: info.isFimDeSemana
                                          ? colorScheme.onSurfaceVariant
                                          : colorScheme.primary,
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      textoBatidas,
                                      style: TextStyle(
                                        fontSize: 13,
                                        fontWeight: info.batidas.isEmpty
                                            ? FontWeight.normal
                                            : FontWeight.w600,
                                        color: info.batidas.isEmpty
                                            ? colorScheme.onSurfaceVariant
                                            : colorScheme.onSurface,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      'Trab: ${_formatarMinutos(info.minutosTrabalhados)}  •  '
                                      'Abono: ${_formatarMinutos(info.minutosAbonados)}  •  '
                                      'Prev: ${_formatarMinutos(info.minutosPrevistos)}',
                                      style: TextStyle(
                                        fontSize: 11,
                                        color: colorScheme.onSurfaceVariant,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 8),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  const Text(
                                    'Saldo',
                                    style: TextStyle(fontSize: 10, color: Colors.grey),
                                  ),
                                  Text(
                                    _formatarMinutos(
                                      info.saldoMinutos,
                                      mostrarSinal: true,
                                    ),
                                    style: TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.bold,
                                      color: info.saldoMinutos == 0
                                          ? colorScheme.onSurfaceVariant
                                          : (saldoDiaPositivo
                                              ? const Color(0xFF43A047)
                                              : const Color(0xFFD32F2F)),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          );
                        },
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 20),

                // Botão de Gerar Extrato (Documento Oficial)
                SizedBox(
                  height: 54,
                  child: OutlinedButton.icon(
                    onPressed: () {
                      final extrato = _controller.calcularExtratoDetalhado();
                      final diasInfo = List.generate(_controller.totalDiasMes, (index) {
                        final dia = index + 1;
                        final info = _controller.obterDadosDia(dia);
                        return {
                          'dia': dia,
                          'isFimDeSemana': info.isFimDeSemana,
                          'batidas': info.batidas,
                          'minutosTrabalhados': info.minutosTrabalhados,
                          'minutosAbonados': info.minutosAbonados,
                          'saldoMinutos': info.saldoMinutos,
                        };
                      });

                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => RelatorioExtratoScreen(
                            colaborador: widget.colaborador,
                            nomeMes: _controller.nomeMesAtual,
                            ano: _controller.mesAtual.year,
                            horasPrevistas: _formatarMinutos(extrato.minutosPrevistos),
                            horasTrabalhadas: _formatarMinutos(extrato.minutosTrabalhados),
                            horasAbonadas: _formatarMinutos(extrato.minutosAbonados),
                            saldoFinal: _formatarMinutos(extrato.saldoMinutos, mostrarSinal: true),
                            saldoPositivo: extrato.saldoMinutos >= 0,
                            dias: diasInfo,
                          ),
                        ),
                      );
                    },
                    icon: const Icon(Icons.picture_as_pdf_outlined),
                    label: const Text(
                      'Visualizar Extrato Oficial',
                      style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                    ),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: colorScheme.primary,
                      side: BorderSide(color: colorScheme.primary, width: 1.5),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(18),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 12), // Espaço entre os botões

                // Botão de Fechamento de Mês (Requisitos 11 e 14)
                SizedBox(
                  height: 54,
                  child: ElevatedButton(
                    onPressed: _controller.podeFecharFolha
                        ? _confirmarFechamentoFolha
                        : null,
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
                          : (_controller.isMesAnteriorAoAtual
                              ? 'Fechar folha do mês'
                              : 'Fechamento liberado apenas após o fim do mês'),
                      style: const TextStyle(
                        fontSize: 15,
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

  Widget _buildMiniResumo(
    BuildContext context, {
    required String titulo,
    required String valor,
    Color? corValor,
  }) {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 10),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest.withOpacity(0.5),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            titulo,
            style: TextStyle(
              fontSize: 11,
              color: colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            valor,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w800,
              color: corValor ?? colorScheme.onSurface,
            ),
          ),
        ],
      ),
    );
  }
}