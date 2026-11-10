import 'dart:math' as math;
import 'package:flutter/material.dart';

class AvatarComLuzCirculante extends StatefulWidget {
  final Widget avatar;
  final double tamanho;
  final Color corLuz;

  const AvatarComLuzCirculante({
    super.key,
    required this.avatar,
    this.tamanho = 46, // Raio de 20 = diâmetro de 40. +6 para a luz circular por fora
    required this.corLuz,
  });

  @override
  State<AvatarComLuzCirculante> createState() => _AvatarComLuzCirculanteState();
}

class _AvatarComLuzCirculanteState extends State<AvatarComLuzCirculante>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2500), // Velocidade do giro
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: widget.tamanho,
      height: widget.tamanho,
      child: Stack(
        alignment: Alignment.center,
        children: [
          AnimatedBuilder(
            animation: _controller,
            builder: (context, _) => CustomPaint(
              size: Size(widget.tamanho, widget.tamanho),
              painter: _LuzCirculantePainter(_controller.value, widget.corLuz),
            ),
          ),
          widget.avatar, // O seu CircleAvatar entra no centro
        ],
      ),
    );
  }
}

class _LuzCirculantePainter extends CustomPainter {
  final double progresso;
  final Color corLuz;

  _LuzCirculantePainter(this.progresso, this.corLuz);

  @override
  void paint(Canvas canvas, Size size) {
    final centro = Offset(size.width / 2, size.height / 2);
    final raio = size.width / 2;
    final rect = Rect.fromCircle(center: centro, radius: raio);

    // Gradiente que cria o efeito de "cometa" (rastro sumindo)
    final shaderLuz = SweepGradient(
      colors: [
        Colors.transparent,
        corLuz.withOpacity(0.1),
        corLuz.withOpacity(0.6),
        corLuz,
        Colors.transparent,
      ],
      stops: const [0.0, 0.4, 0.8, 0.95, 1.0],
      transform: GradientRotation(progresso * 2 * math.pi),
    ).createShader(rect);

    // Pintura da luz principal
    final paintLuz = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0
      ..strokeCap = StrokeCap.round
      ..shader = shaderLuz;

    // Pintura do brilho externo (neon shadow)
    final paintBrilho = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4.0
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3.0)
      ..shader = shaderLuz;

    canvas.drawCircle(centro, raio, paintBrilho);
    canvas.drawCircle(centro, raio, paintLuz);
  }

  @override
  bool shouldRepaint(covariant _LuzCirculantePainter old) => old.progresso != progresso;
}