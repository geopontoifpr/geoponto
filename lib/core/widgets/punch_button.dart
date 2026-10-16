import 'package:flutter/material.dart';

class PunchButton extends StatelessWidget {
  final bool habilitado;
  final bool carregando;
  final VoidCallback? onPressed;
  final String texto;

  const PunchButton({
    super.key,
    required this.habilitado,
    required this.carregando,
    required this.onPressed,
    required this.texto,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: ElevatedButton.icon(
        onPressed:
            habilitado && !carregando
                ? onPressed
                : null,
        icon: carregando
            ? const SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                ),
              )
            : const Icon(
                Icons.access_time,
              ),
        label: Text(
          carregando
              ? 'Registrando...'
              : texto,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }
}