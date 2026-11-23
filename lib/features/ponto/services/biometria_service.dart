import 'package:local_auth/local_auth.dart';

class BiometriaService {
  final LocalAuthentication _localAuth;

  BiometriaService({LocalAuthentication? localAuth})
      : _localAuth = localAuth ?? LocalAuthentication();

  Future<bool> autenticar() async {
    final suportado = await _localAuth.isDeviceSupported();
    final biometriaDisponivel = await _localAuth.canCheckBiometrics;
    final biometria = await _localAuth.getAvailableBiometrics();

    if (!suportado || !biometriaDisponivel || biometria.isEmpty) {
      throw StateError(
        'Este aparelho precisa ter biometria configurada para bater ponto.',
      );
    }

    return _localAuth.authenticate(
      localizedReason: 'Confirme sua identidade para registrar o ponto.',
      options: const AuthenticationOptions(
        biometricOnly: true,
        stickyAuth: true,
      ),
    );
  }
}
