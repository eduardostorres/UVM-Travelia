import 'package:cloud_firestore/cloud_firestore.dart';

/// Categorías de actividad del itinerario.
enum CategoriaActividad {
  transporte('transporte', 'Transporte'),
  hospedaje('hospedaje', 'Hospedaje'),
  comida('comida', 'Comida'),
  atraccion('atraccion', 'Atracción'),
  otro('otro', 'Otro');

  const CategoriaActividad(this.valor, this.etiqueta);

  final String valor;
  final String etiqueta;

  static CategoriaActividad desdeValor(String? valor) =>
      CategoriaActividad.values.firstWhere(
        (c) => c.valor == valor,
        orElse: () => CategoriaActividad.otro,
      );
}

/// Actividad programada dentro del itinerario de un viaje.
///
/// Vive en `users/{uid}/viajes/{viajeId}/actividades/{actividadId}` y
/// constituye un segundo CRUD anidado sobre el viaje.
class Actividad {
  const Actividad({
    required this.id,
    required this.titulo,
    required this.fecha,
    required this.hora,
    required this.categoria,
    required this.costo,
    this.descripcion,
    this.ubicacion,
    this.completada = false,
    this.creadoEn,
  });

  final String id;
  final String titulo;
  final DateTime fecha;
  final String hora;
  final CategoriaActividad categoria;
  final double costo;
  final String? descripcion;
  final String? ubicacion;
  final bool completada;
  final DateTime? creadoEn;

  factory Actividad.desdeDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final d = doc.data() ?? <String, dynamic>{};
    return Actividad(
      id: doc.id,
      titulo: d['titulo'] as String? ?? 'Actividad',
      fecha: (d['fecha'] as Timestamp?)?.toDate() ?? DateTime.now(),
      hora: d['hora'] as String? ?? '00:00',
      categoria: CategoriaActividad.desdeValor(d['categoria'] as String?),
      costo: (d['costo'] as num?)?.toDouble() ?? 0,
      descripcion: d['descripcion'] as String?,
      ubicacion: d['ubicacion'] as String?,
      completada: d['completada'] as bool? ?? false,
      creadoEn: (d['creadoEn'] as Timestamp?)?.toDate(),
    );
  }

  Map<String, dynamic> aMapa() => {
        'titulo': titulo.trim(),
        'fecha': Timestamp.fromDate(fecha),
        'hora': hora,
        'categoria': categoria.valor,
        'costo': costo,
        'descripcion': descripcion?.trim(),
        'ubicacion': ubicacion?.trim(),
        'completada': completada,
      };

  Actividad copiarCon({
    String? titulo,
    DateTime? fecha,
    String? hora,
    CategoriaActividad? categoria,
    double? costo,
    String? descripcion,
    String? ubicacion,
    bool? completada,
  }) {
    return Actividad(
      id: id,
      titulo: titulo ?? this.titulo,
      fecha: fecha ?? this.fecha,
      hora: hora ?? this.hora,
      categoria: categoria ?? this.categoria,
      costo: costo ?? this.costo,
      descripcion: descripcion ?? this.descripcion,
      ubicacion: ubicacion ?? this.ubicacion,
      completada: completada ?? this.completada,
      creadoEn: creadoEn,
    );
  }
}
