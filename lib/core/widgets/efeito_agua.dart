import 'dart:math' as math;
import 'package:flutter/material.dart';

/// Envolve qualquer widget com um efeito de água: ao tocar, nasce uma onda
/// líquida no ponto exato do toque, com anéis ondulados que se expandem e
/// somem. Substitui o InkWell.
class EfeitoAgua extends StatefulWidget {
  final Widget child;
  final VoidCallback? onTap;
  final Color cor;
  final BorderRadius borderRadius;
  final Duration duracao;

  const EfeitoAgua({
    super.key,
    required this.child,
    required this.cor,
    this.onTap,
    this.borderRadius = const BorderRadius.all(Radius.circular(16)),
    this.duracao = const Duration(milliseconds: 900),
  });

  @override
  State<EfeitoAgua> createState() => _EfeitoAguaState();
}

class _EfeitoAguaState extends State<EfeitoAgua>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  Offset _origem = Offset.zero;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: widget.duracao);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _iniciar(TapDownDetails d) {
    _origem = d.localPosition;
    _controller.forward(from: 0);
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTapDown: _iniciar,
      onTap: widget.onTap,
      child: ClipRRect(
        borderRadius: widget.borderRadius,
        child: Stack(
          fit: StackFit.passthrough,
          children: [
            widget.child,
            Positioned.fill(
              child: IgnorePointer(
                child: AnimatedBuilder(
                  animation: _controller,
                  builder: (context, _) => CustomPaint(
                    painter: _AguaPainter(
                      progresso: _controller.value,
                      origem: _origem,
                      cor: widget.cor,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AguaPainter extends CustomPainter {
  final double progresso;
  final Offset origem;
  final Color cor;

  _AguaPainter({
    required this.progresso,
    required this.origem,
    required this.cor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (progresso <= 0 || progresso >= 1) return;

    final cantos = [
      Offset.zero,
      Offset(size.width, 0),
      Offset(0, size.height),
      Offset(size.width, size.height),
    ];
    final maxR = cantos.map((o) => (o - origem).distance).reduce(math.max);

    final raio = maxR * Curves.easeOutCubic.transform(progresso);
    if (raio < 1) return;
    final fade = math.pow(1 - progresso, 1.3).toDouble();

    // Disco de água translúcido com borda mais densa
    final rect = Rect.fromCircle(center: origem, radius: raio);
    canvas.drawCircle(
      origem,
      raio,
      Paint()
        ..shader = RadialGradient(
          colors: [
            cor.withValues(alpha: 0.05 * fade),
            cor.withValues(alpha: 0.22 * fade),
            cor.withValues(alpha: 0.0),
          ],
          stops: const [0.0, 0.82, 1.0],
        ).createShader(rect),
    );

    // Anéis ondulados (a oscilação dá o aspecto líquido)
    for (var k = 0; k < 3; k++) {
      final rk = raio * (1 - k * 0.2);
      if (rk < 2) continue;

      final amp = 2.5 * (1 - progresso) * (1 + k * 0.3);
      final path = Path();
      const passos = 72;
      for (var i = 0; i <= passos; i++) {
        final ang = i / passos * 2 * math.pi;
        final rr = rk + math.sin(ang * 7 + progresso * 14 + k) * amp;
        final p = origem + Offset(math.cos(ang) * rr, math.sin(ang) * rr);
        if (i == 0) {
          path.moveTo(p.dx, p.dy);
        } else {
          path.lineTo(p.dx, p.dy);
        }
      }
      path.close();

      canvas.drawPath(
        path,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2.2 - k * 0.6
          ..color = cor.withValues(alpha: (0.55 - k * 0.15) * fade),
      );
    }
  }

  @override
  bool shouldRepaint(covariant _AguaPainter old) =>
      old.progresso != progresso || old.origem != origem || old.cor != cor;
}
