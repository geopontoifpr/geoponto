import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';

import '../../../core/errors/app_exception.dart';
import '../../../core/utils/executor_async.dart';
import '../services/biometria_service.dart';
import '../services/location_service.dart';
import '../widgets/calculadora_distancia_util.dart';
import '../models/registro_ponto_model.dart';
import '../services/ponto_service.dart';

class PontoController extends ChangeNotifier with ExecutorAsync {
  static const double _precisaoMaximaMetros = 50;

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
        _biometriaService = biometriaService ?? BiometriaService() {
    carregando = true; // a tela começa em "carregando"
  }

  String nomeUsuario = 'Colaborador';
  String nomeEmpresa = 'Empresa';
  double? latitudeEmpresa;
  double? longitudeEmpresa;
  double? raioPermitido;
  Position? posicaoAtual;
  double? distanciaEmpresa;
  List<RegistroPontoModel> registros = [];
  bool atualizandoLocalizacao = false;
  bool registrando = false;
  bool dentroDoRaio = false;
  String? avisoLocalizacao;

  /// Mantém o nome usado pelas telas (`_controller.erro`).
  String? get erro => erroMensagem;
  set erro(String? valor) => erroMensagem = valor;

  bool get precisaoValida =>
      posicaoAtual != null && posicaoAtual!.accuracy <= _precisaoMaximaMetros;

  // O botão fica liberado; a validação de GPS/raio roda AO CLICAR.
  bool get podeBaterPonto =>
      !carregando &&
      !atualizandoLocalizacao &&
      !registrando &&
      registros.length < 4;

  /// Mensagens amigáveis para os erros de localização.
  @override
  String mensagemDeErro(Object erro, String? padrao) {
    if (erro is LocalizacaoDesativadaException) {
      return 'A localização do aparelho está desativada. Ative o GPS e tente novamente.';
    }
    if (erro is PermissaoLocalizacaoNegadaException) {
      return 'A permissão de localização foi negada. Ela é necessária para bater ponto.';
    }
    if (erro is PermissaoLocalizacaoNegadaPermanentementeException) {
      return 'A permissão de localização está bloqueada nas configurações do aparelho.';
    }
    return super.mensagemDeErro(erro, padrao);
  }

  Future<void> _carregarDadosEmpresa() async {
    final dados = await _pontoService.obterDadosEmpresaValidados();
    nomeEmpresa = dados['nome_empresa'] as String;
    latitudeEmpresa = dados['latitude_empresa'] as double;
    longitudeEmpresa = dados['longitude_empresa'] as double;
    raioPermitido = dados['raio_permitido_m'] as double;
  }

  Future<void> inicializar(String nomeDoUsuarioLogado) => executar(() async {
        await _carregarDadosEmpresa();
        nomeUsuario = nomeDoUsuarioLogado;
        await carregarRegistros();
      });

  Future<void> carregarRegistros() async {
    registros = await _pontoService.buscarRegistrosDoDia(usuarioId);
    notifyListeners();
  }

  /// Marca a localização como inválida e guarda o aviso. Sempre retorna false.
  bool _rejeitarLocalizacao(String aviso, {Position? posicao}) {
    posicaoAtual = posicao;
    distanciaEmpresa = null;
    dentroDoRaio = false;
    avisoLocalizacao = aviso;
    erro = aviso;
    return false;
  }

  Future<bool> atualizarLocalizacao() async {
    atualizandoLocalizacao = true;
    avisoLocalizacao = null;
    erro = null;
    notifyListeners();

    try {
      if (latitudeEmpresa == null ||
          longitudeEmpresa == null ||
          raioPermitido == null) {
        await _carregarDadosEmpresa();
      }

      final posicao = await _locationService.obterLocalizacaoAtual();

      if (posicao.isMocked) {
        return _rejeitarLocalizacao(
          'Localização simulada (Fake GPS) detectada. Não é permitido bater ponto.',
          posicao: posicao,
        );
      }

      if (posicao.accuracy > _precisaoMaximaMetros) {
        return _rejeitarLocalizacao(
          'Sinal de GPS impreciso (±${posicao.accuracy.toStringAsFixed(0)}m). '
          'Vá para um local aberto e tente novamente.',
          posicao: posicao,
        );
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
            'Você está fora do raio permitido da empresa (${distancia.toStringAsFixed(0)}m '
            'de distância; máximo permitido: ${raioPermitido!.toStringAsFixed(0)}m).';
        erro = avisoLocalizacao;
        return false;
      }

      return true;
    } catch (e) {
      return _rejeitarLocalizacao(mensagemDeErro(e, null));
    } finally {
      atualizandoLocalizacao = false;
      notifyListeners();
    }
  }

  Future<bool> baterPonto() async {
    if (registrando || atualizandoLocalizacao) return false;

    registrando = true;
    erro = null;
    notifyListeners();

    try {
      // 1. GPS e raio
      final gpsValido = await atualizarLocalizacao();
      if (!gpsValido || !dentroDoRaio || !precisaoValida || posicaoAtual == null) {
        erro ??= 'Não foi possível validar sua localização dentro do raio da empresa.';
        return false;
      }

      // 2. Biometria (apenas em dispositivos móveis)
      if (!kIsWeb) {
        final autenticado = await _biometriaService.autenticar();
        if (!autenticado) {
          erro = 'Autenticação biométrica cancelada. O ponto não foi registrado.';
          return false;
        }
      }

      // 3. Registro no Supabase
      await _pontoService.registrarPonto(
        usuarioId: usuarioId,
        latitude: posicaoAtual!.latitude,
        longitude: posicaoAtual!.longitude,
      );
      await carregarRegistros();
      return true;
    } catch (e) {
      erro = mensagemDeErro(e, null);
      return false;
    } finally {
      registrando = false;
      notifyListeners();
    }
  }
}