import 'package:flutter/foundation.dart';
import '../errors/app_exception.dart';

/// Centraliza o padrão: ligar loading → try → tratar erro → desligar loading.
mixin ExecutorAsync on ChangeNotifier {
  bool carregando = false;
  bool salvando = false;
  String? erroMensagem;
  bool _descartado = false;

  /// Compatibilidade com telas que já usam `isLoading`.
  bool get isLoading => carregando;

  /// Evita "notifyListeners após dispose" (substitui o `_isDisposed` manual).
  @override
  void notifyListeners() {
    if (_descartado) return;
    super.notifyListeners();
  }

  @override
  void dispose() {
    _descartado = true;
    super.dispose();
  }

  /// Converte qualquer erro em texto para a tela. Controllers podem sobrescrever.
  String mensagemDeErro(Object erro, String? padrao) {
    if (erro is AppException) return erro.mensagem;
    if (padrao != null) return padrao;
    return erro.toString().replaceFirst(RegExp(r'^(Exception|Bad state): '), '');
  }

  /// Executa [acao] controlando loading e erro. Retorna true se não houve erro.
  /// - [erroPadrao]: texto para erros que não são AppException (null = usa a mensagem do erro).
  /// - [salvar]: usa a flag `salvando` em vez de `carregando`.
  /// - [mostrarCarregando]: false = não liga nenhuma flag (só limpa/preenche o erro).
  Future<bool> executar(
    Future<void> Function() acao, {
    String? erroPadrao,
    bool salvar = false,
    bool mostrarCarregando = true,
  }) async {
    final usaCarregando = mostrarCarregando && !salvar;
    if (usaCarregando) carregando = true;
    if (salvar) salvando = true;
    erroMensagem = null;
    notifyListeners();

    try {
      await acao();
      return true;
    } catch (e) {
      erroMensagem = mensagemDeErro(e, erroPadrao);
      return false;
    } finally {
      if (usaCarregando) carregando = false;
      if (salvar) salvando = false;
      notifyListeners();
    }
  }

  /// Só liga/desliga o loading e deixa o erro propagar (para telas que fazem try/catch).
  Future<T> comCarregamento<T>(Future<T> Function() acao) async {
    carregando = true;
    notifyListeners();
    try {
      return await acao();
    } finally {
      carregando = false;
      notifyListeners();
    }
  }
}