import 'package:cloud_firestore/cloud_firestore.dart';

/// Perfil del usuario almacenado en `users/{uid}`.
///
/// El identificador del documento es siempre el UID emitido por Firebase
/// Authentication, lo que permite que las Reglas de Seguridad aíslen la
/// información con una sola condición: `request.auth.uid == uid`.
class Usuario {
  const Usuario({
    required this.uid,
    required this.nombre,
    required this.email,
    this.fotoUrl,
    this.idioma = 'es',
    this.moneda = 'MXN',
    this.creadoEn,
  });

  final String uid;
  final String nombre;
  final String email;
  final String? fotoUrl;
  final String idioma;
  final String moneda;
  final DateTime? creadoEn;

  /// Iniciales para el avatar cuando no hay fotografía.
  String get iniciales {
    final partes = nombre.trim().split(RegExp(r'\s+'));
    if (partes.isEmpty || partes.first.isEmpty) return '?';
    if (partes.length == 1) return partes.first[0].toUpperCase();
    return (partes.first[0] + partes[1][0]).toUpperCase();
  }

  factory Usuario.desdeDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final d = doc.data() ?? <String, dynamic>{};
    return Usuario(
      uid: doc.id,
      nombre: d['nombre'] as String? ?? '',
      email: d['email'] as String? ?? '',
      fotoUrl: d['fotoUrl'] as String?,
      idioma: d['idioma'] as String? ?? 'es',
      moneda: d['moneda'] as String? ?? 'MXN',
      creadoEn: (d['creadoEn'] as Timestamp?)?.toDate(),
    );
  }

  Map<String, dynamic> aMapa() => {
        'nombre': nombre.trim(),
        'email': email.trim(),
        'fotoUrl': fotoUrl,
        'idioma': idioma,
        'moneda': moneda,
      };
}
