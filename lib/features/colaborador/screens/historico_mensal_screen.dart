import 'package:flutter/material.dart';
import '../../../core/widgets/custom_app_bar.dart';
import '../../usuarios/models/usuario_model.dart';
import '../../ocorrencias/models/ocorrencia_model.dart';
import '../../ocorrencias/repositories/ocorrencia_repository.dart';
import '../../ocorrencias/screens/ocorrencias_dia_screen.dart';
import '../models/registro_ponto_model.dart';
import '../repositories/frequencia_repository.dart';

enum StatusDiaCalendario { neutro, verde, laranja, vermelho }

class HistoricoMensalScreen extends StatefulWidget {
  final UsuarioModel usuario;

  const HistoricoMensalScreen({
    Key? key,
    required this.usuario,
  }) : super(key: key);

  @override
  State<HistoricoMensalScreen> createState() => _HistoricoMensalScreenState();
}

class _HistoricoMensalScreenState extends State<HistoricoMensalScreen> {
  final _frequenciaRepo = FrequenciaRepository();
  final _ocorrenciaRepo = OcorrenciaRepository();

  late DateTime _mesAtual;
  DateTime? _dataCadastroUsuario;
  int _cargaHorariaSemanal = 40;
  bool _carregando = true;

  Map<int, List<RegistroPontoModel>> _pontosPorDia = {};
  Map<int, List<OcorrenciaModel>> _ocorrenciasPorDia = {};

  static const List<String> _nomesMeses = [
    'Janeiro', 'Fevereiro', 'Março', 'Abril', 'Maio', 'Junho',
    'Julho', 'Agosto', 'Setembro', 'Outubro', 'Novembro', 'Dezembro'
  ];

  @override
  void initState() {
    super.initState();
    final agora = DateTime.now();
    _mesAtual = DateTime(agora.year, agora.month, 1);
    _carregarDadosMes();
  }

  Future<void> _carregarDadosMes() async {
    setState(() => _carregando = true);
    try {
      _dataCadastroUsuario ??=
          await _frequenciaRepo.obterDataCadastroUsuario(widget.usuario.id);
      _cargaHorariaSemanal =
          await _frequenciaRepo.obterCargaHorariaSemanal(widget.usuario.id);

      final pontos = await _frequenciaRepo.listarPontosPorMes(
        usuarioId: widget.usuario.id,
        ano: _mesAtual.year,
        mes: _mesAtual.month,
      );

      final ocorrencias = await _ocorrenciaRepo.listarPorMes(
        usuarioId: widget.usuario.id,
        ano: _mesAtual.year,
        mes: _mesAtual.month,
      );

      final mapPontos = <int, List<RegistroPontoModel>>{};
      for (final p in pontos) {
        final dia = p.criadoEm.day;
        mapPontos.putIfAbsent(dia, () => []).add(p);
      }

      final mapOcorrencias = <int, List<OcorrenciaModel>>{};
      for (final oc in ocorrencias) {
        final dia = oc.dataInicio.day;
        mapOcorrencias.putIfAbsent(dia, () => []).add(oc);
      }

      if (mounted) {
        setState(() {
          _pontosPorDia = mapPontos;
          _ocorrenciasPorDia = mapOcorrencias;
          _carregando = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _carregando = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro ao carregar histórico: $e')),
        );
      }
    }
  }

  void _mudarMes(int delta) {
    setState(() {
      _mesAtual = DateTime(_mesAtual.year, _mesAtual.month + delta, 1);
    });
    _carregarDadosMes();
  }

  Duration _calcularHorasDoDia(int dia) {
    final batidas = List<RegistroPontoModel>.from(_pontosPorDia[dia] ?? [])
      ..sort((a, b) => a.criadoEm.compareTo(b.criadoEm));

    Duration total = Duration.zero;
    for (int i = 0; i + 1 < batidas.length; i += 2) {
      final diff = batidas[i + 1].criadoEm.difference(batidas[i].criadoEm);
      if (!diff.isNegative) {
        total += diff;
      }
    }

    final ocs = _ocorrenciasPorDia[dia] ?? [];
    for (final oc in ocs) {
      if (oc.aprovada && oc.minutosAbonados != null) {
        total += Duration(minutes: oc.minutosAbonados!);
      }
    }
    return total;
  }

  StatusDiaCalendario _avaliarStatusDia(int dia) {
    final dataDia = DateTime(_mesAtual.year, _mesAtual.month, dia);
    final hoje = DateTime.now();
    final hojeSemHora = DateTime(hoje.year, hoje.month, hoje.day);

    final cadastro = _dataCadastroUsuario ?? hojeSemHora;
    final cadastroSemHora = DateTime(cadastro.year, cadastro.month, cadastro.day);

    final batidas = _pontosPorDia[dia] ?? [];
    final ocorrencias = _ocorrenciasPorDia[dia] ?? [];
    final isFimDeSemana =
        dataDia.weekday == DateTime.saturday || dataDia.weekday == DateTime.sunday;

    if (dataDia.isAfter(hojeSemHora)) return StatusDiaCalendario.neutro;
    if (dataDia.isBefore(cadastroSemHora) && batidas.isEmpty) {
      return StatusDiaCalendario.neutro;
    }

    if (isFimDeSemana && batidas.isEmpty) {
      return StatusDiaCalendario.neutro;
    }

    if (batidas.isEmpty) {
      final temAbonoAprovado = ocorrencias.any((o) => o.aprovada);
      if (temAbonoAprovado) return StatusDiaCalendario.verde;

      if (dataDia.isAtSameMomentAs(hojeSemHora)) {
        return StatusDiaCalendario.neutro;
      }
      return StatusDiaCalendario.vermelho;
    }

    if (batidas.length.isOdd) {
      return StatusDiaCalendario.laranja;
    }

    final metaMinutosDia = (_cargaHorariaSemanal / 5.0 * 60.0).round();
    final trabalhadoMinutos = _calcularHorasDoDia(dia).inMinutes;

    if (trabalhadoMinutos >= (metaMinutosDia - 15)) {
      return StatusDiaCalendario.verde;
    } else {
      return StatusDiaCalendario.laranja;
    }
  }

  bool _exibirAlertaExclamacao(int dia) {
    final status = _avaliarStatusDia(dia);
    final ocorrencias = _ocorrenciasPorDia[dia] ?? [];
    final temOcorrenciaPendente = ocorrencias.any((o) => !o.aprovada);
    return status == StatusDiaCalendario.vermelho || temOcorrenciaPendente;
  }

  Future<void> _abrirDia(int dia) async {
    final dataSelecionada = DateTime(_mesAtual.year, _mesAtual.month, dia);
    final batidas = _pontosPorDia[dia] ?? [];
    final ocorrencias = _ocorrenciasPorDia[dia] ?? [];
    final totalDia = _calcularHorasDoDia(dia);

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
      _carregarDadosMes();
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;
    
    // Definição de cores dinâmicas para a tela inteira
    final bgColorScreen = isDarkMode ? const Color(0xFF0F172A) : const Color(0xFFF6F7F9);
    final cardColor = isDarkMode ? const Color(0xFF1E293B) : Colors.white;
    final textColorPrimary = isDarkMode ? Colors.white : const Color(0xFF1E293B);
    final textColorSecondary = isDarkMode ? const Color(0xFF94A3B8) : const Color(0xFF64748B);
    final shadowColor = isDarkMode ? Colors.black.withOpacity(0.3) : Colors.black.withOpacity(0.03);

    final totalDiasMes = DateTime(_mesAtual.year, _mesAtual.month + 1, 0).day;
    final primeiroDiaMes = DateTime(_mesAtual.year, _mesAtual.month, 1);
    final offsetSemana = primeiroDiaMes.weekday % 7;

    Duration totalTrabalhadoMes = Duration.zero;
    int diasUteisNoMes = 0;

    for (int d = 1; d <= totalDiasMes; d++) {
      totalTrabalhadoMes += _calcularHorasDoDia(d);
      final dt = DateTime(_mesAtual.year, _mesAtual.month, d);
      if (dt.weekday != DateTime.saturday && dt.weekday != DateTime.sunday) {
        diasUteisNoMes++;
      }
    }

    final horasDiarias = _cargaHorariaSemanal / 5.0;
    final metaMensalMinutos = (diasUteisNoMes * horasDiarias * 60).round();
    final faltamMinutos =
        (metaMensalMinutos - totalTrabalhadoMes.inMinutes).clamp(0, metaMensalMinutos);

    final progresso = metaMensalMinutos > 0
        ? (totalTrabalhadoMes.inMinutes / metaMensalMinutos).clamp(0.0, 1.0)
        : 0.0;

    final trabHoras = totalTrabalhadoMes.inHours;
    final trabMin = totalTrabalhadoMes.inMinutes % 60;
    final faltamHoras = faltamMinutos ~/ 60;
    final faltamMinRest = faltamMinutos % 60;

    final hoje = DateTime.now();

    return Scaffold(
      backgroundColor: bgColorScreen,
      appBar: CustomAppBar(
        nomeUsuario: widget.usuario.nome,
        onPerfilPressed: () {},
      ),
      body: _carregando
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Card Superior: Resumo do Mês
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: cardColor,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: shadowColor,
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
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
                                  '${_nomesMeses[_mesAtual.month - 1]} ${_mesAtual.year}',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: textColorPrimary,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  '${trabHoras}h ${trabMin.toString().padLeft(2, '0')}min trabalhadas',
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: textColorSecondary,
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
                                    color: Color(0xFFD97757),
                                    letterSpacing: 0.8,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  '${faltamHoras}h ${faltamMinRest.toString().padLeft(2, '0')}m',
                                  style: TextStyle(
                                    fontSize: 22,
                                    fontWeight: FontWeight.bold,
                                    color: textColorPrimary,
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
                            value: progresso,
                            minHeight: 8,
                            backgroundColor: isDarkMode ? const Color(0xFF334155) : const Color(0xFFF1F5F9),
                            valueColor: const AlwaysStoppedAnimation<Color>(
                              Color(0xFF74B49B),
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
                      color: cardColor,
                      borderRadius: BorderRadius.circular(24),
                      boxShadow: [
                        BoxShadow(
                          color: shadowColor,
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        // Navegação do Mês
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            IconButton(
                              onPressed: () => _mudarMes(-1),
                              icon: Icon(Icons.chevron_left, color: textColorSecondary),
                            ),
                            Text(
                              _nomesMeses[_mesAtual.month - 1],
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: textColorPrimary,
                              ),
                            ),
                            IconButton(
                              onPressed: () => _mudarMes(1),
                              icon: Icon(Icons.chevron_right, color: textColorSecondary),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),

                        // Cabeçalho dos dias da semana
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
                                          color: Color(0xFF94A3B8),
                                          fontSize: 13,
                                        ),
                                      ),
                                    ),
                                  ))
                              .toList(),
                        ),
                        const SizedBox(height: 16),

                        // Grade de dias
                        GridView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: offsetSemana + totalDiasMes,
                          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 7,
                            mainAxisSpacing: 10,
                            crossAxisSpacing: 8,
                            childAspectRatio: 0.9,
                          ),
                          itemBuilder: (context, index) {
                            if (index < offsetSemana) {
                              return const SizedBox.shrink();
                            }
                            final dia = index - offsetSemana + 1;
                            final isHoje = hoje.year == _mesAtual.year &&
                                hoje.month == _mesAtual.month &&
                                hoje.day == dia;

                            final status = _avaliarStatusDia(dia);
                            final mostrarAlerta = _exibirAlertaExclamacao(dia);

                            return _buildCelulaDia(
                              dia: dia,
                              status: status,
                              isHoje: isHoje,
                              mostrarAlerta: mostrarAlerta,
                              isDarkMode: isDarkMode,
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildCelulaDia({
    required int dia,
    required StatusDiaCalendario status,
    required bool isHoje,
    required bool mostrarAlerta,
    required bool isDarkMode,
  }) {
    Color bgColor;
    Color borderColor;
    Color textColor;

    switch (status) {
      case StatusDiaCalendario.verde:
        bgColor = isDarkMode ? const Color(0xFF14532D).withOpacity(0.7) : const Color(0xFFE8F5E9);
        borderColor = isDarkMode ? const Color(0xFF22C55E) : const Color(0xFF81C784);
        textColor = isDarkMode ? const Color(0xFF86EFAC) : const Color(0xFF2E7D32);
        break;
      case StatusDiaCalendario.laranja:
        bgColor = isDarkMode ? const Color(0xFF7C2D12).withOpacity(0.7) : const Color(0xFFFFF3E0);
        borderColor = isDarkMode ? const Color(0xFFF97316) : const Color(0xFFFFB74D);
        textColor = isDarkMode ? const Color(0xFFFDBA74) : const Color(0xFFE65100);
        break;
      case StatusDiaCalendario.vermelho:
        bgColor = isDarkMode ? const Color(0xFF7F1D1D).withOpacity(0.7) : const Color(0xFFFFEBEE);
        borderColor = isDarkMode ? const Color(0xFFEF4444) : const Color(0xFFE57373);
        textColor = isDarkMode ? const Color(0xFFFCA5A5) : const Color(0xFFC62828);
        break;
      case StatusDiaCalendario.neutro:
        bgColor = isDarkMode ? const Color(0xFF334155) : const Color(0xFFF1F5F9);
        borderColor = Colors.transparent;
        textColor = isDarkMode ? const Color(0xFFCBD5E1) : const Color(0xFF64748B);
        break;
    }

    if (isHoje) {
      borderColor = const Color(0xFF3B82F6); // Azul vibrante para destacar o dia atual
    }

    return InkWell(
      onTap: () => _abrirDia(dia),
      borderRadius: BorderRadius.circular(14),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Container(
            decoration: BoxDecoration(
              color: bgColor,
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
                  color: textColor,
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
                  color: isDarkMode ? const Color(0xFF1E293B) : Colors.white,
                  shape: BoxShape.circle,
                  border: Border.all(color: const Color(0xFFEF4444), width: 1.5),
                ),
                child: const Center(
                  child: Text(
                    '!',
                    style: TextStyle(
                      color: Color(0xFFEF4444),
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