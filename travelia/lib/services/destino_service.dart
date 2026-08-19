import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/destino.dart';

/// Acceso al catalogo publico de destinos.
///
/// A diferencia del resto de los servicios, esta coleccion es compartida por
/// todos los usuarios y las Reglas de Seguridad la declaran de **solo
/// lectura**: cualquier intento de escritura desde la aplicacion es
/// rechazado por el servidor. Esa diferencia de permisos se verifica en las
/// pruebas dinamicas de la Etapa 3.
class DestinoService {
  DestinoService({FirebaseFirestore? db})
      : _db = db ?? FirebaseFirestore.instance;

  final FirebaseFirestore _db;

  CollectionReference<Map<String, dynamic>> get _destinos =>
      _db.collection('destinos');

  /// Escucha el catalogo completo, ordenado por popularidad.
  Stream<List<Destino>> observar() {
    return _destinos.snapshots().map((s) {
      final lista = s.docs.map(Destino.desdeDoc).toList()
        ..sort((a, b) => b.popularidad.compareTo(a.popularidad));
      return lista;
    });
  }

  Future<Destino?> obtener(String id) async {
    final doc = await _destinos.doc(id).get();
    return doc.exists ? Destino.desdeDoc(doc) : null;
  }

  /// Intento de escritura usado unicamente en las pruebas de seguridad.
  ///
  /// Las Reglas de Seguridad deben rechazarlo con `permission-denied`. Se
  /// conserva en el codigo porque documenta la prueba PD-04 del plan.
  Future<void> intentarEscritura() {
    return _destinos.add({
      'nombre': 'Destino de prueba',
      'pais': 'Prueba',
      'descripcion': 'Escritura que las reglas deben rechazar',
      'categoria': 'ciudad',
      'popularidad': 0,
    });
  }
}
