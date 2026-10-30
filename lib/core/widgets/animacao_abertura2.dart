import 'package:flutter/material.dart';


class AnimacaoAbertura extends StatefulWidget {
  final VoidCallback onFinished;
  final Duration duration;

  const AnimacaoAbertura({
    super.key,
    required this.onFinished,
    this.duration = const Duration(seconds: 6),
  });

  @override
  State<AnimacaoAbertura> createState() => _AnimacaoAberturaState();
}

class _AnimacaoAberturaState extends State<AnimacaoAbertura>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _globeScale;
  late final Animation<double> _globeOpacity;
  late final Animation<double> _nameOpacity;
  late final Animation<Offset> _nameSlide;

  bool _finished = false;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: widget.duration,
    );

    _globeScale = Tween<double>(
      begin: 0.55,
      end: 1.0,
    ).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 0.58, curve: Curves.easeOutBack),
      ),
    );

    _globeOpacity = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 0.28, curve: Curves.easeIn),
      ),
    );

    _nameOpacity = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.68, 0.95, curve: Curves.easeIn),
      ),
    );

    _nameSlide = Tween<Offset>(
      begin: const Offset(0, 0.35),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.68, 0.95, curve: Curves.easeOut),
      ),
    );

    _controller.addStatusListener((status) {
      if (status == AnimationStatus.completed && !_finished) {
        _finished = true;
        widget.onFinished();
      }
    });

    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final backgroundColor = theme.scaffoldBackgroundColor;
    final primaryColor = theme.colorScheme.primary;
    final secondaryColor = theme.colorScheme.secondary;

    return Scaffold(
      backgroundColor: backgroundColor,
      body: Center(
        child: AnimatedBuilder(
          animation: _controller,
          builder: (context, child) {
            return Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                FadeTransition(
                  opacity: _globeOpacity,
                  child: ScaleTransition(
                    scale: _globeScale,
                    child: SizedBox(
                      width: 168,
                      height: 168,
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          Container(
                            width: 148,
                            height: 148,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              gradient: LinearGradient(
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                                colors: [
                                  primaryColor.withValues(alpha: 0.12),
                                  primaryColor.withValues(alpha: 0.04),
                                ],
                              ),
                            ),
                          ),
                          Icon(
                            Icons.language_rounded,
                            size: 132,
                            color: primaryColor,
                          ),
                          Positioned(
                            top: 18,
                            right: 24,
                            child: Container(
                              width: 13,
                              height: 13,
                              decoration: BoxDecoration(
                                color: secondaryColor,
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: backgroundColor,
                                  width: 2,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                FadeTransition(
                  opacity: _nameOpacity,
                  child: SlideTransition(
                    position: _nameSlide,
                    child: Text.rich(
                      TextSpan(
                        children: [
                          TextSpan(
                            text: 'Geo',
                            style: TextStyle(
                              color: primaryColor,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          TextSpan(
                            text: 'Ponto',
                            style: TextStyle(
                              color: isDark
                                  ? theme.colorScheme.onSurface
                                  : const Color(0xFF263238),
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                      style: const TextStyle(
                        fontSize: 34,
                        letterSpacing: -0.8,
                      ),
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}
