class Fmt {
  static const meses = ['Janeiro','Fevereiro','Março','Abril','Maio','Junho',
    'Julho','Agosto','Setembro','Outubro','Novembro','Dezembro'];

  static String _2(int n) => n.toString().padLeft(2, '0');
  static String data(DateTime d) => '${_2(d.day)}/${_2(d.month)}/${d.year}';
  static String hora(DateTime d) { final l = d.toLocal(); return '${_2(l.hour)}:${_2(l.minute)}'; }

  static String minutos(int total, {bool sinal = false, String sep = 'h', String zero = '00h00'}) {
    if (total == 0) return zero;
    final abs = total.abs();
    final s = sinal ? (total < 0 ? '-' : '+') : '';
    return '$s${_2(abs ~/ 60)}$sep${_2(abs % 60)}';
  }
}