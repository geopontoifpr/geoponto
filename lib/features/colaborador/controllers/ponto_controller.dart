import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';

import '../../../core/errors/app_exception.dart';
import '../../../core/services/biometria_service.dart';
import '../../../core/services/location_service.dart';
import '../../../core/utils/calculadora_distancia_util.dart';
import '../models/registro_ponto_model.dart';
import '../repositories/ponto_repository.dart';

class PontoController extends ChangeNotifier {
  final String usuarioId;
  final PontoRepository _repository;
  final LocationService _locationService;
  final BiometriaService _biometriaService;

  PontoController({
    required this.usuarioId,
    PontoRepository? repository,
    LocationService? locationService,
    BiometriaService? biometriaService,
  })  : _repository = repository ?? PontoRepository(),
        _locationService = locationService ?? LocationService(),
        _biometriaService = biometriaService ?? BiometriaService();

  String nomeUsuario = 'Colaborador';
  String nomeEmpresa = 'Empresa';
  double? latitudeEmpresa;
  double? longitudeEmpresa;
  double? raioPermitido;
  Position? posicaoAtual;
  double? distanciaEmpresa;
  List<RegistroPontoModel> registros = [];
  bool carregando = true;
  bool atualizandoLocalizacao = false;
  bool registrando = false;
  bool dentroDoRaio = false;
  String? erro;
  String? avisoLocalizacao;

  bool get precisaoValida =>
      posicaoAtual != null && posicaoAtual!.accuracy <= 50;
  bool get podeBaterPonto =>
      !carregando && !atualizandoLocalizacao && !registrando &&
      dentroDoRaio && precisaoValida && registros.length < 4;

  Future<void> inicializar() async {
    try {
      carregando = true;
      erro = null;
      notifyListeners();
      final dados = await _repository.buscarDadosEmpresa(usuarioId);
      nomeUsuario = dados['nome_usuario'] as String;
      nomeEmpresa = dados['nome_empresa'] as String;
      latitudeEmpresa = dados['latitude_empresa'] as double;
      longitudeEmpresa = dados['longitude_empresa'] as double;
      raioPermitido = dados['raio_permitido_m'] as double;
      await atualizarLocalizacao();
      await carregarRegistros();
    } catch (e) {
      erro = _mensagemErro(e);
    } finally {
      carregando = false;
      notifyListeners();
    }
  }

  Future<void> atualizarLocalizacao() async {
    atualizandoLocalizacao = true;
    avisoLocalizacao = null;
    erro = null;
    notifyListeners();
    try {
      final posicao = await _locationService.obterLocalizacaoAtual();
      if (posicao.accuracy > 50) {
        posicaoAtual = posicao;
        distanciaEmpresa = null;
        dentroDoRaio = false;
        avisoLocalizacao = 'A localização está imprecisa (±${posicao.accuracy.toStringAsFixed(0)} m). Tente novamente em um local com melhor sinal.';
        return;
      }
      if (posicao.isMocked) {
        posicaoAtual = posicao;
        distanciaEmpresa = null;
        dentroDoRaio = false;
        avisoLocalizacao = 'O dispositivo informou uma localização simulada. Não é possível bater ponto com essa localização.';
        return;
      }
      posicaoAtual = posicao;
      final distancia = CalculadoraDistanciaUtil.calcularDistancia(
        latitudeOrigem: posicao.latitude,
        longitudeOrigem: posicao.longitude,
        latitudeDestino: latitudeEmpresa!,
        longitudeDestino: longitudeEmpresa!,
      );
      distanciaEmpresa = distancia;
      dentroDoRaio = distancia <= raioPermitido!;
    } catch (e) {
      posicaoAtual = null;
      distanciaEmpresa = null;
      dentroDoRaio = false;
      avisoLocalizacao = _mensagemErro(e);
    } finally {
      atualizandoLocalizacao = false;
      notifyListeners();
    }
  }

  Future<void> carregarRegistros() async {
    registros = await _repository.buscarRegistrosDoDia(usuarioId: usuarioId);
    notifyListeners();
  }

  Future<bool> baterPonto() async {
    if (registrando) return false;
    await atualizarLocalizacao();
    if (!dentroDoRaio || !precisaoValida || posicaoAtual == null) return false;

    registrando = true;
    erro = null;
    notifyListeners();
    try {
      final autenticado = await _biometriaService.autenticar();
      if (!autenticado) {
        erro = 'Autenticação biométrica cancelada. O ponto não foi registrado.';
        return false;
      }

      await atualizarLocalizacao();
      if (!dentroDoRaio || !precisaoValida || posicaoAtual == null) {
        erro = avisoLocalizacao ?? 'Você está fora do raio permitido. O ponto não foi registrado.';
        return false;
      }

      await carregarRegistros();
      final tipo = _repository.obterProximoTipo(registros);
      await _repository.registrarPonto(
        usuarioId: usuarioId,
        tipoRegistro: tipo,
        latitude: posicaoAtual!.latitude,
        longitude: posicaoAtual!.longitude,
      );
      await carregarRegistros();
      return true;
    } catch (e) {
      erro = _mensagemErro(e);
      return false;
    } finally {
      registrando = false;
      notifyListeners();
    }
  }

  String _mensagemErro(Object erro) {
    if (erro is LocalizacaoDesativadaException) {
      return 'A localização do aparelho está desativada. Ative-a nas configurações e tente novamente.';
    }
    if (erro is PermissaoLocalizacaoNegadaException) {
      return 'A permissão de localização foi negada. Ela é necessária para bater ponto.';
    }
    if (erro is PermissaoLocalizacaoNegadaPermanentementeException) {
      return 'A permissão de localização está bloqueada. Ative-a nas configurações do aplicativo.';
    }
    return erro.toString().replaceFirst('Exception: ', '');
  }
}
