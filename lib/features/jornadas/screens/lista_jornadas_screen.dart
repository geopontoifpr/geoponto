import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/constants/app_colors.dart';
import '../models/jornada_trabalho_model.dart';
import '../repositories/jornada_repository.dart';
import 'atribuir_jornada_screen.dart';

class ListaJornadasScreen extends StatefulWidget {
  const ListaJornadasScreen({super.key});

  @override
  State<ListaJornadasScreen> createState() => _ListaJornadasScreenState();
}

class _ListaJornadasScreenState extends State<ListaJornadasScreen> {
  final _repository = JornadaRepository(Supabase.instance.client);
  
  List<JornadaTrabalhoModel> _jornadas = [];
  bool _carregando = true;

  @override
  void initState() {
    super.initState();
    _carregarJornadas();
  }

  Future<void> _carregarJornadas() async {
    try {
      setState(() => _carregando = true);
      final jornadas = await _repository.listarJornadas();
      setState(() {
        _jornadas = jornadas;
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro ao carregar: $e'), backgroundColor: AppColors.error),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _carregando = false);
      }
    }
  }

  void _mostrarDialogoNovaJornada() {
    final controller = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Nova Carga Horária Base'),
        content: TextField(
          controller: controller,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(
            labelText: 'Horas semanais (Ex: 44)',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () async {
              final horas = int.tryParse(controller.text);
              if (horas != null && horas > 0) {
                Navigator.pop(context);
                try {
                  await _repository.cadastrarJornada(horas);
                  _carregarJornadas();
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Jornada cadastrada!'), backgroundColor: AppColors.success),
                    );
                  }
                } catch (e) {
                   if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Erro: $e'), backgroundColor: AppColors.error),
                      );
                   }
                }
              }
            },
            child: const Text('Salvar'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Modelos de Jornada'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            tooltip: 'Criar nova carga horária base',
            onPressed: _mostrarDialogoNovaJornada,
          ),
        ],
      ),
      body: _carregando
          ? const Center(child: CircularProgressIndicator())
          : _jornadas.isEmpty
              ? const Center(child: Text('Nenhum modelo de jornada cadastrado.'))
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _jornadas.length,
                  itemBuilder: (context, index) {
                    final jornada = _jornadas[index];
                    return Card(
                      margin: const EdgeInsets.only(bottom: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      child: ListTile(
                        leading: const CircleAvatar(
                          backgroundColor: AppColors.primary,
                          child: Icon(Icons.timer, color: Colors.white),
                        ),
                        title: Text(
                          '${jornada.cargaHorariaSemanal} Horas Semanais',
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        subtitle: Text('ID: ${jornada.id.substring(0, 8)}...'),
                        trailing: ElevatedButton(
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => AtribuirJornadaScreen(jornada: jornada),
                              ),
                            );
                          },
                          child: const Text('Atribuir'),
                        ),
                      ),
                    );
                  },
                ),
    );
  }
}