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

  /// Soma os pares de batidas (Entrada -> Saída) de um dia específico
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

    // Soma minutos abonados de ocorrências aprovadas naquele dia, se houver
    final ocs = _ocorrenciasPorDia[dia] ?? [];
    for (final oc in ocs) {
      if (oc.aprovada && oc.minutosAbonados != null) {
        total += Duration(minutes: oc.minutosAbonados!);
      }
    }
    return total;
  }

  /// Determina a cor do dia seguindo a regra de cadastro e dias úteis
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

    // 1. Dias no futuro ou anteriores à criação da conta do usuário (sem batidas) ficam neutros
    if (dataDia.isAfter(hojeSemHora)) return StatusDiaCalendario.neutro;
    if (dataDia.isBefore(cadastroSemHora) && batidas.isEmpty) {
      return StatusDiaCalendario.neutro;
    }

    // 2. Fim de semana sem batidas fica neutro
    if (isFimDeSemana && batidas.isEmpty) {
      return StatusDiaCalendario.neutro;
    }

    // 3. Dia útil sem batidas (desde o cadastro até ontem, ou hoje com ocorrência) -> Vermelho
    if (batidas.isEmpty) {
      final temAbonoAprovado = ocorrencias.any((o) => o.aprovada);
      if (temAbonoAprovado) return StatusDiaCalendario.verde;

      // Se for hoje e ainda não bateu ponto, mantém neutro (com borda azul) até o dia acabar
      if (dataDia.isAtSameMomentAs(hojeSemHora)) {
        return StatusDiaCalendario.neutro;
      }
      return StatusDiaCalendario.vermelho;
    }

    // 4. Tem batidas, mas número ímpar (esqueceu de bater saída) -> Laranja
    if (batidas.length.isOdd) {
      return StatusDiaCalendario.laranja;
    }

    // 5. Batidas pares: verifica se cumpriu pelo menos ~90% da meta diária
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
    final totalDiasMes = DateTime(_mesAtual.year, _mesAtual.month + 1, 0).day;
    final primeiroDiaMes = DateTime(_mesAtual.year, _mesAtual.month, 1);
    // Ajuste para Domingo = 0, Segunda = 1, ..., Sábado = 6
    final offsetSemana = primeiroDiaMes.weekday % 7;

    // Cálculo de horas totais trabalhadas no mês e meta mensal
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
      backgroundColor: const Color(0xFFF6F7F9),
      appBar: CustomAppBar(
        nomeUsuario: 'Histórico Mensal',
        onPerfilPressed: () {},
      ),
      body: _carregando
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Card Superior: Resumo do Mês + Barra de Progresso
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.03),
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
                                  style: const TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFF1E293B),
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  '${trabHoras}h ${trabMin.toString().padLeft(2, '0')}min trabalhadas',
                                  style: const TextStyle(
                                    fontSize: 13,
                                    color: Color(0xFF94A3B8),
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
                                  style: const TextStyle(
                                    fontSize: 22,
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFF1E293B),
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
                            backgroundColor: const Color(0xFFF1F5F9),
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
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(24),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.03),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        // Navegação do Mês (< Agosto >)
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            IconButton(
                              onPressed: () => _mudarMes(-1),
                              icon: const Icon(Icons.chevron_left, color: Color(0xFF64748B)),
                            ),
                            Text(
                              _nomesMeses[_mesAtual.month - 1],
                              style: const TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF1E293B),
                              ),
                            ),
                            IconButton(
                              onPressed: () => _mudarMes(1),
                              icon: const Icon(Icons.chevron_right, color: Color(0xFF64748B)),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),

                        // Cabeçalho dos dias da semana (D S T Q Q S S)
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

                        // Grade de dias do mês
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
  }) {
    Color bgColor = const Color(0xFFF1F5F9);
    Color borderColor = Colors.transparent;
    Color textColor = const Color(0xFF64748B);

    switch (status) {
      case StatusDiaCalendario.verde:
        bgColor = const Color(0xFFE8F5E9);
        borderColor = const Color(0xFF81C784);
        textColor = const Color(0xFF2E7D32);
        break;
      case StatusDiaCalendario.laranja:
        bgColor = const Color(0xFFFFF3E0);
        borderColor = const Color(0xFFFFB74D);
        textColor = const Color(0xFFE65100);
        break;
      case StatusDiaCalendario.vermelho:
        bgColor = const Color(0xFFFFEBEE);
        borderColor = const Color(0xFFE57373);
        textColor = const Color(0xFFC62828);
        break;
      case StatusDiaCalendario.neutro:
        bgColor = const Color(0xFFF1F5F9);
        borderColor = Colors.transparent;
        textColor = const Color(0xFF64748B);
        break;
    }

    if (isHoje) {
      borderColor = const Color(0xFF60A5FA); // Destaque azul do dia atual como no Figma
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
                  color: Colors.white,
                  shape: BoxShape.circle,
                  border: Border.all(color: const Color(0xFFD32F2F), width: 1.5),
                ),
                child: const Center(
                  child: Text(
                    '!',
                    style: TextStyle(
                      color: Color(0xFFD32F2F),
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