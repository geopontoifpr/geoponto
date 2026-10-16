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

  // Mapeamento dos valores do ENUM do banco para nomes amigáveis na interface
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
      Navigator.pop(context, true); // Retorna true para atualizar o calendário
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
    // Separa até 4 batidas ordenadas do dia (Entrada, Início intervalo, Retorno, Saída)
    final batidas = List<RegistroPontoModel>.from(widget.batidasDoDia)
      ..sort((a, b) => a.criadoEm.compareTo(b.criadoEm));

    final entrada = batidas.isNotEmpty ? batidas[0].criadoEm : null;
    final inicioIntervalo = batidas.length > 1 ? batidas[1].criadoEm : null;
    final retorno = batidas.length > 2 ? batidas[2].criadoEm : null;
    final saida = batidas.length > 3 ? batidas[3].criadoEm : null;

    return Scaffold(
      backgroundColor: const Color(0xFFF6F7F9),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0.5,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFF1E293B)),
          onPressed: () => Navigator.pop(context),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Ocorrências',
              style: TextStyle(
                color: Color(0xFF1E293B),
                fontWeight: FontWeight.bold,
                fontSize: 18,
              ),
            ),
            Text(
              _formatarDataSubtitulo(widget.dataSelecionada),
              style: const TextStyle(
                color: Color(0xFF64748B),
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
            child: const Text(
              'Sair',
              style: TextStyle(
                color: Color(0xFF475569),
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
            const Text(
              'Registros do dia',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1E293B),
              ),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.03),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                children: [
                  _buildLinhaRegistro('Entrada', _formatarHoraMinuto(entrada)),
                  const SizedBox(height: 14),
                  _buildLinhaRegistro('Início do intervalo', _formatarHoraMinuto(inicioIntervalo)),
                  const SizedBox(height: 14),
                  _buildLinhaRegistro('Retorno', _formatarHoraMinuto(retorno)),
                  const SizedBox(height: 14),
                  _buildLinhaRegistro('Saída', _formatarHoraMinuto(saida)),
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 14),
                    child: Divider(height: 1, thickness: 1, color: Color(0xFFE2E8F0)),
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Total trabalhado',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF1E293B),
                        ),
                      ),
                      Text(
                        _formatarDuracao(widget.totalTrabalhado),
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF1E293B),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // Se já existirem ocorrências enviadas neste dia, exibe o status delas
            if (widget.ocorrenciasDoDia.isNotEmpty) ...[
              const SizedBox(height: 24),
              const Text(
                'Solicitações enviadas neste dia',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1E293B),
                ),
              ),
              const SizedBox(height: 8),
              ...widget.ocorrenciasDoDia.map((oc) => Card(
                    margin: const EdgeInsets.only(bottom: 8),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    child: ListTile(
                      leading: Icon(
                        oc.aprovada ? Icons.check_circle : Icons.pending_actions,
                        color: oc.aprovada ? Colors.green : Colors.orange,
                      ),
                      title: Text(_tiposOcorrencia[oc.tipoOcorrencia] ?? oc.tipoOcorrencia),
                      subtitle: Text(oc.justificativa),
                      trailing: Text(
                        oc.aprovada ? 'Aprovada' : 'Pendente',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: oc.aprovada ? Colors.green : Colors.orange,
                        ),
                      ),
                    ),
                  )),
            ],

            const SizedBox(height: 24),

            // Bloco 2: Registrar ocorrência
            const Text(
              'Registrar ocorrência',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1E293B),
              ),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.03),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Tipo de ocorrência',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF1E293B),
                    ),
                  ),
                  const SizedBox(height: 8),
                  DropdownButtonFormField<String>(
                    value: _tipoSelecionado,
                    hint: const Text('Selecione uma ocorrência'),
                    decoration: InputDecoration(
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: Color(0xFFCBD5E1)),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: Color(0xFFCBD5E1)),
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
                  const Text(
                    'Assunto',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF1E293B),
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _assuntoController,
                    decoration: InputDecoration(
                      hintText: 'Informe o assunto',
                      hintStyle: const TextStyle(color: Color(0xFF94A3B8)),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: Color(0xFFCBD5E1)),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: Color(0xFFCBD5E1)),
                      ),
                    ),
                  ),
                  const SizedBox(height: 18),
                  const Text(
                    'Observações',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF1E293B),
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _observacoesController,
                    maxLines: 4,
                    decoration: InputDecoration(
                      hintText: 'Descreva a ocorrência...',
                      hintStyle: const TextStyle(color: Color(0xFF94A3B8)),
                      contentPadding: const EdgeInsets.all(16),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: Color(0xFFCBD5E1)),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: Color(0xFFCBD5E1)),
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

  Widget _buildLinhaRegistro(String label, String valor) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 15,
            color: Color(0xFF64748B),
          ),
        ),
        Text(
          valor,
          style: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w600,
            color: Color(0xFF1E293B),
          ),
        ),
      ],
    );
  }
}