class Formatadores {
  static const meses = [
    'Janeiro', 'Fevereiro', 'Março', 'Abril', 'Maio', 'Junho',
    'Julho', 'Agosto', 'Setembro', 'Outubro', 'Novembro', 'Dezembro'
  ];
  static String _dois(int n) => n.toString().padLeft(2, '0');

  static String data(DateTime d) => '${_dois(d.day)}/${_dois(d.month)}/${d.year}';
  static String hora(DateTime d) { final l = d.toLocal(); return '${_dois(l.hour)}:${_dois(l.minute)}'; }
  static String dataIso(DateTime d) => '${d.year}-${_dois(d.month)}-${_dois(d.day)}';   // p/ o banco
  static String mesReferencia(int ano, int mes) => '$ano-${_dois(mes)}-01';          // p/ fechamentos

  static String minutos(int total, {bool mostrarSinal = false, String sep = 'h', String zero = '00h00'}) {
    if (total == 0) return zero;
    final s = mostrarSinal ? (total < 0 ? '-' : '+') : '';
    return '$s${_dois(total.abs() ~/ 60)}$sep${_dois(total.abs() % 60)}';
  }
}