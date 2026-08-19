import 'package:cloud_firestore/cloud_firestore.dart';

/// Destino turístico del catálogo público.
///
/// Vive en la colección raíz `destinos`, que es de solo lectura para los
/// usuarios autenticados. Las Reglas de Seguridad impiden cualquier escritura
/// desde el cliente; el catálogo se administra desde la consola de Firebase.
/// Esta diferencia de permisos se verifica en las pruebas dinámicas.
class Destino {
  const Destino({
    required this.id,
    required this.nombre,
    required this.pais,
    required this.descripcion,
    required this.categoria,
    required this.popularidad,
    this.imagenUrl,
    this.lat,
    this.lng,
  });

  final String id;
  final String nombre;
  final String pais;
  final String descripcion;
  final String categoria;
  final int popularidad;
  final String? imagenUrl;
  final double? lat;
  final double? lng;

  String get ubicacion => '$nombre, $pais';

  bool get tieneCoordenadas => lat != null && lng != null;

  factory Destino.desdeDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final d = doc.data() ?? <String, dynamic>{};
    return Destino(
      id: doc.id,
      nombre: d['nombre'] as String? ?? '',
      pais: d['pais'] as String? ?? '',
      descripcion: d['descripcion'] as String? ?? '',
      categoria: d['categoria'] as String? ?? 'ciudad',
      popularidad: (d['popularidad'] as num?)?.toInt() ?? 0,
      imagenUrl: d['imagenUrl'] as String?,
      lat: (d['lat'] as num?)?.toDouble(),
      lng: (d['lng'] as num?)?.toDouble(),
    );
  }
}
