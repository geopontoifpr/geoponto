import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/errors/app_exception.dart';
import '../../../core/services/supabase_service.dart';
import '../../usuarios/models/usuario_model.dart';
import '../models/ocorrencia_model.dart';
import '../repositories/ocorrencia_repository.dart';
import 'package:flutter/foundation.dart';

class OcorrenciaService {
  final OcorrenciaRepository _repository;
  final SupabaseClient _client;

  OcorrenciaService({
    OcorrenciaRepository? repository,
    SupabaseClient? client,
  })  : _repository = repository ?? OcorrenciaRepository(client: client),
        _client = client ?? SupabaseService.instance.client;

  Future<UsuarioModel> _obterUsuarioAutenticado() async {
    final usuarioAuth = _client.auth.currentUser;
    if (usuarioAuth == null) {
      throw const ValidacaoException('Sua sessão expirou. Entre novamente.');
    }

    final usuario = await _repository.obterUsuario(usuarioAuth.id);
    if (usuario == null || !usuario.ativo) {
      throw const ValidacaoException('Não foi possível validar seu perfil de acesso.');
    }
    return usuario;
  }

  Future<UsuarioModel> _validarUsuarioLogado(UsuarioModel usuarioInformado) async {
    final usuarioAutenticado = await _obterUsuarioAutenticado();
    if (usuarioAutenticado.id != usuarioInformado.id ||
        usuarioAutenticado.tipoUsuario != usuarioInformado.tipoUsuario) {
      throw const ValidacaoException(
        'O usuário informado não corresponde à sessão autenticada.',
      );
    }
    return usuarioAutenticado;
  }

  Future<List<UsuarioModel>> listarPessoasComPendencias({
    required UsuarioModel usuarioLogado,
  }) async {
    final usuario = await _validarUsuarioLogado(usuarioLogado);
    final agora = DateTime.now();
    late final List<UsuarioModel> pessoasElegiveis;

    switch (usuario.tipoUsuario) {
      case TipoUsuario.gestor:
        final setorId = await _repository.obterSetorResponsavelDoGestor(usuario.id);
        if (setorId == null || setorId.isEmpty) {
          throw const ValidacaoException(
            'Seu perfil não possui um setor responsável vinculado.',
          );
        }
        pessoasElegiveis = await _repository.listarFuncionariosPorSetor(setorId);
      case TipoUsuario.administrador:
        pessoasElegiveis = (await _repository.listarUsuariosPorTipo(
          tipoUsuario: 'GESTOR',
        )).where((pessoa) => pessoa.ativo).toList();
      case TipoUsuario.funcionario:
        throw const ValidacaoException(
          'Colaboradores não possuem permissão para consultar ocorrências para avaliação.',
        );
    }

    if (pessoasElegiveis.isEmpty) return [];

    final ocorrencias = await _repository.listarPorUsuariosNoMes(
      usuariosIds: pessoasElegiveis.map((pessoa) => pessoa.id).toList(),
      ano: agora.year,
      mes: agora.month,
    );
    final idsComOcorrencias = ocorrencias
        .map((ocorrencia) => ocorrencia.usuarioId)
        .toSet();
    final idsComFechamento = await _repository.listarUsuariosComFechamentoFechado(
      usuariosIds: idsComOcorrencias.toList(),
      ano: agora.year,
      mes: agora.month,
    );

    return pessoasElegiveis
        .where((pessoa) =>
            idsComOcorrencias.contains(pessoa.id) &&
            !idsComFechamento.contains(pessoa.id))
        .toList();
  }

  Future<List<OcorrenciaModel>> listarOcorrenciasDaPessoa({
    required UsuarioModel usuarioLogado,
    required UsuarioModel pessoa,
  }) async {
    final usuario = await _validarUsuarioLogado(usuarioLogado);
    final agora = DateTime.now();

    return _listarOcorrenciasDeOutraPessoa(
      usuario: usuario,
      pessoa: pessoa,
      ano: agora.year,
      mes: agora.month,
    );
  }

  Future<List<OcorrenciaModel>> listarPorMes({
    required String usuarioId,
    required int ano,
    required int mes,
  }) async {
    final usuarioAutenticado = await _obterUsuarioAutenticado();
    if (usuarioAutenticado.id != usuarioId) {
      throw const ValidacaoException(
        'Você só pode consultar as próprias ocorrências nesta funcionalidade.',
      );
    }
    return _repository.listarPorMes(
      usuarioId: usuarioId,
      ano: ano,
      mes: mes,
    );
  }

  Future<List<OcorrenciaModel>> listarOcorrenciasConsultadas({
    required UsuarioModel usuarioLogado,
    required String usuarioId,
    required int ano,
    required int mes,
  }) async {
    final usuario = await _validarUsuarioLogado(usuarioLogado);
    if (usuario.id == usuarioId) {
      final fechado = await _repository.mesEstaFechado(
        usuarioId: usuarioId,
        ano: ano,
        mes: mes,
      );
      if (fechado) {
        throw const ValidacaoException(
          'O fechamento mensal desta pessoa já foi concluído. As ocorrências deste mês não estão mais disponíveis.',
        );
      }
      return _repository.listarPorMes(
        usuarioId: usuarioId,
        ano: ano,
        mes: mes,
      );
    }

    final pessoa = await _repository.obterUsuario(usuarioId);
    if (pessoa == null) {
      throw const ValidacaoException('O usuário selecionado não foi encontrado.');
    }

    return _listarOcorrenciasDeOutraPessoa(
      usuario: usuario,
      pessoa: pessoa,
      ano: ano,
      mes: mes,
    );
  }

  Future<List<OcorrenciaModel>> _listarOcorrenciasDeOutraPessoa({
    required UsuarioModel usuario,
    required UsuarioModel pessoa,
    required int ano,
    required int mes,
  }) async {
    if (usuario.tipoUsuario == TipoUsuario.gestor) {
      final setorResponsavel =
          await _repository.obterSetorResponsavelDoGestor(usuario.id);
      if (pessoa.tipoUsuario != TipoUsuario.funcionario ||
          setorResponsavel == null ||
          pessoa.setorId != setorResponsavel) {
        throw const ValidacaoException(
          'Você só pode consultar ocorrências de colaboradores do seu setor.',
        );
      }
    } else if (usuario.tipoUsuario == TipoUsuario.administrador) {
      if (pessoa.tipoUsuario != TipoUsuario.gestor) {
        throw const ValidacaoException(
          'O administrador só pode consultar ocorrências de gestores nesta funcionalidade.',
        );
      }
    } else {
      throw const ValidacaoException(
        'Colaboradores só podem consultar as próprias ocorrências.',
      );
    }

    final fechado = await _repository.mesEstaFechado(
      usuarioId: pessoa.id,
      ano: ano,
      mes: mes,
    );
    if (fechado) {
      throw const ValidacaoException(
        'O fechamento mensal desta pessoa já foi concluído. As ocorrências deste mês não estão mais disponíveis.',
      );
    }

    return _repository.listarPorMes(
      usuarioId: pessoa.id,
      ano: ano,
      mes: mes,
    );
  }

  Future<List<OcorrenciaModel>> listarPorGestor(String gestorId) async {
    final usuario = await _obterUsuarioAutenticado();
    if (usuario.id != gestorId || usuario.tipoUsuario != TipoUsuario.gestor) {
      throw const ValidacaoException('A consulta de pendências não está autorizada.');
    }
    return _repository.listarPorGestor(gestorId);
  }

  void _validarPrazo72Horas(DateTime dataReferencia) {
    final agora = DateTime.now();
    final hojeFimDoDia = DateTime(agora.year, agora.month, agora.day, 23, 59, 59);

    if (dataReferencia.isAfter(hojeFimDoDia)) {
      throw const ValidacaoException(
        'Não é permitido registrar ocorrências em datas futuras.',
      );
    }

    final fimDoDiaReferencia = DateTime(
      dataReferencia.year,
      dataReferencia.month,
      dataReferencia.day,
      23,
      59,
      59,
    );

    if (agora.difference(fimDoDiaReferencia).inHours > 72) {
      throw const ValidacaoException(
        'O prazo de 72 horas para registrar ou alterar ocorrências desta data já expirou.',
      );
    }
  }

  Future<void> salvarOcorrencia({
    String? idEdicao,
    required String usuarioId,
    required DateTime dataReferencia,
    required TipoOcorrenciaEnum? tipoOcorrencia,
    required String justificativa,
    required int minutosSolicitados,
  }) async {
    final usuario = await _obterUsuarioAutenticado();
    if (usuario.id != usuarioId) {
      throw const ValidacaoException('Você só pode registrar suas próprias ocorrências.');
    }

    if (tipoOcorrencia == null) {
      throw const ValidacaoException('Selecione o tipo de ocorrência.');
    }

    final justificativaLimpa = justificativa.trim();
    if (justificativaLimpa.isEmpty) {
      throw const ValidacaoException('Descreva a justificativa da ocorrência.');
    }

    if (minutosSolicitados <= 0 || minutosSolicitados > 720) {
      throw const ValidacaoException(
        'Informe uma quantidade válida de minutos para abono (entre 1 e 720 min).',
      );
    }

    _validarPrazo72Horas(dataReferencia);
    final horarioTime = OcorrenciaModel.formatarMinutosParaTime(minutosSolicitados);

    if (idEdicao != null && idEdicao.isNotEmpty) {
      final existente = await _repository.obterPorId(idEdicao);
      if (existente == null ||
          existente.usuarioId != usuarioId ||
          existente.foiAvaliada) {
        throw const ValidacaoException(
          'A ocorrência não existe, já foi avaliada ou não pode mais ser editada.',
        );
      }
      final conflito = await _repository.buscarPorDia(
        usuarioId: usuarioId,
        data: dataReferencia,
      );
      if (conflito != null && conflito.id != idEdicao) {
        throw const ValidacaoException(
          'Já existe outra ocorrência registrada na data selecionada.',
        );
      }
      await _repository.atualizarOcorrencia(
        id: idEdicao,
        dataReferencia: dataReferencia,
        tipoOcorrencia: tipoOcorrencia,
        justificativa: justificativaLimpa,
        horarioProposto: horarioTime,
      );
      return;
    }

    final existente = await _repository.buscarPorDia(
      usuarioId: usuarioId,
      data: dataReferencia,
    );
    if (existente != null) {
      throw const ValidacaoException(
        'Já existe uma ocorrência registrada neste dia. Edite ou exclua a ocorrência existente.',
      );
    }

    final gestorId = await _repository.obterGestorResponsavelId(usuarioId);
    final novaOcorrencia = OcorrenciaModel(
      usuarioId: usuarioId,
      gestorId: gestorId,
      dataInicio: dataReferencia,
      dataFim: dataReferencia,
      tipoOcorrencia: tipoOcorrencia,
      justificativa: justificativaLimpa,
      horarioProposto: horarioTime,
      aprovada: false,
    );
    await _repository.inserirOcorrencia(novaOcorrencia);
  }

  Future<void> excluirOcorrencia(OcorrenciaModel ocorrencia) async {
    final usuario = await _obterUsuarioAutenticado();
    if (usuario.id != ocorrencia.usuarioId || usuario.tipoUsuario == TipoUsuario.administrador) {
      throw const ValidacaoException('Você só pode excluir suas próprias ocorrências.');
    }
    if (ocorrencia.id == null) return;
    if (ocorrencia.foiAvaliada) {
      throw const ValidacaoException(
        'Não é possível excluir uma ocorrência que já foi avaliada.',
      );
    }
    await _repository.deletarOcorrencia(ocorrencia.id!);
  }

  Future<void> avaliarOcorrencia({
    required OcorrenciaModel ocorrencia,
    required bool aprovar,
    required UsuarioModel pessoaSelecionada,
    String? observacaoGestor,
  }) async {
    final usuario = await _obterUsuarioAutenticado();
    if (ocorrencia.id == null || ocorrencia.foiAvaliada) {
      throw const ValidacaoException('A ocorrência não está pendente de avaliação.');
    }
    if (usuario.id == ocorrencia.usuarioId) {
      throw const ValidacaoException('Você não pode aprovar ou recusar sua própria ocorrência.');
    }

    if (ocorrencia.usuarioId != pessoaSelecionada.id ||
        usuario.empresaId == null ||
        pessoaSelecionada.empresaId != usuario.empresaId) {
      throw const ValidacaoException(
        'A ocorrência não pertence à pessoa ou à empresa selecionada.',
      );
    }

    if (usuario.tipoUsuario == TipoUsuario.gestor) {
      final setorResponsavel =
          await _repository.obterSetorResponsavelDoGestor(usuario.id);
      if (pessoaSelecionada.tipoUsuario != TipoUsuario.funcionario ||
          setorResponsavel == null ||
          pessoaSelecionada.setorId != setorResponsavel ||
          ocorrencia.gestorId != usuario.id) {
        throw const ValidacaoException(
          'Você só pode avaliar ocorrências de colaboradores do seu setor.',
        );
      }
    } else if (usuario.tipoUsuario == TipoUsuario.administrador) {
      if (pessoaSelecionada.tipoUsuario != TipoUsuario.gestor ||
          ocorrencia.gestorId != usuario.id) {
        throw const ValidacaoException(
          'O administrador só pode avaliar ocorrências de gestores da própria empresa.',
        );
      }
    } else {
      throw const ValidacaoException('Colaboradores não podem avaliar ocorrências.');
    }

    final agora = DateTime.now();
    final fechado = await _repository.mesEstaFechado(
      usuarioId: ocorrencia.usuarioId,
      ano: agora.year,
      mes: agora.month,
    );
    if (fechado || ocorrencia.dataInicio.year != agora.year ||
        ocorrencia.dataInicio.month != agora.month) {
      throw const ValidacaoException(
        'Não é possível avaliar ocorrências de um mês encerrado ou diferente do mês atual.',
      );
    }

    final minutosAbonados = aprovar ? ocorrencia.minutosPropostos : 0;
    if (aprovar && (minutosAbonados <= 0 || minutosAbonados > 720)) {
      throw const ValidacaoException(
        'A quantidade de minutos solicitados nesta ocorrência é inválida.',
      );
    }

    await _repository.avaliarOcorrencia(
      ocorrenciaId: ocorrencia.id!,
      aprovar: aprovar,
      minutosAbonados: minutosAbonados,
      observacao: observacaoGestor?.trim().isEmpty == true
          ? null
          : observacaoGestor?.trim(),
    );
  }

  Future<void> reabrirOcorrencia({
    required OcorrenciaModel ocorrencia,
    required UsuarioModel pessoaSelecionada,
  }) async {
    final usuario = await _obterUsuarioAutenticado();
    if (ocorrencia.id == null || !ocorrencia.foiAvaliada) {
      throw const ValidacaoException('A ocorrência não está concluída.');
    }
    if (ocorrencia.usuarioId != pessoaSelecionada.id ||
        usuario.id == ocorrencia.usuarioId ||
        usuario.empresaId == null ||
        pessoaSelecionada.empresaId != usuario.empresaId) {
      throw const ValidacaoException('Você não possui permissão para reabrir esta ocorrência.');
    }

    if (usuario.tipoUsuario == TipoUsuario.gestor) {
      final setorResponsavel =
          await _repository.obterSetorResponsavelDoGestor(usuario.id);
      if (pessoaSelecionada.tipoUsuario != TipoUsuario.funcionario ||
          setorResponsavel == null ||
          pessoaSelecionada.setorId != setorResponsavel ||
          ocorrencia.gestorId != usuario.id) {
        throw const ValidacaoException(
          'Você só pode reabrir ocorrências de colaboradores do seu setor.',
        );
      }
    } else if (usuario.tipoUsuario == TipoUsuario.administrador) {
      if (pessoaSelecionada.tipoUsuario != TipoUsuario.gestor ||
          ocorrencia.gestorId != usuario.id) {
        throw const ValidacaoException(
          'O administrador só pode reabrir ocorrências de gestores da própria empresa.',
        );
      }
    } else {
      throw const ValidacaoException('Colaboradores não podem reabrir ocorrências.');
    }

    final agora = DateTime.now();
    final fechado = await _repository.mesEstaFechado(
      usuarioId: ocorrencia.usuarioId,
      ano: agora.year,
      mes: agora.month,
    );
    if (fechado ||
        ocorrencia.dataInicio.year != agora.year ||
        ocorrencia.dataInicio.month != agora.month) {
      throw const ValidacaoException(
        'Não é possível reabrir ocorrências de um mês encerrado ou diferente do mês atual.',
      );
    }

    await _repository.reabrirOcorrencia(ocorrencia.id!);
  }

}
