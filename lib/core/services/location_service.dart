import 'package:geolocator/geolocator.dart';

class LocationService {
  Future<Position> obterLocalizacaoAtual() async {
    bool servicoAtivo = await Geolocator.isLocationServiceEnabled();

    if (!servicoAtivo) {
      throw Exception('O serviço de localização está desativado.');
    }

    LocationPermission permissao = await Geolocator.checkPermission();

    if (permissao == LocationPermission.denied) {
      permissao = await Geolocator.requestPermission();

      if (permissao == LocationPermission.denied) {
        throw Exception('Permissão de localização negada.');
      }
    }

    if (permissao == LocationPermission.deniedForever) {
      throw Exception('Permissão de localização negada permanentemente.');
    }

    return await Geolocator.getCurrentPosition();
  }
}