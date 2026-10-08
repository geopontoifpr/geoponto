import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/widgets/primary_button.dart';
import '../models/jornada_trabalho_model.dart';
import '../models/jornada_usuario_model.dart';
import '../repositories/jornada_repository.dart';

class AtribuirJornadaScreen extends StatefulWidget {
  final JornadaTrabalhoModel jornada;

  const AtribuirJornadaScreen({super.key, required this.jornada});

  @override
  State<AtribuirJornadaScreen> createState() => _AtribuirJornadaScreenState();
}

class _AtribuirJornadaScreenState extends State<AtribuirJornadaScreen> {
  final _repository = JornadaRepository(Supabase.instance.client);
  final _supabase = Supabase.instance.client;

  bool _carregando = true;
  bool _salvando = false;

  List<dynamic> _usuarios = []; 
  String? _usuarioIdSelecionado;

  DateTime _dataInicio = DateTime.now();
  DateTime? _dataFim;

  @override
  void initState() {
    super.initState();
    _carregarUsuarios();
  }

  Future<void> _carregarUsuarios() async {
    try {
      final response = await _supabase
          .from('usuarios')
          .select('id, nome, email')
          .eq('ativo', true)
          .order('nome', ascending: true);

      setState(() {
        _usuarios = response as List<dynamic>;
        _carregando = false;
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro ao carregar colaboradores: $e'), backgroundColor: AppColors.error),
        );
        setState(() => _carregando = false);
      }
    }
  }

  Future<void> _selecionarData(BuildContext context, bool isInicio) async {
    final DateTime? selecionada = await showDatePicker(
      context: context,
      initialDate: isInicio ? _dataInicio : (_dataFim ?? DateTime.now()),
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );

    if (selecionada != null && mounted) {
      setState(() {
        if (isInicio) {
          _dataInicio = selecionada;
          if (_dataFim != null && _dataFim!.isBefore(_dataInicio)) {
            _dataFim = null;
          }
        } else {
          if (selecionada.isBefore(_dataInicio)) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('A data fim não pode ser antes do início.'), backgroundColor: AppColors.error),
            );
          } else {
            _dataFim = selecionada;
          }
        }
      });
    }
  }

  Future<void> _salvarVigencia() async {
    if (_usuarioIdSelecionado == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Selecione um colaborador.', style: TextStyle(color: Colors.white)), backgroundColor: AppColors.error),
      );
      return;
    }

    setState(() => _salvando = true);

    try {
      final novaVigencia = JornadaUsuarioModel(
        id: '',
        usuarioId: _usuarioIdSelecionado!,
        jornadaId: widget.jornada.id,
        dataInicioVigencia: _dataInicio,
        dataFimVigencia: _dataFim,
      );

      await _repository.atribuirJornada(novaVigencia);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Jornada atribuída com sucesso!'), backgroundColor: AppColors.success),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro ao atribuir: $e'), backgroundColor: AppColors.error),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _salvando = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Atribuir Jornada'),
      ),
      body: _carregando
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Theme.of(context).primaryColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Theme.of(context).primaryColor.withOpacity(0.3)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Jornada Selecionada:', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 4),
                        Text(
                          '${widget.jornada.cargaHorariaSemanal} Horas Semanais',
                          style: TextStyle(fontSize: 20, color: Theme.of(context).primaryColor, fontWeight: FontWeight.w900),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 32),
                  const Text('Colaborador', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                  const SizedBox(height: 8),
                  DropdownButtonFormField<String>(
                    isExpanded: true,
                    decoration: InputDecoration(
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      filled: true,
                      fillColor: Theme.of(context).cardColor,
                    ),
                    hint: const Text('Selecione o colaborador...'),
                    value: _usuarioIdSelecionado,
                    items: _usuarios.map((u) {
                      return DropdownMenuItem<String>(
                        value: u['id'] as String,
                        child: Text('${u['nome']} (${u['email']})', overflow: TextOverflow.ellipsis),
                      );
                    }).toList(),
                    onChanged: (val) => setState(() => _usuarioIdSelecionado = val),
                  ),
                  const SizedBox(height: 24),

                  const Text('Data de Início da Vigência', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                  const SizedBox(height: 8),
                  InkWell(
                    onTap: () => _selecionarData(context, true),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey.shade400),
                        borderRadius: BorderRadius.circular(12),
                        color: Theme.of(context).cardColor,
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('${_dataInicio.day.toString().padLeft(2, '0')}/${_dataInicio.month.toString().padLeft(2, '0')}/${_dataInicio.year}'),
                          const Icon(Icons.calendar_today_outlined, size: 20),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),

                  const Text('Data de Fim (Opcional)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                  const SizedBox(height: 8),
                  InkWell(
                    onTap: () => _selecionarData(context, false),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey.shade400),
                        borderRadius: BorderRadius.circular(12),
                        color: Theme.of(context).cardColor,
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            _dataFim != null
                                ? '${_dataFim!.day.toString().padLeft(2, '0')}/${_dataFim!.month.toString().padLeft(2, '0')}/${_dataFim!.year}'
                                : 'Sem data fim (Vigência Indeterminada)',
                            style: TextStyle(color: _dataFim == null ? Colors.grey : null),
                          ),
                          const Icon(Icons.calendar_today_outlined, size: 20),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 48),

                  PrimaryButton(
                    onPressed: _salvando ? null : _salvarVigencia,
                    isLoading: _salvando,
                    text: 'Salvar Atribuição',
                  ),
                ],
              ),
            ),
    );
  }
}