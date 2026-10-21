import 'dart:async';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/themes/app_themes.dart';
import '../../../core/widgets/custom_app_bar.dart';
import '../../usuarios/models/usuario_model.dart';
import '../controllers/ponto_controller.dart';
import '../models/registro_ponto_model.dart';

class BaterPontoScreen extends StatefulWidget {
  final UsuarioModel usuario;
  final bool mostrarAppBar;

  const BaterPontoScreen({
    super.key,
    required this.usuario,
    this.mostrarAppBar = true,
  });

  @override
  State<BaterPontoScreen> createState() => _BaterPontoScreenState();
}

class _BaterPontoScreenState extends State<BaterPontoScreen> {
  late final PontoController _controller;
  Timer? _relogioTimer;
  DateTime _agora = DateTime.now();

  @override
  void initState() {
    super.initState();
    _controller = PontoController(usuarioId: widget.usuario.id);
    _controller.inicializar(widget.usuario.nome);
    _relogioTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) {
        setState(() => _agora = DateTime.now());
      }
    });
  }

  @override
  void dispose() {
    _relogioTimer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  String _formatarDataCabecalho(DateTime dt) {
    const diasSemana = [
      'Segunda-feira',
      'Terça-feira',
      'Quarta-feira',
      'Quinta-feira',
      'Sexta-feira',
      'Sábado',
      'Domingo',
    ];
    const mesesAbrev = [
      'jan', 'fev', 'mar', 'abr', 'mai', 'jun',
      'jul', 'ago', 'set', 'out', 'nov', 'dez'
    ];
    return '${diasSemana[dt.weekday - 1]}, ${dt.day} de ${mesesAbrev[dt.month - 1]}';
  }

  Future<void> _baterPonto() async {
    final sucesso = await _controller.baterPonto();
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          sucesso
              ? 'Ponto registrado com sucesso!'
              : _controller.erro ??
                  _controller.avisoLocalizacao ??
                  'Não foi possível registrar o ponto.',
        ),
        backgroundColor: sucesso ? AppColors.success : AppColors.error,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Future<void> _abrirConfiguracoesLocalizacao() async {
    final aberto = await Geolocator.openLocationSettings();
    if (!aberto && mounted) {
      await Geolocator.openAppSettings();
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    final horaMinuto =
        '${_agora.hour.toString().padLeft(2, '0')}:${_agora.minute.toString().padLeft(2, '0')}';
    final segundos = '${_agora.second.toString().padLeft(2, '0')}s';

    final conteudo = AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        if (_controller.carregando) {
          return const Center(child: CircularProgressIndicator());
        }

        final statusDisponivel =
            _controller.precisaoValida && _controller.distanciaEmpresa != null;
        final habilitado = _controller.podeBaterPonto;

        return RefreshIndicator(
          onRefresh: () => _controller.inicializar(widget.usuario.nome),
          child: ListView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
            children: [
              const SizedBox(height: 8),
              // Relógio Digital (1ª imagem do protótipo)
              Center(
                child: Text(
                  horaMinuto,
                  style: TextStyle(
                    fontSize: 64,
                    fontWeight: FontWeight.w800,
                    color: colorScheme.onSurface,
                    height: 1.0,
                    letterSpacing: -1.5,
                  ),
                ),
              ),
              const SizedBox(height: 6),
              Center(
                child: Text(
                  segundos,
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w400,
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Center(
                child: Text(
                  _formatarDataCabecalho(_agora),
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
              const SizedBox(height: 8),

              // Linha de Localização com clique para atualizar GPS
              InkWell(
                onTap: _controller.atualizandoLocalizacao
                    ? null
                    : _controller.atualizarLocalizacao,
                borderRadius: BorderRadius.circular(12),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.location_on_outlined,
                        size: 18,
                        color: statusDisponivel && _controller.dentroDoRaio
                            ? AppColors.progressGreen
                            : AppColors.warning,
                      ),
                      const SizedBox(width: 4),
                      Flexible(
                        child: Text(
                          _controller.atualizandoLocalizacao
                              ? 'Atualizando localização...'
                              : statusDisponivel
                                  ? '${_controller.nomeEmpresa} — ${_controller.dentroDoRaio ? 'Dentro do raio' : 'Fora do raio'} (${_controller.distanciaEmpresa!.toStringAsFixed(0)}m)'
                                  : (_controller.avisoLocalizacao ??
                                      'Toque para atualizar localização'),
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 13,
                            color: colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              if ((_controller.avisoLocalizacao ?? '').contains('desativada'))
                Center(
                  child: TextButton.icon(
                    onPressed: _abrirConfiguracoesLocalizacao,
                    icon: const Icon(Icons.settings, size: 16),
                    label: const Text('Ativar localização'),
                  ),
                ),

              const SizedBox(height: 28),

              // Botão Circular Central "Bater Ponto" (1ª imagem do protótipo)
              Center(
                child: GestureDetector(
                  onTap: habilitado ? _baterPonto : null,
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    width: 210,
                    height: 210,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: habilitado
                          ? const Color(0xFFA8D5BA)
                          : colorScheme.surfaceContainerHighest,
                      boxShadow: [
                        if (habilitado)
                          BoxShadow(
                            color: const Color(0xFF74B49B).withOpacity(0.35),
                            blurRadius: 24,
                            offset: const Offset(0, 10),
                          ),
                      ],
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        if (_controller.registrando)
                          const CircularProgressIndicator(
                            color: Color(0xFF1E293B),
                          )
                        else ...[
                          Icon(
                            Icons.access_time,
                            size: 32,
                            color: habilitado
                                ? const Color(0xFF1E293B)
                                : colorScheme.onSurfaceVariant,
                          ),
                          const SizedBox(height: 10),
                          Text(
                            'Bater Ponto',
                            style: TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.w800,
                              color: habilitado
                                  ? const Color(0xFF1E293B)
                                  : colorScheme.onSurfaceVariant,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            child: Text(
                              habilitado
                                  ? 'Toque para registrar'
                                  : (_controller.registros.length >= 4
                                      ? 'Jornada concluída'
                                      : 'Aguardando raio/GPS'),
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w500,
                                color: habilitado
                                    ? const Color(0xFF334155)
                                    : colorScheme.onSurfaceVariant,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ),

              if (_controller.erro != null) ...[
                const SizedBox(height: 16),
                Text(
                  _controller.erro!,
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: AppColors.error, fontSize: 13),
                ),
              ],

              const SizedBox(height: 32),

              // Card Inferior "HOJE" (1ª imagem do protótipo)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: theme.cardColor,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [AppThemes.cardShadow(context)],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'HOJE',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.2,
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 16),
                    if (_controller.registros.isEmpty)
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 20),
                        child: Center(
                          child: Text(
                            'Nenhum registro\nrealizado hoje.',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 15,
                              color: colorScheme.onSurfaceVariant,
                              height: 1.4,
                            ),
                          ),
                        ),
                      )
                    else
                      ..._controller.registros.map((r) => _buildItemHoje(context, r)),
                  ],
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
      appBar: CustomAppBar(nomeUsuario: widget.usuario.nome),
      body: conteudo,
    );
  }

  Widget _buildItemHoje(BuildContext context, RegistroPontoModel registro) {
    final colorScheme = Theme.of(context).colorScheme;
    final horario = registro.criadoEm.toLocal();
    final hora =
        '${horario.hour.toString().padLeft(2, '0')}:${horario.minute.toString().padLeft(2, '0')}';
    final isEntrada = registro.tipoRegistro.name.contains('entrada');

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Icon(
                isEntrada ? Icons.login : Icons.logout,
                size: 18,
                color: isEntrada ? AppColors.success : AppColors.warning,
              ),
              const SizedBox(width: 10),
              Text(
                registro.tipoRegistro.titulo,
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: colorScheme.onSurface,
                ),
              ),
            ],
          ),
          Text(
            hora,
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.bold,
              color: colorScheme.onSurface,
            ),
          ),
        ],
      ),
    );
  }
}