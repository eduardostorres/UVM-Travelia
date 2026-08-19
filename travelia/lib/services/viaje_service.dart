import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../models/actividad.dart';
import '../models/viaje.dart';

/// Error de dominio con mensaje legible para la interfaz.
class ViajeException implements Exception {
  const ViajeException(this.mensaje);
  final String mensaje;

  @override
  String toString() => mensaje;
}

/// Acceso a los viajes del usuario en Cloud Firestore.
///
/// Implementa las cuatro operaciones del CRUD exigidas en el punto 3.1 de la
/// Etapa 3 sobre la ruta `users/{uid}/viajes`:
///
/// | Operación  | Método            | API de Firestore |
/// |------------|-------------------|------------------|
/// | Agregar    | [agregar]         | `add()`          |
/// | Recuperar  | [observar], [obtener] | `snapshots()`, `get()` |
/// | Actualizar | [actualizar]      | `update()`       |
/// | Eliminar   | [eliminar]        | `delete()`       |
///
/// Todas las rutas se construyen a partir del UID de la sesión activa, de modo
/// que resulta imposible que el cliente consulte datos de otro usuario aunque
/// se manipule la interfaz. Las Reglas de Seguridad refuerzan esa misma
/// restricción del lado del servidor.
class ViajeService {
  ViajeService({FirebaseFirestore? db, FirebaseAuth? auth})
      : _db = db ?? FirebaseFirestore.instance,
        _auth = auth ?? FirebaseAuth.instance;

  final FirebaseFirestore _db;
  final FirebaseAuth _auth;

  String get _uid {
    final uid = _auth.currentUser?.uid;
    if (uid == null) {
      throw const ViajeException('Debes iniciar sesión para continuar.');
    }
    return uid;
  }

  CollectionReference<Map<String, dynamic>> get _viajes =>
      _db.collection('users').doc(_uid).collection('viajes');

  CollectionReference<Map<String, dynamic>> _actividades(String viajeId) =>
      _viajes.doc(viajeId).collection('actividades');

  // ------------------------------------------------------------------
  // RECUPERAR
  // ------------------------------------------------------------------

  /// Escucha en tiempo real todos los viajes del usuario.
  ///
  /// Se usa en la pantalla "Mis viajes": cualquier alta, edición o borrado se
  /// refleja de inmediato sin recargar manualmente.
  Stream<List<Viaje>> observar() {
    return _viajes
        .orderBy('fechaInicio', descending: false)
        .snapshots()
        .map((s) => s.docs.map(Viaje.desdeDoc).toList());
  }

  /// Escucha únicamente los viajes que estén en un estado determinado.
  Stream<List<Viaje>> observarPorEstado(EstadoViaje estado) {
    return _viajes
        .where('estado', isEqualTo: estado.valor)
        .snapshots()
        .map((s) {
      final lista = s.docs.map(Viaje.desdeDoc).toList()
        ..sort((a, b) => a.fechaInicio.compareTo(b.fechaInicio));
      return lista;
    });
  }

  /// Recupera un viaje puntual por su identificador.
  Future<Viaje?> obtener(String id) async {
    try {
      final doc = await _viajes.doc(id).get();
      if (!doc.exists) return null;
      return Viaje.desdeDoc(doc);
    } on FirebaseException catch (e) {
      throw ViajeException(_traducir(e.code));
    }
  }

  // ------------------------------------------------------------------
  // AGREGAR
  // ------------------------------------------------------------------

  /// Da de alta un viaje y devuelve el identificador asignado por Firestore.
  ///
  /// Las marcas de tiempo se generan con [FieldValue.serverTimestamp] para que
  /// dependan del reloj del servidor y no del dispositivo, que es manipulable.
  Future<String> agregar(Viaje viaje) async {
    try {
      final ref = await _viajes.add({
        ...viaje.aMapa(),
        'creadoEn': FieldValue.serverTimestamp(),
        'actualizadoEn': FieldValue.serverTimestamp(),
      });
      return ref.id;
    } on FirebaseException catch (e) {
      throw ViajeException(_traducir(e.code));
    }
  }

  // ------------------------------------------------------------------
  // ACTUALIZAR
  // ------------------------------------------------------------------

  /// Modifica los datos de un viaje existente.
  Future<void> actualizar(Viaje viaje) async {
    if (viaje.id.isEmpty) {
      throw const ViajeException('El viaje no tiene un identificador válido.');
    }
    try {
      await _viajes.doc(viaje.id).update({
        ...viaje.aMapa(),
        'actualizadoEn': FieldValue.serverTimestamp(),
      });
    } on FirebaseException catch (e) {
      throw ViajeException(_traducir(e.code));
    }
  }

  /// Cambia únicamente el estado del viaje.
  Future<void> cambiarEstado(String id, EstadoViaje estado) async {
    try {
      await _viajes.doc(id).update({
        'estado': estado.valor,
        'actualizadoEn': FieldValue.serverTimestamp(),
      });
    } on FirebaseException catch (e) {
      throw ViajeException(_traducir(e.code));
    }
  }

  // ------------------------------------------------------------------
  // ELIMINAR
  // ------------------------------------------------------------------

  /// Elimina un viaje junto con todas sus actividades.
  ///
  /// Firestore no borra subcolecciones en cascada, por lo que las actividades
  /// se eliminan explícitamente dentro de un lote atómico para no dejar
  /// documentos huérfanos ocupando espacio e inaccesibles desde la interfaz.
  Future<void> eliminar(String id) async {
    try {
      final actividades = await _actividades(id).get();
      final lote = _db.batch();
      for (final doc in actividades.docs) {
        lote.delete(doc.reference);
      }
      lote.delete(_viajes.doc(id));
      await lote.commit();
    } on FirebaseException catch (e) {
      throw ViajeException(_traducir(e.code));
    }
  }

  // ------------------------------------------------------------------
  // ACTIVIDADES DEL ITINERARIO (CRUD anidado)
  // ------------------------------------------------------------------

  Stream<List<Actividad>> observarActividades(String viajeId) {
    return _actividades(viajeId).snapshots().map((s) {
      final lista = s.docs.map(Actividad.desdeDoc).toList()
        ..sort((a, b) {
          final porFecha = a.fecha.compareTo(b.fecha);
          return porFecha != 0 ? porFecha : a.hora.compareTo(b.hora);
        });
      return lista;
    });
  }

  Future<String> agregarActividad(String viajeId, Actividad actividad) async {
    try {
      final ref = await _actividades(viajeId).add({
        ...actividad.aMapa(),
        'creadoEn': FieldValue.serverTimestamp(),
      });
      return ref.id;
    } on FirebaseException catch (e) {
      throw ViajeException(_traducir(e.code));
    }
  }

  Future<void> actualizarActividad(String viajeId, Actividad actividad) async {
    try {
      await _actividades(viajeId).doc(actividad.id).update(actividad.aMapa());
    } on FirebaseException catch (e) {
      throw ViajeException(_traducir(e.code));
    }
  }

  Future<void> eliminarActividad(String viajeId, String actividadId) async {
    try {
      await _actividades(viajeId).doc(actividadId).delete();
    } on FirebaseException catch (e) {
      throw ViajeException(_traducir(e.code));
    }
  }

  /// Suma el costo de todas las actividades registradas en un viaje.
  Future<double> gastoRegistrado(String viajeId) async {
    final s = await _actividades(viajeId).get();
    return s.docs.fold<double>(
      0,
      (total, d) => total + ((d.data()['costo'] as num?)?.toDouble() ?? 0),
    );
  }

  /// Traduce los códigos de Firestore a mensajes en español.
  String _traducir(String codigo) {
    switch (codigo) {
      case 'permission-denied':
        return 'No tienes permiso para realizar esta operación.';
      case 'unavailable':
        return 'Sin conexión con el servidor. Revisa tu internet.';
      case 'not-found':
        return 'El registro ya no existe.';
      case 'deadline-exceeded':
        return 'La operación tardó demasiado. Inténtalo de nuevo.';
      case 'resource-exhausted':
        return 'Se alcanzó el límite de operaciones. Espera un momento.';
      default:
        return 'Ocurrió un error al comunicarse con la base de datos.';
    }
  }
}
