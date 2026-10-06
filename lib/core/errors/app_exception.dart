import 'package:flutter/material.dart';
import '../themes/app_themes.dart'; // Importe seu arquivo de temas aqui

abstract class AppException implements Exception {
  final String mensagem;
  final String? codigo;
  final Color cor;

  const AppException({
    required this.mensagem,
    this.codigo,
    this.cor = AppThemes.errorColor, // Cor padrão baseada no seu tema
  });

  @override
  String toString() => mensagem;
}

// Credenciais Supabase
class CredenciaisSupabaseException extends AppException {
  const CredenciaisSupabaseException([String mensagem = 'Variáveis SUPABASE_URL ou SUPABASE_ANON_KEY não encontradas no .env'])
      : super(mensagem: mensagem, codigo: 'SUPABASE_CREDENTIALS', cor: AppThemes.errorColor);
}

// preencha email e senha
class CamposObrigatoriosException extends AppException {
  const CamposObrigatoriosException([String mensagem = 'Por favor, preencha o e-mail e a senha.'])
      : super(mensagem: mensagem, codigo: 'REQUIRED_FIELDS', cor: AppThemes.warningColor);
}

// Erros de autenticação / credenciais
class AuthExceptionApp extends AppException {
  const AuthExceptionApp([String mensagem = 'E-mail ou senha inválidos.'])
      : super(mensagem: mensagem, codigo: 'AUTH_ERROR', cor: AppThemes.errorColor);
}

// Usuário inativo / bloqueado
class UsuarioInativoException extends AppException {
  const UsuarioInativoException([String mensagem = 'Usuário inativo. Contate o administrador.'])
      : super(mensagem: mensagem, codigo: 'USER_INACTIVE', cor: AppThemes.warningColor);
}

// Erros de permissão / RLS / Não autorizado
class NaoAutorizadoException extends AppException {
  const NaoAutorizadoException([String mensagem = 'Acesso não autorizado para este recurso.'])
      : super(mensagem: mensagem, codigo: 'UNAUTHORIZED', cor: AppThemes.warningColor);
}

// Erros de conexão / servidor / Supabase
class ServidorException extends AppException {
  const ServidorException([String mensagem = 'Falha de comunicação com o servidor.'])
      : super(mensagem: mensagem, codigo: 'SERVER_ERROR', cor: AppThemes.errorColor);
}

// Validações de formulários e campos obrigatórios
class ValidacaoException extends AppException {
  const ValidacaoException(String mensagem)
      : super(mensagem: mensagem, codigo: 'VALIDATION_ERROR', cor: AppThemes.warningColor);
}

// Erro de regras de ponto
class PontoForaDoRaioException extends AppException {
  const PontoForaDoRaioException([String mensagem = 'Você está fora do raio permitido da empresa.'])
      : super(mensagem: mensagem, codigo: 'OUT_OF_RANGE', cor: AppThemes.errorColor);
}

// Erro quando o serviço de localização está desativado
class LocalizacaoDesativadaException extends AppException {
  const LocalizacaoDesativadaException([String mensagem = 'O serviço de localização está desativado.']) 
      : super(mensagem: mensagem, codigo: 'LOCATION_DISABLED', cor: AppThemes.warningColor);
}

// Erro quando a permissão de localização foi negada
class PermissaoLocalizacaoNegadaException extends AppException {
  const PermissaoLocalizacaoNegadaException([String mensagem = 'Permissão de localização negada.']) 
      : super(mensagem: mensagem, codigo: 'LOCATION_PERMISSION_DENIED', cor: AppThemes.errorColor);
}

// Erro quando a permissão de localização foi negada permanentemente
class PermissaoLocalizacaoNegadaPermanentementeException extends AppException {
  const PermissaoLocalizacaoNegadaPermanentementeException([String mensagem = 'Permissão de localização negada permanentemente.']) 
      : super(mensagem: mensagem, codigo: 'LOCATION_PERMISSION_DENIED_FOREVER', cor: AppThemes.errorColor);
}

// --- As três exceções corrigidas com o construtor correto e cores ---

class ConexaoException extends AppException {
  const ConexaoException([String mensagem = 'Falha na conexão de rede. Verifique sua internet.'])
      : super(mensagem: mensagem, codigo: 'NETWORK_ERROR', cor: AppThemes.warningColor);
}

class DadoDuplicadoException extends AppException {
  const DadoDuplicadoException([String mensagem = 'Este registro já está cadastrado no sistema.'])
      : super(mensagem: mensagem, codigo: 'DUPLICATE_ENTRY', cor: AppThemes.warningColor);
}

class NaoEncontradoException extends AppException {
  const NaoEncontradoException([String mensagem = 'Registro não encontrado.'])
      : super(mensagem: mensagem, codigo: 'NOT_FOUND', cor: AppThemes.infoColor);
}