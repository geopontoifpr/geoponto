class FeriadosUtil {
  /// Retorna o nome do feriado se a data for feriado, ou null caso não seja.
  static String? obterFeriado(DateTime data) {
    final fixos = {
      '01-01': 'Confraternização Universal',
      '21-04': 'Tiradentes',
      '01-05': 'Dia do Trabalhador',
      '10-06': 'Aniversário de Foz do Iguaçu',
      '24-06': 'Padroeiro São João Batista',
      '07-09': 'Independência do Brasil',
      '12-10': 'Nossa Sr.ª Aparecida',
      '02-11': 'Finados',
      '15-11': 'Proclamação da República',
      '25-12': 'Natal',
    };

    final chaveFixa = '${data.day.toString().padLeft(2, '0')}-${data.month.toString().padLeft(2, '0')}';
    if (fixos.containsKey(chaveFixa)) return fixos[chaveFixa];

    final pascoa = _calcularPascoa(data.year);
    final sextaSanta = pascoa.subtract(const Duration(days: 2));
    final carnaval = pascoa.subtract(const Duration(days: 47));
    final corpusChristi = pascoa.add(const Duration(days: 60));

    if (_mesmoDia(data, sextaSanta)) return 'Sexta-feira Santa';
    if (_mesmoDia(data, carnaval)) return 'Carnaval';
    if (_mesmoDia(data, corpusChristi)) return 'Corpus Christi';

    return null;
  }

  static bool isFimDeSemanaOuFeriado(DateTime data) {
    if (data.weekday == DateTime.saturday || data.weekday == DateTime.sunday) return true;
    return obterFeriado(data) != null;
  }

  static bool _mesmoDia(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  /// Algoritmo de Meeus/Jones/Butcher para calcular a Páscoa
  static DateTime _calcularPascoa(int ano) {
    final a = ano % 19;
    final b = ano ~/ 100;
    final c = ano % 100;
    final d = b ~/ 4;
    final e = b % 4;
    final f = (b + 8) ~/ 25;
    final g = (b - f + 1) ~/ 3;
    final h = (19 * a + b - d - g + 15) % 30;
    final i = c ~/ 4;
    final k = c % 4;
    final l = (32 + 2 * e + 2 * i - h - k) % 7;
    final m = (a + 11 * h + 22 * l) ~/ 451;
    final mes = (h + l - 7 * m + 114) ~/ 31;
    final dia = ((h + l - 7 * m + 114) % 31) + 1;
    return DateTime(ano, mes, dia);
  }
}