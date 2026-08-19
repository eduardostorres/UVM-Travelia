/// Utilidades de formato para fechas y montos.
///
/// Se implementan de forma explícita en español para no depender de la carga
/// de datos de localización en tiempo de ejecución, lo que mantiene el APK
/// más pequeño y evita fallos de formato en dispositivos con otra región.
class Formato {
  Formato._();

  static const List<String> _meses = [
    'enero', 'febrero', 'marzo', 'abril', 'mayo', 'junio',
    'julio', 'agosto', 'septiembre', 'octubre', 'noviembre', 'diciembre',
  ];

  static const List<String> _mesesCortos = [
    'ene', 'feb', 'mar', 'abr', 'may', 'jun',
    'jul', 'ago', 'sep', 'oct', 'nov', 'dic',
  ];

  static const List<String> _dias = [
    'lunes', 'martes', 'miércoles', 'jueves', 'viernes', 'sábado', 'domingo',
  ];

  /// Ejemplo: `15 de octubre de 2026`
  static String fechaLarga(DateTime f) =>
      '${f.day} de ${_meses[f.month - 1]} de ${f.year}';

  /// Ejemplo: `15 oct 2026`
  static String fechaCorta(DateTime f) =>
      '${f.day} ${_mesesCortos[f.month - 1]} ${f.year}';

  /// Ejemplo: `jueves 15 de octubre`
  static String fechaConDia(DateTime f) =>
      '${_dias[f.weekday - 1]} ${f.day} de ${_meses[f.month - 1]}';

  /// Ejemplo: `15 oct – 25 oct 2026`
  static String rango(DateTime inicio, DateTime fin) {
    if (inicio.year == fin.year) {
      return '${inicio.day} ${_mesesCortos[inicio.month - 1]} – '
          '${fin.day} ${_mesesCortos[fin.month - 1]} ${fin.year}';
    }
    return '${fechaCorta(inicio)} – ${fechaCorta(fin)}';
  }

  /// Ejemplo: `$45,000.00 MXN`
  static String dinero(double monto, String moneda) {
    final partes = monto.toStringAsFixed(2).split('.');
    final enteros = partes[0];
    final buffer = StringBuffer();
    for (int i = 0; i < enteros.length; i++) {
      if (i > 0 && (enteros.length - i) % 3 == 0) buffer.write(',');
      buffer.write(enteros[i]);
    }
    return '\$$buffer.${partes[1]} $moneda';
  }

  /// Días que faltan para una fecha, en texto legible.
  static String cuentaRegresiva(DateTime fecha) {
    final hoy = DateTime.now();
    final dias = DateTime(fecha.year, fecha.month, fecha.day)
        .difference(DateTime(hoy.year, hoy.month, hoy.day))
        .inDays;

    if (dias < 0) return 'Finalizado';
    if (dias == 0) return 'Comienza hoy';
    if (dias == 1) return 'Falta 1 día';
    if (dias < 30) return 'Faltan $dias días';
    final meses = (dias / 30).floor();
    return meses == 1 ? 'Falta 1 mes' : 'Faltan $meses meses';
  }
}
