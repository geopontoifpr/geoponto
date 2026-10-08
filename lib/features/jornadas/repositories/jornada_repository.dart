import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/jornada_trabalho_model.dart';
import '../models/jornada_usuario_model.dart';

class JornadaRepository {
  final SupabaseClient _supabase;

  JornadaRepository(this._supabase);

  Future<JornadaTrabalhoModel> cadastrarJornada(int cargaHorariaSemanal) async {
    try {
      final response = await _supabase
          .from('jornadas_trabalho')
          .insert({'carga_horaria_sem': cargaHorariaSemanal})
          .select()
          .single();

      return JornadaTrabalhoModel.fromJson(response);
    } catch (e) {
      throw Exception('Erro ao cadastrar jornada de trabalho: $e');
    }
  }

  Future<List<JornadaTrabalhoModel>> listarJornadas() async {
    try {
      final response = await _supabase
          .from('jornadas_trabalho')
          .select()
          .order('carga_horaria_sem', ascending: true);

      return (response as List)
          .map((json) => JornadaTrabalhoModel.fromJson(json))
          .toList();
    } catch (e) {
      throw Exception('Erro ao listar jornadas de trabalho: $e');
    }
  }

  Future<JornadaUsuarioModel> atribuirJornada(JornadaUsuarioModel vinculacao) async {
    try {
      final response = await _supabase
          .from('jornadas_usuarios')
          .insert(vinculacao.toJson())
          .select()
          .single();

      return JornadaUsuarioModel.fromJson(response);
    } catch (e) {
      throw Exception('Erro ao atribuir jornada ao usuário: $e');
    }
  }
}