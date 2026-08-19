/// Validaciones de entrada de la aplicación.
///
/// La validación se aplica en tres niveles: en el formulario (esta clase),
/// en el servicio antes de escribir y en las Reglas de Seguridad de Cloud
/// Firestore. Este enfoque en capas evita depender únicamente del cliente,
/// que puede ser modificado por un atacante.
class Validadores {
  Validadores._();

  static final RegExp _correo = RegExp(
    r'^[\w.\-+]+@([\w\-]+\.)+[a-zA-Z]{2,}$',
  );

  /// Longitud máxima aceptada por las Reglas de Seguridad para el título.
  static const int maxTitulo = 100;

  static String? correo(String? valor) {
    final v = valor?.trim() ?? '';
    if (v.isEmpty) return 'Ingresa tu correo electrónico';
    if (v.length > 254) return 'El correo es demasiado largo';
    if (!_correo.hasMatch(v)) return 'El formato del correo no es válido';
    return null;
  }

  static String? contrasena(String? valor) {
    final v = valor ?? '';
    if (v.isEmpty) return 'Ingresa tu contraseña';
    if (v.length < 8) return 'Debe tener al menos 8 caracteres';
    if (v.length > 128) return 'La contraseña es demasiado larga';
    if (!v.contains(RegExp(r'[A-Za-z]'))) return 'Debe incluir al menos una letra';
    if (!v.contains(RegExp(r'[0-9]'))) return 'Debe incluir al menos un número';
    return null;
  }

  static String? confirmacion(String? valor, String original) {
    if ((valor ?? '').isEmpty) return 'Confirma tu contraseña';
    if (valor != original) return 'Las contraseñas no coinciden';
    return null;
  }

  static String? nombre(String? valor) {
    final v = valor?.trim() ?? '';
    if (v.isEmpty) return 'Ingresa tu nombre';
    if (v.length < 3) return 'Debe tener al menos 3 caracteres';
    if (v.length > 60) return 'El nombre es demasiado largo';
    return null;
  }

  static String? obligatorio(String? valor, String campo, {int max = 100}) {
    final v = valor?.trim() ?? '';
    if (v.isEmpty) return 'Ingresa $campo';
    if (v.length > max) return 'Máximo $max caracteres';
    return null;
  }

  /// Valida un importe monetario. Las Reglas de Seguridad rechazan negativos.
  static String? monto(String? valor, {bool obligatorio = true}) {
    final v = valor?.trim().replaceAll(',', '') ?? '';
    if (v.isEmpty) return obligatorio ? 'Ingresa un monto' : null;
    final n = double.tryParse(v);
    if (n == null) return 'Ingresa un número válido';
    if (n < 0) return 'El monto no puede ser negativo';
    if (n > 99999999) return 'El monto es demasiado alto';
    return null;
  }
}
