import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../models/usuario.dart';

/// Acceso al perfil del usuario en `users/{uid}`.
class UsuarioService {
  UsuarioService({FirebaseFirestore? db, FirebaseAuth? auth})
      : _db = db ?? FirebaseFirestore.instance,
        _auth = auth ?? FirebaseAuth.instance;

  final FirebaseFirestore _db;
  final FirebaseAuth _auth;

  String get _uid {
    final uid = _auth.currentUser?.uid;
    if (uid == null) throw Exception('Debes iniciar sesión para continuar.');
    return uid;
  }

  DocumentReference<Map<String, dynamic>> get _perfil =>
      _db.collection('users').doc(_uid);

  Stream<Usuario?> observar() {
    return _perfil.snapshots().map(
          (doc) => doc.exists ? Usuario.desdeDoc(doc) : null,
        );
  }

  Future<Usuario?> obtener() async {
    final doc = await _perfil.get();
    return doc.exists ? Usuario.desdeDoc(doc) : null;
  }

  Future<void> actualizar({
    String? nombre,
    String? idioma,
    String? moneda,
  }) async {
    final cambios = <String, dynamic>{};
    if (nombre != null) cambios['nombre'] = nombre.trim();
    if (idioma != null) cambios['idioma'] = idioma;
    if (moneda != null) cambios['moneda'] = moneda;
    if (cambios.isEmpty) return;

    await _perfil.update(cambios);

    if (nombre != null) {
      await _auth.currentUser?.updateDisplayName(nombre.trim());
    }
  }

  /// Intento de lectura del perfil de otro usuario.
  ///
  /// Usado en la prueba dinamica PD-02: las Reglas de Seguridad deben
  /// responder `permission-denied` porque el UID no coincide con el de la
  /// sesion activa.
  Future<DocumentSnapshot<Map<String, dynamic>>> intentarLeerOtroUsuario(
    String uidAjeno,
  ) {
    return _db.collection('users').doc(uidAjeno).get();
  }
}
