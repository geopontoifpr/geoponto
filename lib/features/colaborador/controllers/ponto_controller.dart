import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';

import '../../../core/errors/app_exception.dart';
import '../../../core/services/biometria_service.dart';
import '../../../core/services/location_service.dart';
import '../../../core/utils/calculadora_distancia_util.dart';
import '../models/registro_ponto_model.dart';
import '../services/ponto_service.dart';

class PontoController extends ChangeNotifier {
  final String usuarioId;
  final PontoService _pontoService;
  final LocationService _locationService;
  final BiometriaService _biometriaService;

  PontoController({
    required this.usuarioId,
    PontoService? pontoService,
    LocationService? locationService,
    BiometriaService? biometriaService,
  })  : _pontoService = pontoService ?? PontoService(),
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

  // Agora o botão fica liberado para clique; a validação de GPS e raio roda AO CLICAR!
  bool get podeBaterPonto =>
      !carregando &&
      !atualizandoLocalizacao &&
      !registrando &&
      registros.length < 4;

  String get textoBotao => _pontoService.obterTextoBotao(registros);

  Future<void> inicializar(String nomeDoUsuarioLogado) async {
    try {
      carregando = true;
      erro = null;
      notifyListeners();

      final dados = await _pontoService.obterDadosEmpresaValidados();

      nomeUsuario = nomeDoUsuarioLogado;
      nomeEmpresa = dados['nome_empresa'] as String;
      latitudeEmpresa = dados['latitude_empresa'] as double;
      longitudeEmpresa = dados['longitude_empresa'] as double;
      raioPermitido = dados['raio_permitido_m'] as double;

      await carregarRegistros();
    } catch (e) {
      erro = _mensagemErro(e);
    } finally {
      carregando = false;
      notifyListeners();
    }
  }

  Future<bool> atualizarLocalizacao() async {
    atualizandoLocalizacao = true;
    avisoLocalizacao = null;
    erro = null;
    notifyListeners();
    try {
      if (latitudeEmpresa == null || longitudeEmpresa == null || raioPermitido == null) {
        final dados = await _pontoService.obterDadosEmpresaValidados();
        nomeEmpresa = dados['nome_empresa'] as String;
        latitudeEmpresa = dados['latitude_empresa'] as double;
        longitudeEmpresa = dados['longitude_empresa'] as double;
        raioPermitido = dados['raio_permitido_m'] as double;
      }

      final posicao = await _locationService.obterLocalizacaoAtual();

      if (posicao.isMocked) {
        posicaoAtual = posicao;
        distanciaEmpresa = null;
        dentroDoRaio = false;
        avisoLocalizacao =
            'Localização simulada (Fake GPS) detectada. Não é permitido bater ponto.';
        erro = avisoLocalizacao;
        return false;
      }

      if (posicao.accuracy > 50) {
        posicaoAtual = posicao;
        distanciaEmpresa = null;
        dentroDoRaio = false;
        avisoLocalizacao =
            'Sinal de GPS impreciso (±${posicao.accuracy.toStringAsFixed(0)}m). Vá para um local aberto e tente novamente.';
        erro = avisoLocalizacao;
        return false;
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

      if (!dentroDoRaio) {
        avisoLocalizacao =
            'Você está fora do raio permitido da empresa (${distancia.toStringAsFixed(0)}m de distância; máximo permitido: ${raioPermitido!.toStringAsFixed(0)}m).';
        erro = avisoLocalizacao;
        return false;
      }

      return true;
    } catch (e) {
      posicaoAtual = null;
      distanciaEmpresa = null;
      dentroDoRaio = false;
      avisoLocalizacao = _mensagemErro(e);
      erro = avisoLocalizacao;
      return false;
    } finally {
      atualizandoLocalizacao = false;
      notifyListeners();
    }
  }

  Future<void> carregarRegistros() async {
    registros = await _pontoService.buscarRegistrosDoDia(usuarioId);
    notifyListeners();
  }

  Future<bool> baterPonto() async {
    if (registrando || atualizandoLocalizacao) return false;

    registrando = true;
    erro = null;
    notifyListeners();

    try {
      // 1. Executa a verificação de GPS e Raio ao clicar no botão
      final gpsValido = await atualizarLocalizacao();
      if (!gpsValido || !dentroDoRaio || !precisaoValida || posicaoAtual == null) {
        erro ??= 'Não foi possível validar sua localização dentro do raio da empresa.';
        return false;
      }

      // 2. Solicita a Biometria (apenas em dispositivos móveis; na Web pula biometria)
      if (!kIsWeb) {
        final autenticado = await _biometriaService.autenticar();
        if (!autenticado) {
          erro = 'Autenticação biométrica cancelada. O ponto não foi registrado.';
          return false;
        }
      }

      // 3. Registra o ponto no Supabase
      await _pontoService.registrarPonto(
        usuarioId: usuarioId,
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
      return 'A localização do aparelho está desativada. Ative o GPS e tente novamente.';
    }
    if (erro is PermissaoLocalizacaoNegadaException) {
      return 'A permissão de localização foi negada. Ela é necessária para bater ponto.';
    }
    if (erro is PermissaoLocalizacaoNegadaPermanentementeException) {
      return 'A permissão de localização está bloqueada nas configurações do aparelho.';
    }
    return erro.toString().replaceFirst('Exception: ', '');
  }
}