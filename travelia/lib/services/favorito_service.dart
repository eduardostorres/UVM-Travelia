import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../models/favorito.dart';

/// Acceso a los lugares guardados por el usuario.
///
/// Vive en `users/{uid}/favoritos`, por lo que hereda el mismo aislamiento
/// por usuario que el resto de la informacion personal.
class FavoritoService {
  FavoritoService({FirebaseFirestore? db, FirebaseAuth? auth})
      : _db = db ?? FirebaseFirestore.instance,
        _auth = auth ?? FirebaseAuth.instance;

  final FirebaseFirestore _db;
  final FirebaseAuth _auth;

  String get _uid {
    final uid = _auth.currentUser?.uid;
    if (uid == null) throw Exception('Debes iniciar sesión para continuar.');
    return uid;
  }

  CollectionReference<Map<String, dynamic>> get _favoritos =>
      _db.collection('users').doc(_uid).collection('favoritos');

  /// Escucha en tiempo real todos los favoritos del usuario.
  Stream<List<Favorito>> observar() {
    return _favoritos.snapshots().map((s) {
      final lista = s.docs.map(Favorito.desdeDoc).toList()
        ..sort((a, b) => a.nombre.compareTo(b.nombre));
      return lista;
    });
  }

  /// Escucha los favoritos de un tipo determinado.
  Stream<List<Favorito>> observarPorTipo(TipoFavorito tipo) {
    return _favoritos
        .where('tipo', isEqualTo: tipo.valor)
        .snapshots()
        .map((s) {
      final lista = s.docs.map(Favorito.desdeDoc).toList()
        ..sort((a, b) => a.nombre.compareTo(b.nombre));
      return lista;
    });
  }

  Future<String> agregar(Favorito favorito) async {
    final ref = await _favoritos.add({
      ...favorito.aMapa(),
      'creadoEn': FieldValue.serverTimestamp(),
    });
    return ref.id;
  }

  Future<void> eliminar(String id) => _favoritos.doc(id).delete();

  /// Indica si un lugar ya esta guardado, comparando por nombre y ciudad.
  Future<String?> idSiExiste(String nombre, String ciudad) async {
    final s = await _favoritos
        .where('nombre', isEqualTo: nombre.trim())
        .where('ciudad', isEqualTo: ciudad.trim())
        .limit(1)
        .get();
    return s.docs.isEmpty ? null : s.docs.first.id;
  }
}
