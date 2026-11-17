import 'package:geolocator/geolocator.dart';

class CalculadoraDistanciaUtil {
  static double calcularDistancia({
    required double latitudeOrigem,
    required double longitudeOrigem,
    required double latitudeDestino,
    required double longitudeDestino,
  }) {
    return Geolocator.distanceBetween(
      latitudeOrigem,
      longitudeOrigem,
      latitudeDestino,
      longitudeDestino,
    );
  }
}