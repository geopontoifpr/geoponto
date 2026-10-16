import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';

import '../../../core/widgets/custom_app_bar.dart';
import '../../../core/widgets/punch_button.dart';
import '../../usuarios/models/usuario_model.dart';
import '../controllers/ponto_controller.dart';
import '../models/registro_ponto_model.dart';

class BaterPontoScreen extends StatefulWidget {
  final UsuarioModel usuario;

  const BaterPontoScreen({super.key, required this.usuario});

  @override
  State<BaterPontoScreen> createState() => _BaterPontoScreenState();
}

class _BaterPontoScreenState extends State<BaterPontoScreen> {
  late final PontoController _controller;

  @override
  void initState() {
    super.initState();
    _controller = PontoController(usuarioId: widget.usuario.id);
    _controller.inicializar();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _baterPonto() async {
    final sucesso = await _controller.baterPonto();
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(sucesso
            ? 'Ponto registrado com sucesso.'
            : _controller.erro ?? _controller.avisoLocalizacao ?? 'Não foi possível registrar o ponto.'),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Future<void> _abrirConfiguracoesLocalizacao() async {
    final aberto = await Geolocator.openLocationSettings();
    if (!aberto && mounted) {
      await Geolocator.openAppSettings();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomAppBar(nomeUsuario: widget.usuario.nome),
      body: AnimatedBuilder(
        animation: _controller,
        builder: (context, _) {
          if (_controller.carregando) {
            return const Center(child: CircularProgressIndicator());
          }

          final temLocalizacao = _controller.posicaoAtual != null;
          final statusDisponivel = _controller.precisaoValida && _controller.distanciaEmpresa != null;
          final corStatus = !statusDisponivel
              ? Theme.of(context).colorScheme.error
              : _controller.dentroDoRaio
                  ? Colors.green
                  : Theme.of(context).colorScheme.error;

          return RefreshIndicator(
            onRefresh: () async {
              await _controller.inicializar();
            },
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                Text('Bater Ponto', style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold)),
                const SizedBox(height: 4),
                Text(_controller.nomeEmpresa, style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 20),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Row(children: [Icon(Icons.my_location), SizedBox(width: 8), Text('Sua localização', style: TextStyle(fontWeight: FontWeight.bold))]),
                        const SizedBox(height: 12),
                        if (temLocalizacao) ...[
                          Text('Latitude: ${_controller.posicaoAtual!.latitude.toStringAsFixed(6)}'),
                          Text('Longitude: ${_controller.posicaoAtual!.longitude.toStringAsFixed(6)}'),
                          Text('Precisão estimada: ±${_controller.posicaoAtual!.accuracy.toStringAsFixed(0)} m'),
                        ] else
                          const Text('Aguardando uma localização válida.'),
                        const SizedBox(height: 12),
                        OutlinedButton.icon(
                          onPressed: _controller.atualizandoLocalizacao ? null : _controller.atualizarLocalizacao,
                          icon: const Icon(Icons.refresh),
                          label: Text(_controller.atualizandoLocalizacao ? 'Atualizando...' : 'Atualizar localização'),
                        ),
                        if ((_controller.avisoLocalizacao ?? '').contains('desativada'))
                          TextButton.icon(
                            onPressed: _abrirConfiguracoesLocalizacao,
                            icon: const Icon(Icons.settings),
                            label: const Text('Abrir configurações de localização'),
                          ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Card(
                  color: corStatus.withOpacity(0.08),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(statusDisponivel && _controller.dentroDoRaio ? Icons.check_circle : Icons.block, color: corStatus),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                !statusDisponivel
                                    ? 'Localização não validada'
                                    : _controller.dentroDoRaio
                                        ? 'Você está dentro do raio permitido.'
                                        : 'Você está fora do raio permitido.',
                                style: TextStyle(color: corStatus, fontWeight: FontWeight.bold),
                              ),
                              if (_controller.distanciaEmpresa != null)
                                Text('Distância da empresa: ${_formatarDistancia(_controller.distanciaEmpresa!)}'),
                              if (_controller.raioPermitido != null)
                                Text('Raio permitido: ${_formatarDistancia(_controller.raioPermitido!)}'),
                              if (!statusDisponivel)
                                Text(_controller.avisoLocalizacao ?? 'Atualize a localização antes de bater ponto.', style: TextStyle(color: corStatus)),
                              if (statusDisponivel && !_controller.dentroDoRaio)
                                Text('A biometria ficará bloqueada enquanto você estiver fora do raio.', style: TextStyle(color: corStatus)),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                if (_controller.erro != null) ...[
                  const SizedBox(height: 12),
                  Text(_controller.erro!, style: TextStyle(color: Theme.of(context).colorScheme.error)),
                ],
                const SizedBox(height: 16),
                PunchButton(
                  habilitado: _controller.podeBaterPonto,
                  carregando: _controller.registrando || _controller.atualizandoLocalizacao,
                  texto: _textoBotao(_controller.registros),
                  onPressed: _baterPonto,
                ),
                const SizedBox(height: 24),
                Text('Registros de hoje', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                if (_controller.registros.isEmpty)
                  const Card(child: Padding(padding: EdgeInsets.all(18), child: Text('Nenhum registro realizado hoje.')))
                else
                  ..._controller.registros.map(_cartaoRegistro),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _cartaoRegistro(RegistroPontoModel registro) {
    final horario = registro.criadoEm.toLocal();
    final hora = '${horario.hour.toString().padLeft(2, '0')}:${horario.minute.toString().padLeft(2, '0')}';
    return Card(
      child: ListTile(
        leading: const Icon(Icons.access_time),
        title: Text(_formatarTipo(registro.tipoRegistro)),
        subtitle: Text('$hora · ${registro.latitudeDisp.toStringAsFixed(5)}, ${registro.longitudeDisp.toStringAsFixed(5)}'),
      ),
    );
  }

  String _textoBotao(List<RegistroPontoModel> registros) {
    if (registros.length >= 4) return 'Limite diário atingido';
    return registros.length.isEven ? 'Registrar Entrada' : 'Registrar Saída';
  }

  String _formatarTipo(String tipo) {
    switch (tipo.toUpperCase()) {
      case 'SAIDA':
      case 'SAÍDA':
        return 'Saída';
      default:
        return 'Entrada';
    }
  }

  String _formatarDistancia(double distancia) => distancia < 1000
      ? '${distancia.toStringAsFixed(0)} m'
      : '${(distancia / 1000).toStringAsFixed(2)} km';
}
