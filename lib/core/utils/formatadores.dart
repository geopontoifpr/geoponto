class Formatadores {
  static const meses = [
    'Janeiro', 'Fevereiro', 'Março', 'Abril', 'Maio', 'Junho',
    'Julho', 'Agosto', 'Setembro', 'Outubro', 'Novembro', 'Dezembro'
  ];
  static String _2(int n) => n.toString().padLeft(2, '0');

  static String data(DateTime d) => '${_2(d.day)}/${_2(d.month)}/${d.year}';
  static String hora(DateTime d) { final l = d.toLocal(); return '${_2(l.hour)}:${_2(l.minute)}'; }
  static String dataIso(DateTime d) => '${d.year}-${_2(d.month)}-${_2(d.day)}';   // p/ o banco
  static String mesReferencia(int ano, int mes) => '$ano-${_2(mes)}-01';          // p/ fechamentos

  static String minutos(int total, {bool mostrarSinal = false, String sep = 'h', String zero = '00h00'}) {
    if (total == 0) return zero;
    final s = mostrarSinal ? (total < 0 ? '-' : '+') : '';
    return '$s${_2(total.abs() ~/ 60)}$sep${_2(total.abs() % 60)}';
  }
}