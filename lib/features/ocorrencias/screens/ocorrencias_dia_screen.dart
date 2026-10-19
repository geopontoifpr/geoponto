import 'package:flutter/material.dart';
import '../../usuarios/models/usuario_model.dart';
import '../../colaborador/models/registro_ponto_model.dart';
import '../models/ocorrencia_model.dart';
import '../repositories/ocorrencia_repository.dart';
import '../../auth/repositories/auth_repository.dart';
import '../../auth/screens/login_screen.dart';

class OcorrenciasDiaScreen extends StatefulWidget {
  final UsuarioModel usuario;
  final DateTime dataSelecionada;
  final List<RegistroPontoModel> batidasDoDia;
  final List<OcorrenciaModel> ocorrenciasDoDia;
  final Duration totalTrabalhado;

  const OcorrenciasDiaScreen({
    Key? key,
    required this.usuario,
    required this.dataSelecionada,
    required this.batidasDoDia,
    required this.ocorrenciasDoDia,
    required this.totalTrabalhado,
  }) : super(key: key);

  @override
  State<OcorrenciasDiaScreen> createState() => _OcorrenciasDiaScreenState();
}

class _OcorrenciasDiaScreenState extends State<OcorrenciasDiaScreen> {
  final _ocorrenciaRepo = OcorrenciaRepository();
  final _assuntoController = TextEditingController();
  final _observacoesController = TextEditingController();

  String? _tipoSelecionado;
  bool _salvando = false;

  final Map<String, String> _tiposOcorrencia = {
    'esquecimento': 'Esquecimento de marcação',
    'atraso': 'Atraso',
    'falta': 'Falta justificada',
    'saida_antecipada': 'Saída antecipada',
    'erro_registro': 'Erro no registro',
    'abono': 'Pedido de abono / Atestado',
  };

  @override
  void dispose() {
    _assuntoController.dispose();
    _observacoesController.dispose();
    super.dispose();
  }

  String _formatarDataSubtitulo(DateTime d) {
    const meses = [
      'Janeiro', 'Fevereiro', 'Março', 'Abril', 'Maio', 'Junho',
      'Julho', 'Agosto', 'Setembro', 'Outubro', 'Novembro', 'Dezembro'
    ];
    return '${meses[d.month - 1]} ${d.day}, ${d.year}';
  }

  String _formatarHoraMinuto(DateTime? dt) {
    if (dt == null) return '--:--';
    return '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
  }

  String _formatarDuracao(Duration d) {
    final horas = d.inHours.toString().padLeft(2, '0');
    final minutos = (d.inMinutes % 60).toString().padLeft(2, '0');
    return '${horas}h$minutos';
  }

  Future<void> _salvarOcorrencia() async {
    if (_tipoSelecionado == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Selecione o tipo de ocorrência.')),
      );
      return;
    }
    if (_observacoesController.text.trim().isEmpty &&
        _assuntoController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Informe o assunto ou descreva a ocorrência.')),
      );
      return;
    }

    setState(() => _salvando = true);
    try {
      await _ocorrenciaRepo.registrarOcorrencia(
        usuarioId: widget.usuario.id,
        dataReferencia: widget.dataSelecionada,
        tipoOcorrencia: _tipoSelecionado!,
        assunto: _assuntoController.text.trim(),
        observacoes: _observacoesController.text.trim(),
      );

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Ocorrência registrada com sucesso!'),
          backgroundColor: Colors.green,
        ),
      );
      Navigator.pop(context, true); 
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erro ao registrar ocorrência: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) setState(() => _salvando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;

    // Padronização de Cores
    final bgColorScreen = isDarkMode ? const Color(0xFF0F172A) : const Color(0xFFF6F7F9);
    final cardColor = isDarkMode ? const Color(0xFF1E293B) : Colors.white;
    final textColorPrimary = isDarkMode ? Colors.white : const Color(0xFF1E293B);
    final textColorSecondary = isDarkMode ? const Color(0xFF94A3B8) : const Color(0xFF64748B);
    final borderColor = isDarkMode ? const Color(0xFF334155) : const Color(0xFFCBD5E1);
    final shadowColor = isDarkMode ? Colors.black.withOpacity(0.3) : Colors.black.withOpacity(0.03);

    final batidas = List<RegistroPontoModel>.from(widget.batidasDoDia)
      ..sort((a, b) => a.criadoEm.compareTo(b.criadoEm));

    final entrada = batidas.isNotEmpty ? batidas[0].criadoEm : null;
    final inicioIntervalo = batidas.length > 1 ? batidas[1].criadoEm : null;
    final retorno = batidas.length > 2 ? batidas[2].criadoEm : null;
    final saida = batidas.length > 3 ? batidas[3].criadoEm : null;

    return Scaffold(
      backgroundColor: bgColorScreen,
      appBar: AppBar(
        backgroundColor: isDarkMode ? const Color(0xFF1E293B) : Colors.white,
        elevation: 0.5,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: textColorPrimary),
          onPressed: () => Navigator.pop(context),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Ocorrências',
              style: TextStyle(
                color: textColorPrimary,
                fontWeight: FontWeight.bold,
                fontSize: 18,
              ),
            ),
            Text(
              _formatarDataSubtitulo(widget.dataSelecionada),
              style: TextStyle(
                color: textColorSecondary,
                fontSize: 13,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () async {
              await AuthRepository().deslogar();
              if (!context.mounted) return;
              Navigator.of(context).pushAndRemoveUntil(
                MaterialPageRoute(builder: (_) => const LoginScreen()),
                (route) => false,
              );
            },
            child: Text(
              'Sair',
              style: TextStyle(
                color: textColorSecondary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Bloco 1: Registros do dia
            Text(
              'Registros do dia',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: textColorPrimary,
              ),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: cardColor,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: shadowColor,
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                children: [
                  _buildLinhaRegistro('Entrada', _formatarHoraMinuto(entrada), textColorPrimary, textColorSecondary),
                  const SizedBox(height: 14),
                  _buildLinhaRegistro('Início do intervalo', _formatarHoraMinuto(inicioIntervalo), textColorPrimary, textColorSecondary),
                  const SizedBox(height: 14),
                  _buildLinhaRegistro('Retorno', _formatarHoraMinuto(retorno), textColorPrimary, textColorSecondary),
                  const SizedBox(height: 14),
                  _buildLinhaRegistro('Saída', _formatarHoraMinuto(saida), textColorPrimary, textColorSecondary),
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    child: Divider(height: 1, thickness: 1, color: borderColor),
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Total trabalhado',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: textColorPrimary,
                        ),
                      ),
                      Text(
                        _formatarDuracao(widget.totalTrabalhado),
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: textColorPrimary,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // Ocorrências enviadas
            if (widget.ocorrenciasDoDia.isNotEmpty) ...[
              const SizedBox(height: 24),
              Text(
                'Solicitações enviadas neste dia',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: textColorPrimary,
                ),
              ),
              const SizedBox(height: 8),
              ...widget.ocorrenciasDoDia.map((oc) => Card(
                    color: isDarkMode ? const Color(0xFF334155) : Colors.white,
                    margin: const EdgeInsets.only(bottom: 8),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    child: ListTile(
                      leading: Icon(
                        oc.aprovada ? Icons.check_circle : Icons.pending_actions,
                        color: oc.aprovada 
                            ? (isDarkMode ? const Color(0xFF4CAF50) : Colors.green) 
                            : (isDarkMode ? const Color(0xFFFFB74D) : Colors.orange),
                      ),
                      title: Text(
                        _tiposOcorrencia[oc.tipoOcorrencia] ?? oc.tipoOcorrencia,
                        style: TextStyle(color: textColorPrimary, fontWeight: FontWeight.bold),
                      ),
                      subtitle: Text(
                        oc.justificativa,
                        style: TextStyle(color: textColorSecondary),
                      ),
                      trailing: Text(
                        oc.aprovada ? 'Aprovada' : 'Pendente',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: oc.aprovada 
                              ? (isDarkMode ? const Color(0xFF4CAF50) : Colors.green) 
                              : (isDarkMode ? const Color(0xFFFFB74D) : Colors.orange),
                        ),
                      ),
                    ),
                  )),
            ],

            const SizedBox(height: 24),

            // Bloco 2: Registrar ocorrência
            Text(
              'Registrar ocorrência',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: textColorPrimary,
              ),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: cardColor,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: shadowColor,
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Tipo de ocorrência',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: textColorPrimary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  DropdownButtonFormField<String>(
                    value: _tipoSelecionado,
                    dropdownColor: cardColor,
                    style: TextStyle(color: textColorPrimary, fontSize: 16),
                    hint: Text('Selecione uma ocorrência', style: TextStyle(color: textColorSecondary)),
                    decoration: InputDecoration(
                      fillColor: isDarkMode ? bgColorScreen : Colors.white,
                      filled: true,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: borderColor),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: borderColor),
                      ),
                    ),
                    items: _tiposOcorrencia.entries
                        .map((e) => DropdownMenuItem(
                              value: e.key,
                              child: Text(e.value),
                            ))
                        .toList(),
                    onChanged: (val) => setState(() => _tipoSelecionado = val),
                  ),
                  const SizedBox(height: 18),
                  Text(
                    'Assunto',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: textColorPrimary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _assuntoController,
                    style: TextStyle(color: textColorPrimary),
                    decoration: InputDecoration(
                      fillColor: isDarkMode ? bgColorScreen : Colors.white,
                      filled: true,
                      hintText: 'Informe o assunto',
                      hintStyle: TextStyle(color: textColorSecondary),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: borderColor),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: borderColor),
                      ),
                    ),
                  ),
                  const SizedBox(height: 18),
                  Text(
                    'Observações',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: textColorPrimary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _observacoesController,
                    style: TextStyle(color: textColorPrimary),
                    maxLines: 4,
                    decoration: InputDecoration(
                      fillColor: isDarkMode ? bgColorScreen : Colors.white,
                      filled: true,
                      hintText: 'Descreva a ocorrência...',
                      hintStyle: TextStyle(color: textColorSecondary),
                      contentPadding: const EdgeInsets.all(16),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: borderColor),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: borderColor),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: ElevatedButton(
                      onPressed: _salvando ? null : _salvarOcorrencia,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF2563EB),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: _salvando
                          ? const SizedBox(
                              height: 22,
                              width: 22,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Text(
                              'Enviar Ocorrência',
                              style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                            ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLinhaRegistro(String label, String valor, Color colorPrimary, Color colorSecondary) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 15,
            color: colorSecondary,
          ),
        ),
        Text(
          valor,
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w600,
            color: colorPrimary,
          ),
        ),
      ],
    );
  }
}