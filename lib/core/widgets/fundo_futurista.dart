import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../constants/app_colors.dart';

/// Fundo escuro com grade em movimento lento, orbes de luz e uma linha de
/// varredura. Coloque o conteúdo da tela em [child].
class FundoFuturista extends StatefulWidget {
  final Widget child;

  const FundoFuturista({super.key, required this.child});

  @override
  State<FundoFuturista> createState() => _FundoFuturistaState();
}

class _FundoFuturistaState extends State<FundoFuturista>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 20),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        const ColoredBox(color: AppColors.backgroundDeep),
        RepaintBoundary(
          child: AnimatedBuilder(
            animation: _controller,
            builder: (context, _) => CustomPaint(
              painter: _FundoPainter(_controller.value),
            ),
          ),
        ),
        widget.child,
      ],
    );
  }
}

class _FundoPainter extends CustomPainter {
  final double t;

  _FundoPainter(this.t);

  void _orbe(Canvas canvas, Offset centro, double raio, Color cor, double alpha) {
    final rect = Rect.fromCircle(center: centro, radius: raio);
    canvas.drawCircle(
      centro,
      raio,
      Paint()
        ..shader = RadialGradient(
          colors: [cor.withValues(alpha: alpha), Colors.transparent],
        ).createShader(rect),
    );
  }

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final ciclo = t * 2 * math.pi;

    // Orbes de luz
    _orbe(
      canvas,
      Offset(w * (0.2 + 0.1 * math.sin(ciclo)), h * 0.18),
      w * 0.75,
      AppColors.primary,
      0.30,
    );
    _orbe(
      canvas,
      Offset(w * (0.85 - 0.1 * math.cos(ciclo)), h * 0.82),
      w * 0.7,
      AppColors.neonCyan,
      0.14,
    );

    // Grade (as linhas horizontais descem devagar)
    const passo = 36.0;
    final grade = Paint()
      ..strokeWidth = 0.6
      ..color = AppColors.neonCyan.withValues(alpha: 0.06);
    for (var x = 0.0; x < w; x += passo) {
      canvas.drawLine(Offset(x, 0), Offset(x, h), grade);
    }
    final deslocamento = (t * passo * 10) % passo;
    for (var y = -passo + deslocamento; y < h; y += passo) {
      canvas.drawLine(Offset(0, y), Offset(w, y), grade);
    }

    // Vinheta: a grade some nas bordas
    final tela = Offset.zero & size;
    canvas.drawRect(
      tela,
      Paint()
        ..shader = RadialGradient(
          radius: 0.95,
          colors: [
            Colors.transparent,
            AppColors.backgroundDeep.withValues(alpha: 0.92),
          ],
          stops: const [0.35, 1.0],
        ).createShader(tela),
    );

    // Linha de varredura
    final y = h * ((t * 2) % 1.0);
    final faixa = Rect.fromLTWH(0, y - 40, w, 80);
    canvas.drawRect(
      faixa,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Colors.transparent,
            AppColors.neonCyan.withValues(alpha: 0.07),
            Colors.transparent,
          ],
        ).createShader(faixa),
    );
  }

  @override
  bool shouldRepaint(covariant _FundoPainter old) => old.t != t;
}
