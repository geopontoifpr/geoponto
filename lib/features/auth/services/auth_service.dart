import 'package:flutter/foundation.dart';
import '../repositories/auth_repository.dart';
import '../../usuarios/models/usuario_model.dart';
import '../../../core/errors/app_exception.dart';
import '../../../core/utils/device_util.dart';

class AuthService {
  final AuthRepository _repository;

  AuthService({AuthRepository? repository})
      : _repository = repository ?? AuthRepository();

  Future<UsuarioModel> autenticar({
    required String email,
    required String senha,
  }) async {
    final emailTratado = email.trim();

    if (emailTratado.isEmpty || senha.isEmpty) {
      throw const CamposObrigatoriosException();
    }

    final usuario = await _repository.buscarPorCredenciais(emailTratado, senha);

    if (usuario == null) {
      throw AuthExceptionApp('E-mail ou senha inválidos. Verifique suas credenciais.');
    }

    if (!usuario.ativo) {
      throw UsuarioInativoException('Usuário inativo. Entre em contato com a administração.');
    }

    // === INÍCIO DA VALIDAÇÃO DO DISPOSITIVO ===
    
    // 1. Pega o ID da placa do celular atual
    if (!kDebugMode) {
      final String? dispositivoAtual = await DeviceUtil.getDeviceId();

      if (dispositivoAtual == null || dispositivoAtual.isEmpty) {
        throw AuthExceptionApp('Erro de segurança: Não foi possível identificar o hardware deste aparelho.');
      }

      final String? dispositivoCadastrado = usuario.dispositivoUsuario;

      if (dispositivoCadastrado == null || dispositivoCadastrado.isEmpty) {
        // 2. Primeiro acesso neste aparelho: Vincula no banco
        await _repository.vincularDispositivo(usuario.id, dispositivoAtual);
        
        // Atualiza o objeto na memória e segue o baile
        return usuario.copyWith(dispositivoUsuario: dispositivoAtual);
        
      } else if (dispositivoCadastrado != dispositivoAtual) {
        // 3. Celular diferente do que está no banco: Bloqueia!
        throw AuthExceptionApp(
          'Acesso negado.\nSua conta já está vinculada a outro celular.\n'
          'Solicite ao RH ou Gestor a liberação do seu novo aparelho.'
        );
      }
    }
    // === FIM DA VALIDAÇÃO ===

    return usuario;
  }

  Future<void> logout() async {
    await _repository.deslogar();
  }

  Future<void> salvarPrimeiroAcesso(String novaSenha, String confirmarSenha, String usuarioId) async {
    // Regras de negócio e validação
    if (novaSenha.trim().length < 6) {
      throw ValidacaoException('A senha deve ter no mínimo 6 caracteres.');
    }
    if (novaSenha != confirmarSenha) {
      throw ValidacaoException('As senhas não coincidem.');
    }

    // Chama o repositório
    await _repository.atualizarSenha(novaSenha);
    await _repository.removerFlagPrimeiroAcesso(usuarioId);
  }
}