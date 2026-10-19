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
    _controller.inicializar(widget.usuario.nome);
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
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;

    // Padronização das cores com o restante do app
    final bgColorScreen = isDarkMode ? const Color(0xFF0F172A) : const Color(0xFFF6F7F9);
    final cardColor = isDarkMode ? const Color(0xFF1E293B) : Colors.white;
    final textColorPrimary = isDarkMode ? Colors.white : const Color(0xFF1E293B);
    final textColorSecondary = isDarkMode ? const Color(0xFF94A3B8) : Colors.black54;

    return Scaffold(
      backgroundColor: bgColorScreen,
      appBar: CustomAppBar(nomeUsuario: widget.usuario.nome),
      body: AnimatedBuilder(
        animation: _controller,
        builder: (context, _) {
          if (_controller.carregando) {
            return const Center(child: CircularProgressIndicator());
          }

          final temLocalizacao = _controller.posicaoAtual != null;
          final statusDisponivel = _controller.precisaoValida && _controller.distanciaEmpresa != null;
          
          // Ajuste de cores para o card de status (Verde e Vermelho)
          final corStatus = !statusDisponivel
              ? (isDarkMode ? const Color(0xFFEF4444) : theme.colorScheme.error)
              : _controller.dentroDoRaio
                  ? (isDarkMode ? const Color(0xFF22C55E) : Colors.green)
                  : (isDarkMode ? const Color(0xFFEF4444) : theme.colorScheme.error);

          return RefreshIndicator(
            onRefresh: () async {
              await _controller.inicializar(widget.usuario.nome);
            },
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                Text(
                  'Bater Ponto', 
                  style: theme.textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: textColorPrimary,
                  )
                ),
                const SizedBox(height: 4),
                Text(
                  _controller.nomeEmpresa, 
                  style: theme.textTheme.titleMedium?.copyWith(color: textColorSecondary)
                ),
                const SizedBox(height: 20),
                
                // Card de Localização Atual
                Card(
                  color: cardColor,
                  elevation: 2,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.my_location, color: textColorPrimary), 
                            const SizedBox(width: 8), 
                            Text('Sua localização', style: TextStyle(fontWeight: FontWeight.bold, color: textColorPrimary))
                          ]
                        ),
                        const SizedBox(height: 12),
                        if (temLocalizacao) ...[
                          Text('Latitude: ${_controller.posicaoAtual!.latitude.toStringAsFixed(6)}', style: TextStyle(color: textColorSecondary)),
                          Text('Longitude: ${_controller.posicaoAtual!.longitude.toStringAsFixed(6)}', style: TextStyle(color: textColorSecondary)),
                          Text('Precisão estimada: ±${_controller.posicaoAtual!.accuracy.toStringAsFixed(0)} m', style: TextStyle(color: textColorSecondary)),
                        ] else
                          Text('Aguardando uma localização válida.', style: TextStyle(color: textColorSecondary)),
                        const SizedBox(height: 12),
                        OutlinedButton.icon(
                          onPressed: _controller.atualizandoLocalizacao ? null : _controller.atualizarLocalizacao,
                          icon: const Icon(Icons.refresh),
                          label: Text(_controller.atualizandoLocalizacao ? 'Atualizando...' : 'Atualizar localização'),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: isDarkMode ? Colors.white : theme.primaryColor,
                          ),
                        ),
                        if ((_controller.avisoLocalizacao ?? '').contains('desativada'))
                          TextButton.icon(
                            onPressed: _abrirConfiguracoesLocalizacao,
                            icon: const Icon(Icons.settings),
                            label: const Text('Abrir configurações de localização'),
                            style: TextButton.styleFrom(
                              foregroundColor: isDarkMode ? Colors.white : theme.primaryColor,
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                
                // Card de Status da Localização (Raio da empresa)
                Card(
                  color: corStatus.withOpacity(isDarkMode ? 0.15 : 0.08),
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                    side: BorderSide(color: corStatus.withOpacity(isDarkMode ? 0.3 : 0.1)),
                  ),
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
                                Text('Distância da empresa: ${_formatarDistancia(_controller.distanciaEmpresa!)}', style: TextStyle(color: textColorPrimary)),
                              if (_controller.raioPermitido != null)
                                Text('Raio permitido: ${_formatarDistancia(_controller.raioPermitido!)}', style: TextStyle(color: textColorPrimary)),
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
                  Text(_controller.erro!, style: TextStyle(color: isDarkMode ? const Color(0xFFEF4444) : theme.colorScheme.error)),
                ],
                const SizedBox(height: 16),
                
                PunchButton(
                  habilitado: _controller.podeBaterPonto,
                  carregando: _controller.registrando || _controller.atualizandoLocalizacao,
                  texto: _textoBotao(_controller.registros),
                  onPressed: _baterPonto,
                ),
                const SizedBox(height: 24),
                
                Text('Registros de hoje', style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold, color: textColorPrimary)),
                const SizedBox(height: 8),
                if (_controller.registros.isEmpty)
                  Card(
                    color: cardColor,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    child: Padding(
                      padding: const EdgeInsets.all(18), 
                      child: Text('Nenhum registro realizado hoje.', style: TextStyle(color: textColorSecondary))
                    )
                  )
                else
                  ..._controller.registros.map((r) => _cartaoRegistro(r, isDarkMode, cardColor, textColorPrimary, textColorSecondary)),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _cartaoRegistro(RegistroPontoModel registro, bool isDarkMode, Color cardColor, Color textColorPrimary, Color textColorSecondary) {
    final horario = registro.criadoEm.toLocal();
    final hora = '${horario.hour.toString().padLeft(2, '0')}:${horario.minute.toString().padLeft(2, '0')}';
    
    return Card(
      color: cardColor,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        leading: Icon(
          registro.tipoRegistro.name.contains('entrada') ? Icons.login : Icons.logout,
          color: registro.tipoRegistro.name.contains('entrada') 
              ? (isDarkMode ? const Color(0xFF22C55E) : Colors.green) 
              : (isDarkMode ? const Color(0xFFF97316) : Colors.orange),
        ),
        title: Text(registro.tipoRegistro.titulo, style: TextStyle(fontWeight: FontWeight.bold, color: textColorPrimary)),
        subtitle: Text('$hora · Lat: ${registro.latitudeDisp.toStringAsFixed(3)}, Lon: ${registro.longitudeDisp.toStringAsFixed(3)}', style: TextStyle(color: textColorSecondary)),
      ),
    );
  }

  String _textoBotao(List<RegistroPontoModel> registros) {
    if (registros.length >= 4) return 'Limite diário atingido';
    
    const textosDosBotoes = [
      'Registrar Entrada 1',
      'Registrar Saída para Almoço',
      'Registrar Retorno do Almoço',
      'Registrar Fim do Expediente'
    ];
    
    return textosDosBotoes[registros.length];
  }
  
  String _formatarDistancia(double distancia) => distancia < 1000
      ? '${distancia.toStringAsFixed(0)} m'
      : '${(distancia / 1000).toStringAsFixed(2)} km';
}