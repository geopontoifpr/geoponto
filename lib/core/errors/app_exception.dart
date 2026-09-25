import 'package:flutter/material.dart';

abstract class AppException implements Exception {
  final String mensagem;
  final String? codigo;
  final Color cor;

  const AppException({
    required this.mensagem,
    this.codigo,
    this.cor = Colors.red,
  });

  @override
  String toString() => mensagem;
}

// Credenciais Supabase
class CredenciaisSupabaseException extends AppException {
  const CredenciaisSupabaseException([String mensagem = 'Variáveis SUPABASE_URL ou SUPABASE_ANON_KEY não encontradas no .env'])
      : super(mensagem: mensagem, codigo: 'SUPABASE_CREDENTIALS', cor: Colors.redAccent);
}


// preencha email e senha
class CamposObrigatoriosException extends AppException {
  const CamposObrigatoriosException([String mensagem = 'Por favor, preencha o e-mail e a senha.'])
      : super(mensagem: mensagem, codigo: 'REQUIRED_FIELDS', cor: Colors.orange);
}


// Erros de autenticação / credenciais
class AuthExceptionApp extends AppException {
  const AuthExceptionApp([String mensagem = 'E-mail ou senha inválidos.'])
      : super(mensagem: mensagem, codigo: 'AUTH_ERROR', cor: Colors.redAccent);
}

// Usuário inativo / bloqueado
class UsuarioInativoException extends AppException {
  const UsuarioInativoException([String mensagem = 'Usuário inativo. Contate o administrador.'])
      : super(mensagem: mensagem, codigo: 'USER_INACTIVE', cor: Colors.orange);
}

// Erros de permissão / RLS / Não autorizado
class NaoAutorizadoException extends AppException {
  const NaoAutorizadoException([String mensagem = 'Acesso não autorizado para este recurso.'])
      : super(mensagem: mensagem, codigo: 'UNAUTHORIZED', cor: Colors.deepOrange);
}

// Erros de conexão / servidor / Supabase
class ServidorException extends AppException {
  const ServidorException([String mensagem = 'Falha de comunicação com o servidor.'])
      : super(mensagem: mensagem, codigo: 'SERVER_ERROR', cor: Colors.red);
}

// Validações de formulários e campos obrigatórios
class ValidacaoException extends AppException {
  const ValidacaoException(String mensagem)
      : super(mensagem: mensagem, codigo: 'VALIDATION_ERROR', cor: Colors.amber);
}

// Erro de regras de ponto (geolocalização, fora do raio, etc. para Etapa 2)
class PontoForaDoRaioException extends AppException {
  const PontoForaDoRaioException([String mensagem = 'Você está fora do raio permitido da empresa.'])
      : super(mensagem: mensagem, codigo: 'OUT_OF_RANGE', cor: Colors.red);
}