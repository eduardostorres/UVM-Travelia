import 'package:cloud_firestore/cloud_firestore.dart';

/// Estados posibles de un viaje dentro de Travelia.
enum EstadoViaje {
  proximo('proximo', 'Próximo'),
  enCurso('en_curso', 'En curso'),
  finalizado('finalizado', 'Finalizado');

  const EstadoViaje(this.valor, this.etiqueta);

  /// Valor almacenado en Firestore.
  final String valor;

  /// Texto mostrado al usuario.
  final String etiqueta;

  static EstadoViaje desdeValor(String? valor) => EstadoViaje.values.firstWhere(
        (e) => e.valor == valor,
        orElse: () => EstadoViaje.proximo,
      );
}

/// Representa un viaje del usuario.
///
/// Es la entidad principal sobre la que se demuestran las cuatro operaciones
/// del CRUD requeridas en la Etapa 3 del Proyecto Integrador. Cada documento
/// vive en `users/{uid}/viajes/{viajeId}`, de modo que la información queda
/// aislada por usuario.
class Viaje {
  const Viaje({
    required this.id,
    required this.titulo,
    required this.destino,
    required this.pais,
    required this.fechaInicio,
    required this.fechaFin,
    required this.presupuesto,
    required this.moneda,
    required this.estado,
    this.notas,
    this.imagenUrl,
    this.creadoEn,
    this.actualizadoEn,
  });

  final String id;
  final String titulo;
  final String destino;
  final String pais;
  final DateTime fechaInicio;
  final DateTime fechaFin;
  final double presupuesto;
  final String moneda;
  final EstadoViaje estado;
  final String? notas;
  final String? imagenUrl;
  final DateTime? creadoEn;
  final DateTime? actualizadoEn;

  /// Duración del viaje en días, contando el día de inicio.
  int get duracionDias => fechaFin.difference(fechaInicio).inDays + 1;

  /// Texto legible del destino, por ejemplo "Tokio, Japón".
  String get destinoCompleto => '$destino, $pais';

  /// Construye un [Viaje] a partir de un documento de Firestore.
  factory Viaje.desdeDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final d = doc.data() ?? <String, dynamic>{};
    return Viaje(
      id: doc.id,
      titulo: d['titulo'] as String? ?? 'Viaje sin título',
      destino: d['destino'] as String? ?? '',
      pais: d['pais'] as String? ?? '',
      fechaInicio: _aFecha(d['fechaInicio']) ?? DateTime.now(),
      fechaFin: _aFecha(d['fechaFin']) ?? DateTime.now(),
      presupuesto: (d['presupuesto'] as num?)?.toDouble() ?? 0,
      moneda: d['moneda'] as String? ?? 'MXN',
      estado: EstadoViaje.desdeValor(d['estado'] as String?),
      notas: d['notas'] as String?,
      imagenUrl: d['imagenUrl'] as String?,
      creadoEn: _aFecha(d['creadoEn']),
      actualizadoEn: _aFecha(d['actualizadoEn']),
    );
  }

  /// Serializa el viaje para escribirlo en Firestore.
  ///
  /// Se omiten `id`, `creadoEn` y `actualizadoEn` porque el identificador lo
  /// asigna Firestore y las marcas de tiempo las coloca el servicio con
  /// [FieldValue.serverTimestamp].
  Map<String, dynamic> aMapa() => {
        'titulo': titulo.trim(),
        'destino': destino.trim(),
        'pais': pais.trim(),
        'fechaInicio': Timestamp.fromDate(fechaInicio),
        'fechaFin': Timestamp.fromDate(fechaFin),
        'presupuesto': presupuesto,
        'moneda': moneda,
        'estado': estado.valor,
        'notas': notas?.trim(),
        'imagenUrl': imagenUrl,
      };

  Viaje copiarCon({
    String? id,
    String? titulo,
    String? destino,
    String? pais,
    DateTime? fechaInicio,
    DateTime? fechaFin,
    double? presupuesto,
    String? moneda,
    EstadoViaje? estado,
    String? notas,
    String? imagenUrl,
  }) {
    return Viaje(
      id: id ?? this.id,
      titulo: titulo ?? this.titulo,
      destino: destino ?? this.destino,
      pais: pais ?? this.pais,
      fechaInicio: fechaInicio ?? this.fechaInicio,
      fechaFin: fechaFin ?? this.fechaFin,
      presupuesto: presupuesto ?? this.presupuesto,
      moneda: moneda ?? this.moneda,
      estado: estado ?? this.estado,
      notas: notas ?? this.notas,
      imagenUrl: imagenUrl ?? this.imagenUrl,
      creadoEn: creadoEn,
      actualizadoEn: actualizadoEn,
    );
  }

  /// Viaje vacío usado como valor inicial del formulario de alta.
  factory Viaje.nuevo() {
    final hoy = DateTime.now();
    return Viaje(
      id: '',
      titulo: '',
      destino: '',
      pais: '',
      fechaInicio: hoy,
      fechaFin: hoy.add(const Duration(days: 6)),
      presupuesto: 0,
      moneda: 'MXN',
      estado: EstadoViaje.proximo,
    );
  }

  static DateTime? _aFecha(dynamic valor) {
    if (valor is Timestamp) return valor.toDate();
    if (valor is DateTime) return valor;
    return null;
  }
}
