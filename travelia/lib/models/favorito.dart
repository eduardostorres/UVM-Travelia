import 'package:cloud_firestore/cloud_firestore.dart';

/// Tipos de lugar que el usuario puede guardar como favorito.
enum TipoFavorito {
  destino('destino', 'Destino'),
  hotel('hotel', 'Hotel'),
  restaurante('restaurante', 'Restaurante'),
  atraccion('atraccion', 'Atracción');

  const TipoFavorito(this.valor, this.etiqueta);

  final String valor;
  final String etiqueta;

  static TipoFavorito desdeValor(String? valor) =>
      TipoFavorito.values.firstWhere(
        (t) => t.valor == valor,
        orElse: () => TipoFavorito.destino,
      );
}

/// Lugar guardado por el usuario para consulta posterior.
///
/// Vive en `users/{uid}/favoritos/{favoritoId}`.
class Favorito {
  const Favorito({
    required this.id,
    required this.nombre,
    required this.tipo,
    required this.ciudad,
    required this.pais,
    this.imagenUrl,
    this.creadoEn,
  });

  final String id;
  final String nombre;
  final TipoFavorito tipo;
  final String ciudad;
  final String pais;
  final String? imagenUrl;
  final DateTime? creadoEn;

  String get ubicacion => '$ciudad, $pais';

  factory Favorito.desdeDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final d = doc.data() ?? <String, dynamic>{};
    return Favorito(
      id: doc.id,
      nombre: d['nombre'] as String? ?? '',
      tipo: TipoFavorito.desdeValor(d['tipo'] as String?),
      ciudad: d['ciudad'] as String? ?? '',
      pais: d['pais'] as String? ?? '',
      imagenUrl: d['imagenUrl'] as String?,
      creadoEn: (d['creadoEn'] as Timestamp?)?.toDate(),
    );
  }

  Map<String, dynamic> aMapa() => {
        'nombre': nombre.trim(),
        'tipo': tipo.valor,
        'ciudad': ciudad.trim(),
        'pais': pais.trim(),
        'imagenUrl': imagenUrl,
      };
}
