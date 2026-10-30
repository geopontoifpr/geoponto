import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../constants/app_colors.dart';

/// Abertura do GeoPonto: globo wireframe com varredura de radar, órbitas com
/// satélites, pin que "pousa" emitindo pings de localização, título letra a
/// letra e barra de progresso estilo HUD.
///
/// A API é a mesma de antes: [onFinished] é chamado uma única vez ao final.
class AnimacaoAbertura extends StatefulWidget {
  final VoidCallback onFinished;
  final Duration duration;

  const AnimacaoAbertura({
    super.key,
    required this.onFinished,
    this.duration = const Duration(seconds: 5),
  });

  @override
  State<AnimacaoAbertura> createState() => _AnimacaoAberturaState();
}

class _AnimacaoAberturaState extends State<AnimacaoAbertura>
    with SingleTickerProviderStateMixin {
  static const _fundo = AppColors.primary;
  static const _fundoBrilho = AppColors.backgroundDark;
  static const _azul = AppColors.primary;
  static const _ciano = AppColors.neonCyan;

  late final AnimationController _controller;
  late final List<_Particula> _particulas;
  bool _finished = false;

  @override
  void initState() {
    super.initState();

    final rnd = math.Random(7);
    _particulas = List.generate(28, (_) {
      return _Particula(
        angulo: rnd.nextDouble() * 2 * math.pi,
        distancia: 1.25 + rnd.nextDouble() * 0.65,
        velocidade: (0.15 + rnd.nextDouble() * 0.5) * (rnd.nextBool() ? 1 : -1),
        tamanho: 1.0 + rnd.nextDouble() * 1.8,
        fase: rnd.nextDouble() * 2 * math.pi,
      );
    });

    _controller = AnimationController(vsync: this, duration: widget.duration)
      ..addStatusListener((status) {
        if (status == AnimationStatus.completed && !_finished) {
          _finished = true;
          widget.onFinished();
        }
      })
      ..forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _fundo,
      body: AnimatedBuilder(
        animation: _controller,
        builder: (context, _) {
          final t = _controller.value;
          final segundos = t * widget.duration.inMilliseconds / 1000.0;

          final saida = 1.0 - ((t - 0.94) / 0.06).clamp(0.0, 1.0);
          final revelar =
              Curves.easeOutCubic.transform((t / 0.35).clamp(0.0, 1.0));
          final pin = ((t - 0.30) / 0.25).clamp(0.0, 1.0);
          final giro = segundos * 0.7;
          final varredura = segundos * 2.2;

          final etapa = t < 0.33
              ? 'INICIANDO SENSORES'
              : t < 0.66
                  ? 'LOCALIZANDO DISPOSITIVO'
                  : 'SISTEMA PRONTO';

          return Opacity(
            opacity: saida,
            child: DecoratedBox(
              decoration: const BoxDecoration(
                gradient: RadialGradient(
                  center: Alignment(0, -0.25),
                  radius: 1.1,
                  colors: [_fundoBrilho, _fundo],
                ),
              ),
              child: SafeArea(
                child: Stack(
                  children: [
                    Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          SizedBox(
                            width: 340,
                            height: 340,
                            child: Stack(
                              alignment: Alignment.center,
                              children: [
                                CustomPaint(
                                  size: const Size(340, 340),
                                  painter: _GlobePainter(
                                    revelar: revelar,
                                    giro: giro,
                                    varredura: varredura,
                                    segundos: segundos,
                                    pin: pin,
                                    particulas: _particulas,
                                    azul: _azul,
                                    ciano: _ciano,
                                  ),
                                ),
                                Opacity(
                                  opacity: (pin * 4).clamp(0.0, 1.0),
                                  child: Transform.translate(
                                    offset: Offset(
                                      0,
                                      -22 -
                                          (1 - Curves.bounceOut.transform(pin)) *
                                              140,
                                    ),
                                    child: const Icon(
                                      Icons.location_on,
                                      size: 46,
                                      color: AppColors.white,
                                      shadows: [
                                        Shadow(color: _ciano, blurRadius: 18),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 4),
                          _titulo(t),
                          const SizedBox(height: 10),
                          _subtitulo(t),
                        ],
                      ),
                    ),
                    Positioned(
                      left: 40,
                      right: 40,
                      bottom: 36,
                      child: _progresso(t, etapa),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _titulo(double t) {
    const letras = ['G', 'e', 'o', 'P', 'o', 'n', 't', 'o'];
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (var i = 0; i < letras.length; i++)
          () {
            final inicio = 0.55 + i * 0.035;
            final p = Curves.easeOutCubic
                .transform(((t - inicio) / 0.14).clamp(0.0, 1.0));
            final destaque = i < 3;
            return Opacity(
              opacity: p,
              child: Transform.translate(
                offset: Offset(0, (1 - p) * 14),
                child: Text(
                  letras[i],
                  style: TextStyle(
                    fontSize: 38,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1,
                    color: destaque ? _ciano : AppColors.white,
                    shadows: destaque
                        ? [
                            Shadow(
                              color: _ciano.withValues(alpha: 0.6),
                              blurRadius: 16,
                            ),
                          ]
                        : null,
                  ),
                ),
              ),
            );
          }(),
      ],
    );
  }

  Widget _subtitulo(double t) {
    final p = ((t - 0.82) / 0.13).clamp(0.0, 1.0);
    return Opacity(
      opacity: p,
      child: Text(
        'CONTROLE DE JORNADA  •  PONTO ELETRÔNICO',
        style: TextStyle(
          fontSize: 10.5,
          letterSpacing: 2,
          fontWeight: FontWeight.w500,
          color: AppColors.white.withValues(alpha: 0.55),
        ),
      ),
    );
  }

  Widget _progresso(double t, String etapa) {
    final estilo = TextStyle(
      fontSize: 10.5,
      letterSpacing: 2,
      fontWeight: FontWeight.w600,
      color: AppColors.white.withValues(alpha: 0.5),
    );

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(etapa, style: estilo),
            Text('${(t * 100).round()}%', style: estilo),
          ],
        ),
        const SizedBox(height: 8),
        ClipRRect(
          borderRadius: BorderRadius.circular(2),
          child: SizedBox(
            height: 3,
            child: Stack(
              children: [
                Positioned.fill(
                  child: ColoredBox(color: AppColors.white.withValues(alpha: 0.08)),
                ),
                Align(
                  alignment: Alignment.centerLeft,
                  child: FractionallySizedBox(
                    widthFactor: t,
                    child: const DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(colors: [_azul, _ciano]),
                        boxShadow: [
                          BoxShadow(color: _ciano, blurRadius: 8),
                        ],
                      ),
                      child: SizedBox.expand(),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _Particula {
  final double angulo;
  final double distancia;
  final double velocidade;
  final double tamanho;
  final double fase;

  const _Particula({
    required this.angulo,
    required this.distancia,
    required this.velocidade,
    required this.tamanho,
    required this.fase,
  });
}

class _GlobePainter extends CustomPainter {
  final double revelar;
  final double giro;
  final double varredura;
  final double segundos;
  final double pin;
  final List<_Particula> particulas;
  final Color azul;
  final Color ciano;

  _GlobePainter({
    required this.revelar,
    required this.giro,
    required this.varredura,
    required this.segundos,
    required this.pin,
    required this.particulas,
    required this.azul,
    required this.ciano,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final c = size.center(Offset.zero);
    final r = size.width * 0.26;
    final a = revelar;

    // Halo de fundo
    final haloRect = Rect.fromCircle(center: c, radius: r * 1.9);
    canvas.drawCircle(
      c,
      r * 1.9,
      Paint()
        ..shader = RadialGradient(
          colors: [azul.withValues(alpha: 0.22 * a), Colors.transparent],
        ).createShader(haloRect),
    );

    // Partículas flutuantes
    final pPaint = Paint();
    for (final p in particulas) {
      final ang = p.angulo + giro * p.velocidade;
      final pos = c +
          Offset(
            math.cos(ang) * r * p.distancia,
            math.sin(ang) * r * p.distancia * 0.8,
          );
      final brilho = 0.35 + 0.35 * math.sin(segundos * 2 + p.fase);
      pPaint.color = ciano.withValues(alpha: (brilho * a).clamp(0.0, 1.0));
      canvas.drawCircle(pos, p.tamanho, pPaint);
    }

    // Corpo do globo
    final globo = Rect.fromCircle(center: c, radius: r);
    canvas.drawCircle(
      c,
      r,
      Paint()
        ..shader = RadialGradient(
          center: const Alignment(-0.35, -0.4),
          colors: [
            azul.withValues(alpha: 0.45 * a),
            AppColors.backgroundDeep.withValues(alpha: 0.9 * a),
          ],
        ).createShader(globo),
    );

    // Meridianos e paralelos
    final fio = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.8
      ..color = ciano.withValues(alpha: 0.35 * a);

    for (var i = 0; i < 6; i++) {
      final ang = giro + i * math.pi / 6;
      final w = r * math.cos(ang).abs();
      canvas.drawOval(
        Rect.fromCenter(center: c, width: w * 2, height: r * 2),
        fio,
      );
    }
    for (final lat in const [-0.66, -0.33, 0.0, 0.33, 0.66]) {
      final y = r * lat;
      final hw = math.sqrt(r * r - y * y);
      canvas.drawOval(
        Rect.fromCenter(center: c + Offset(0, y), width: hw * 2, height: hw * 0.3),
        fio,
      );
    }

    // Varredura de radar (recortada no globo)
    canvas.save();
    canvas.clipPath(Path()..addOval(globo));
    canvas.drawRect(
      globo,
      Paint()
        ..shader = SweepGradient(
          colors: [
            ciano.withValues(alpha: 0.0),
            ciano.withValues(alpha: 0.0),
            ciano.withValues(alpha: 0.5 * a),
          ],
          stops: const [0.0, 0.78, 1.0],
          transform: GradientRotation(varredura),
        ).createShader(globo),
    );
    canvas.restore();

    // Contorno
    canvas.drawCircle(
      c,
      r,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.6
        ..color = ciano.withValues(alpha: 0.9 * a),
    );

    // Marcas de HUD girando devagar
    final marca = Paint()
      ..strokeWidth = 1.0
      ..color = ciano.withValues(alpha: 0.35 * a);
    for (var i = 0; i < 60; i++) {
      final ang = i * 2 * math.pi / 60 - giro * 0.3;
      final tam = i % 5 == 0 ? 8.0 : 4.0;
      final dir = Offset(math.cos(ang), math.sin(ang));
      canvas.drawLine(c + dir * (r * 1.12), c + dir * (r * 1.12 + tam), marca);
    }

    // Órbitas com satélites
    _orbita(canvas, c, r, -0.5, 1, a);
    _orbita(canvas, c, r, 0.9, -1, a);

    // Pings de localização depois que o pin pousa
    final anel = ((pin - 0.85) / 0.15).clamp(0.0, 1.0);
    if (anel > 0) {
      for (var k = 0; k < 3; k++) {
        final p = ((segundos / 1.8) + k / 3) % 1.0;
        final w = r * (0.2 + p * 1.5);
        canvas.drawOval(
          Rect.fromCenter(center: c, width: w * 2, height: w * 0.7),
          Paint()
            ..style = PaintingStyle.stroke
            ..strokeWidth = 1.4
            ..color = ciano.withValues(alpha: (1 - p) * 0.7 * anel),
        );
      }
    }
  }

  void _orbita(
    Canvas canvas,
    Offset c,
    double r,
    double inclinacao,
    double direcao,
    double a,
  ) {
    final rx = r * 1.6;
    final ry = r * 0.46;
    final rect = Rect.fromCenter(center: Offset.zero, width: rx * 2, height: ry * 2);

    canvas.save();
    canvas.translate(c.dx, c.dy);
    canvas.rotate(inclinacao);

    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.6
      ..strokeCap = StrokeCap.round
      ..shader = SweepGradient(
        colors: [
          ciano.withValues(alpha: 0.04),
          ciano,
          ciano.withValues(alpha: 0.04),
        ],
        transform: GradientRotation(giro * direcao),
      ).createShader(rect);
    canvas.drawArc(rect, 0, 2 * math.pi * a, false, paint);

    final ang = giro * 1.4 * direcao;
    final sat = Offset(rx * math.cos(ang), ry * math.sin(ang));
    canvas.drawCircle(
      sat,
      6,
      Paint()
        ..color = ciano.withValues(alpha: 0.6 * a)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6),
    );
    canvas.drawCircle(sat, 2.6, Paint()..color = AppColors.white.withValues(alpha: a));

    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _GlobePainter old) => true;
}