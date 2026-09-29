import 'package:geolocator/geolocator.dart';

import '../errors/app_exception.dart';

class LocationService {
  Future<Position> obterLocalizacaoAtual() async {
    bool servicoAtivo = await Geolocator.isLocationServiceEnabled();

    if (!servicoAtivo) {
      throw const LocalizacaoDesativadaException();
    }

    LocationPermission permissao = await Geolocator.checkPermission();

    if (permissao == LocationPermission.denied) {
      permissao = await Geolocator.requestPermission();

      if (permissao == LocationPermission.denied) {
        throw const PermissaoLocalizacaoNegadaException();
      }
    }

    if (permissao == LocationPermission.deniedForever) {
      throw const PermissaoLocalizacaoNegadaPermanentementeException();
    }

    return await Geolocator.getCurrentPosition();
  }
}