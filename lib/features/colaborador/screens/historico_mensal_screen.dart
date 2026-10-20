import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/themes/app_themes.dart';
import '../../../core/widgets/custom_app_bar.dart';
import '../../ocorrencias/screens/ocorrencias_dia_screen.dart';
import '../../usuarios/models/usuario_model.dart';
import '../controllers/frequencia_controller.dart';
import '../services/frequencia_service.dart';

class HistoricoMensalScreen extends StatefulWidget {
  final UsuarioModel usuario;

  const HistoricoMensalScreen({
    super.key,
    required this.usuario,
  });

  @override
  State<HistoricoMensalScreen> createState() => _HistoricoMensalScreenState();
}

class _HistoricoMensalScreenState extends State<HistoricoMensalScreen> {
  late final FrequenciaController _controller;

  @override
  void initState() {
    super.initState();
    _controller = FrequenciaController(usuarioId: widget.usuario.id);
    _controller.carregarDadosMes();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _abrirDia(int dia) async {
    final dataSelecionada = DateTime(
      _controller.mesAtual.year,
      _controller.mesAtual.month,
      dia,
    );
    final batidas = _controller.pontosPorDia[dia] ?? [];
    final ocorrencias = _controller.ocorrenciasPorDia[dia] ?? [];
    final totalDia = _controller.calcularHorasDoDia(dia);

    final atualizou = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => OcorrenciasDiaScreen(
          usuario: widget.usuario,
          dataSelecionada: dataSelecionada,
          batidasDoDia: batidas,
          ocorrenciasDoDia: ocorrencias,
          totalTrabalhado: totalDia,
        ),
      ),
    );

    if (atualizou == true) {
      _controller.carregarDadosMes();
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final hoje = DateTime.now();

    return Scaffold(
      appBar: CustomAppBar(
        nomeUsuario: widget.usuario.nome,
        onPerfilPressed: () {},
      ),
      body: ListenableBuilder(
        listenable: _controller,
        builder: (context, _) {
          if (_controller.carregando) {
            return const Center(child: CircularProgressIndicator());
          }

          final resumo = _controller.calcularResumoMensal();

          return SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Card Superior: Resumo do Mês
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: theme.cardColor,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [AppThemes.cardShadow(context)],
                  ),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '${_controller.nomeMesAtual} ${_controller.mesAtual.year}',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: colorScheme.onSurface,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                '${resumo.trabHoras}h ${resumo.trabMin.toString().padLeft(2, '0')}min trabalhadas',
                                style: TextStyle(
                                  fontSize: 13,
                                  color: colorScheme.onSurfaceVariant,
                                ),
                              ),
                            ],
                          ),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              const Text(
                                'FALTAM',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.accentOrange,
                                  letterSpacing: 0.8,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                '${resumo.faltamHoras}h ${resumo.faltamMinRest.toString().padLeft(2, '0')}m',
                                style: TextStyle(
                                  fontSize: 22,
                                  fontWeight: FontWeight.bold,
                                  color: colorScheme.onSurface,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: LinearProgressIndicator(
                          value: resumo.progresso,
                          minHeight: 8,
                          backgroundColor: colorScheme.surfaceContainerHighest,
                          valueColor: const AlwaysStoppedAnimation<Color>(
                            AppColors.progressGreen,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 20),

                // Card Principal do Calendário
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
                  decoration: BoxDecoration(
                    color: theme.cardColor,
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: [AppThemes.cardShadow(context)],
                  ),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          IconButton(
                            onPressed: () => _controller.mudarMes(-1),
                            icon: Icon(
                              Icons.chevron_left,
                              color: colorScheme.onSurfaceVariant,
                            ),
                          ),
                          Text(
                            _controller.nomeMesAtual,
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: colorScheme.onSurface,
                            ),
                          ),
                          IconButton(
                            onPressed: () => _controller.mudarMes(1),
                            icon: Icon(
                              Icons.chevron_right,
                              color: colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: const ['D', 'S', 'T', 'Q', 'Q', 'S', 'S']
                            .map((d) => SizedBox(
                                  width: 40,
                                  child: Center(
                                    child: Text(
                                      d,
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        color: colorScheme.onSurfaceVariant,
                                        fontSize: 13,
                                      ),
                                    ),
                                  ),
                                ))
                            .toList(),
                      ),
                      const SizedBox(height: 16),
                      GridView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: _controller.offsetSemana + _controller.totalDiasMes,
                        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 7,
                          mainAxisSpacing: 10,
                          crossAxisSpacing: 8,
                          childAspectRatio: 0.9,
                        ),
                        itemBuilder: (context, index) {
                          if (index < _controller.offsetSemana) {
                            return const SizedBox.shrink();
                          }
                          final dia = index - _controller.offsetSemana + 1;
                          final isHoje = hoje.year == _controller.mesAtual.year &&
                              hoje.month == _controller.mesAtual.month &&
                              hoje.day == dia;

                          final status = _controller.avaliarStatusDia(dia);
                          final mostrarAlerta = _controller.exibirAlertaExclamacao(dia);

                          return _buildCelulaDia(
                            context: context,
                            dia: dia,
                            status: status,
                            isHoje: isHoje,
                            mostrarAlerta: mostrarAlerta,
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildCelulaDia({
    required BuildContext context,
    required int dia,
    required StatusDiaCalendario status,
    required bool isHoje,
    required bool mostrarAlerta,
  }) {
    final theme = Theme.of(context);
    final cores = AppThemes.coresStatusCalendario(
      context,
      status: status.name,
    );

    final borderColor = isHoje ? AppColors.info : cores.border;

    return InkWell(
      onTap: () => _abrirDia(dia),
      borderRadius: BorderRadius.circular(14),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Container(
            decoration: BoxDecoration(
              color: cores.bg,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: borderColor,
                width: isHoje ? 2.0 : 1.2,
              ),
            ),
            child: Center(
              child: Text(
                '$dia',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: status != StatusDiaCalendario.neutro || isHoje
                      ? FontWeight.bold
                      : FontWeight.w500,
                  color: cores.text,
                ),
              ),
            ),
          ),
          if (mostrarAlerta)
            Positioned(
              top: -4,
              right: -4,
              child: Container(
                width: 18,
                height: 18,
                decoration: BoxDecoration(
                  color: theme.cardColor,
                  shape: BoxShape.circle,
                  border: Border.all(color: AppColors.error, width: 1.5),
                ),
                child: const Center(
                  child: Text(
                    '!',
                    style: TextStyle(
                      color: AppColors.error,
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      height: 1.0,
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}