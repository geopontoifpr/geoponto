import 'dart:async'; // Necessário para reconhecer o TimeoutException
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

    try {
      // Adicionamos um limite de 10 segundos para não congelar o ecrã
      return await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
        timeLimit: const Duration(seconds: 10),
      );
    } on TimeoutException {
      // Se não conseguir em 10 segundos, tenta pegar a última localização conhecida do cache
      final ultimaPosicao = await Geolocator.getLastKnownPosition();
      
      if (ultimaPosicao != null) {
        return ultimaPosicao;
      } else {
        // Se também não tiver cache, lança um erro para o Controller apanhar
        throw Exception('Sinal de GPS fraco. Vá para um local aberto e tente novamente.');
      }
    }
  }
}