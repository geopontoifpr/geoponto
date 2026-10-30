import 'dart:math' as math;
import 'dart:ui' show ImageFilter;
import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/screens/painel_unificado_screen.dart';
import '../../../core/themes/app_themes.dart';
import '../../../core/utils/snackbar_util.dart';
import '../../../core/widgets/custom_text_field.dart';
import '../../../core/widgets/efeito_agua.dart';
import '../../../core/widgets/fundo_futurista.dart';
import '../controllers/login_controller.dart';
import 'primeiro_acesso_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  late final LoginController _controller;
  final _emailController = TextEditingController();
  final _senhaController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _controller = LoginController();
    _controller.addListener(_aoAtualizarEstado);
  }

  void _aoAtualizarEstado() {
    if (mounted) setState(() {});
  }

  Future<void> _submeter() async {
    final email = _emailController.text.trim();
    final senha = _senhaController.text;

    if (email.isEmpty || senha.isEmpty) {
      SnackbarUtil.showError(context, 'Por favor, preencha o e-mail e a senha.');
      return;
    }

    final sucesso = await _controller.entrar(
      email: email,
      senha: senha,
    );

    if (sucesso && mounted) {
      final usuario = _controller.usuarioLogado!;

      final Widget destino = usuario.primeiroAcesso
          ? PrimeiroAcessoScreen(usuario: usuario)
          : PainelUnificadoScreen(usuario: usuario);

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => destino),
      );
    }
  }

  Future<void> _abrirModalRecuperacao() async {
    final emailRecuperacaoController = TextEditingController();

    await showDialog(
      context: context,
      // O dialog fica fora da árvore do Theme local, então reaplicamos o tema escuro
      builder: (ctx) => Theme(
        data: AppThemes.darkTheme,
        child: AlertDialog(
          title: const Text('Recuperar Senha'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Informe seu e-mail corporativo para receber o link de redefinição de senha.',
              ),
              const SizedBox(height: 16),
              TextField(
                controller: emailRecuperacaoController,
                decoration: InputDecoration(
                  labelText: 'E-mail',
                  prefixIcon: const Icon(Icons.email_outlined),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                keyboardType: TextInputType.emailAddress,
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancelar'),
            ),
            ElevatedButton(
              onPressed: () async {
                final email = emailRecuperacaoController.text.trim();
                if (email.isEmpty || !email.contains('@')) {
                  SnackbarUtil.showError(ctx, 'Informe um e-mail válido.');
                  return;
                }

                final sucesso = await _controller.recuperarSenha(email);

                if (!ctx.mounted) return;

                if (sucesso) {
                  Navigator.pop(ctx);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('E-mail de recuperação enviado com sucesso!'),
                      backgroundColor: Colors.green,
                    ),
                  );
                } else {
                  SnackbarUtil.showError(
                    ctx,
                    _controller.erro ?? 'Erro ao enviar e-mail',
                  );
                }
              },
              child: const Text('Enviar Link'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _controller.removeListener(_aoAtualizarEstado);
    _controller.dispose();
    _emailController.dispose();
    _senhaController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Tela sempre escura: o Theme local garante que CustomTextField e
    // demais widgets herdados usem a paleta escura, mesmo com o app no claro.
    return Theme(
      data: AppThemes.darkTheme,
      child: Scaffold(
        backgroundColor: AppColors.backgroundDeep,
        body: FundoFuturista(
          child: SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
                child: TweenAnimationBuilder<double>(
                  tween: Tween(begin: 0, end: 1),
                  duration: const Duration(milliseconds: 900),
                  curve: Curves.easeOutCubic,
                  builder: (context, v, child) => Opacity(
                    opacity: v,
                    child: Transform.translate(
                      offset: Offset(0, (1 - v) * 24),
                      child: child,
                    ),
                  ),
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 420),
                    child: _conteudo(),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _conteudo() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Center(child: _LogoOrbital()),
        const SizedBox(height: 20),
        Text.rich(
          TextSpan(
            children: [
              TextSpan(
                text: 'Geo',
                style: TextStyle(
                  color: AppColors.neonCyan,
                  shadows: [
                    Shadow(
                      color: AppColors.neonCyan.withValues(alpha: 0.6),
                      blurRadius: 16,
                    ),
                  ],
                ),
              ),
              const TextSpan(
                text: 'Ponto',
                style: TextStyle(color: AppColors.white),
              ),
            ],
          ),
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontSize: 34,
            fontWeight: FontWeight.w800,
            letterSpacing: 0.5,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'CONTROLE DE JORNADA  •  PONTO ELETRÔNICO',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 10.5,
            letterSpacing: 2,
            fontWeight: FontWeight.w500,
            color: AppColors.textSecondaryDark.withValues(alpha: 0.9),
          ),
        ),
        const SizedBox(height: 36),
        _painelVidro(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Container(
                    width: 8,
                    height: 8,
                    decoration: const BoxDecoration(
                      color: AppColors.success,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(color: AppColors.success, blurRadius: 8),
                      ],
                    ),
                  ),
                  const SizedBox(width: 10),
                  Text(
                    'CONEXÃO SEGURA',
                    style: TextStyle(
                      fontSize: 10.5,
                      letterSpacing: 2,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textSecondaryDark.withValues(alpha: 0.9),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              CustomTextField(
                controller: _emailController,
                labelText: 'E-mail corporativo',
                prefixIcon: Icons.email_outlined,
              ),
              const SizedBox(height: 16),
              CustomTextField(
                controller: _senhaController,
                labelText: 'Senha',
                prefixIcon: Icons.lock_outline,
                obscureText: true,
              ),
              const SizedBox(height: 8),
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: _abrirModalRecuperacao,
                  style: TextButton.styleFrom(
                    foregroundColor: AppColors.neonCyan,
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                  child: const Text(
                    'Esqueci minha senha',
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              if (_controller.erro != null) ...[
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.error.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: AppColors.error.withValues(alpha: 0.5),
                    ),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.error_outline, color: AppColors.error),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          _controller.erro!,
                          style: const TextStyle(color: AppColors.error),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
              ],
              _BotaoNeon(
                text: 'Acessar Sistema',
                isLoading: _controller.carregando,
                onPressed: _controller.carregando ? null : _submeter,
              ),
            ],
          ),
        ),
        const SizedBox(height: 28),
        Text(
          'GEOLOCALIZAÇÃO  •  BIOMETRIA  •  SEGURANÇA',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 9.5,
            letterSpacing: 2,
            color: AppColors.textSecondaryDark.withValues(alpha: 0.5),
          ),
        ),
      ],
    );
  }

  /// Cartão de vidro fosco com colchetes de HUD nos cantos.
  Widget _painelVidro({required Widget child}) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(24),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
        child: CustomPaint(
          foregroundPainter: const _CantosPainter(),
          child: Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: AppColors.cardDark.withValues(alpha: 0.55),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(
                color: AppColors.neonCyan.withValues(alpha: 0.22),
              ),
            ),
            child: child,
          ),
        ),
      ),
    );
  }
}

/// Botão com gradiente, brilho neon e efeito água ao tocar.
class _BotaoNeon extends StatelessWidget {
  final String text;
  final bool isLoading;
  final VoidCallback? onPressed;

  const _BotaoNeon({
    required this.text,
    required this.isLoading,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 54,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        gradient: const LinearGradient(
          colors: [AppColors.primary, AppColors.neonCyan],
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.45),
            blurRadius: 22,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: IgnorePointer(
        ignoring: onPressed == null,
        child: EfeitoAgua(
          cor: AppColors.white,
          borderRadius: BorderRadius.circular(16),
          onTap: onPressed,
          child: Center(
            child: isLoading
                ? const SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.4,
                      color: AppColors.white,
                    ),
                  )
                : Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        text,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.5,
                          color: AppColors.white,
                        ),
                      ),
                      const SizedBox(width: 8),
                      const Icon(
                        Icons.arrow_forward_rounded,
                        size: 20,
                        color: AppColors.white,
                      ),
                    ],
                  ),
          ),
        ),
      ),
    );
  }
}

/// Logo: pin dentro de um círculo de vidro com anéis orbitando.
class _LogoOrbital extends StatefulWidget {
  const _LogoOrbital();

  @override
  State<_LogoOrbital> createState() => _LogoOrbitalState();
}

class _LogoOrbitalState extends State<_LogoOrbital>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 8),
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
      width: 108,
      height: 108,
      child: Stack(
        alignment: Alignment.center,
        children: [
          AnimatedBuilder(
            animation: _controller,
            builder: (context, _) => CustomPaint(
              size: const Size(108, 108),
              painter: _LogoPainter(_controller.value),
            ),
          ),
          Container(
            width: 66,
            height: 66,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: [
                  AppColors.primary.withValues(alpha: 0.4),
                  AppColors.backgroundDeep.withValues(alpha: 0.95),
                ],
              ),
              border: Border.all(
                color: AppColors.neonCyan.withValues(alpha: 0.5),
              ),
              boxShadow: [
                BoxShadow(
                  color: AppColors.neonCyan.withValues(alpha: 0.35),
                  blurRadius: 24,
                ),
              ],
            ),
            child: const Icon(
              Icons.location_on,
              size: 34,
              color: AppColors.white,
              shadows: [Shadow(color: AppColors.neonCyan, blurRadius: 14)],
            ),
          ),
        ],
      ),
    );
  }
}

class _LogoPainter extends CustomPainter {
  final double t;

  _LogoPainter(this.t);

  @override
  void paint(Canvas canvas, Size size) {
    final c = size.center(Offset.zero);
    final ang = t * 2 * math.pi;

    for (var i = 0; i < 2; i++) {
      final r = 52.0 - i * 8;
      final dir = i == 0 ? 1.0 : -1.0;
      final rect = Rect.fromCircle(center: c, radius: r);
      canvas.drawArc(
        rect,
        0,
        2 * math.pi,
        false,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.6
          ..strokeCap = StrokeCap.round
          ..shader = SweepGradient(
            colors: [
              AppColors.neonCyan.withValues(alpha: 0.04),
              AppColors.neonCyan,
              AppColors.neonCyan.withValues(alpha: 0.04),
            ],
            transform: GradientRotation(ang * dir * (1 + i * 0.6)),
          ).createShader(rect),
      );
    }

    final sat = c + Offset(math.cos(ang * 2), math.sin(ang * 2)) * 52;
    canvas.drawCircle(
      sat,
      6,
      Paint()
        ..color = AppColors.neonCyan.withValues(alpha: 0.6)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6),
    );
    canvas.drawCircle(sat, 2.6, Paint()..color = AppColors.white);
  }

  @override
  bool shouldRepaint(covariant _LogoPainter old) => old.t != t;
}

class _CantosPainter extends CustomPainter {
  const _CantosPainter();

  @override
  void paint(Canvas canvas, Size size) {
    const l = 16.0;
    const m = 8.0;
    final w = size.width;
    final h = size.height;

    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.round
      ..color = AppColors.neonCyan.withValues(alpha: 0.7);

    final path = Path()
      ..moveTo(m, m + l)
      ..lineTo(m, m)
      ..lineTo(m + l, m)
      ..moveTo(w - m - l, m)
      ..lineTo(w - m, m)
      ..lineTo(w - m, m + l)
      ..moveTo(m, h - m - l)
      ..lineTo(m, h - m)
      ..lineTo(m + l, h - m)
      ..moveTo(w - m - l, h - m)
      ..lineTo(w - m, h - m)
      ..lineTo(w - m, h - m - l);

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant _CantosPainter old) => false;
}
