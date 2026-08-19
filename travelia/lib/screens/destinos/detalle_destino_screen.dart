import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../models/destino.dart';
import '../../models/favorito.dart';
import '../../services/favorito_service.dart';

/// Ficha de un destino del catalogo.
///
/// Permite guardarlo en favoritos y abrir su ubicacion en la aplicacion de
/// mapas del sistema. Se resolvio asi en lugar de incrustar Google Maps
/// porque el SDK requiere una clave con facturacion activa, fuera del
/// alcance de este proyecto academico.
class DetalleDestinoScreen extends StatefulWidget {
  const DetalleDestinoScreen({super.key, required this.destino});

  final Destino destino;

  @override
  State<DetalleDestinoScreen> createState() => _DetalleDestinoScreenState();
}

class _DetalleDestinoScreenState extends State<DetalleDestinoScreen> {
  final _favoritos = FavoritoService();

  String? _idFavorito;
  bool _cargando = true;

  @override
  void initState() {
    super.initState();
    _revisarFavorito();
  }

  Future<void> _revisarFavorito() async {
    try {
      final id = await _favoritos.idSiExiste(
        widget.destino.nombre,
        widget.destino.nombre,
      );
      if (mounted) {
        setState(() {
          _idFavorito = id;
          _cargando = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _cargando = false);
    }
  }

  Future<void> _alternarFavorito() async {
    setState(() => _cargando = true);
    try {
      if (_idFavorito != null) {
        await _favoritos.eliminar(_idFavorito!);
        if (mounted) {
          setState(() => _idFavorito = null);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Se quitó de favoritos')),
          );
        }
      } else {
        final id = await _favoritos.agregar(
          Favorito(
            id: '',
            nombre: widget.destino.nombre,
            tipo: TipoFavorito.destino,
            ciudad: widget.destino.nombre,
            pais: widget.destino.pais,
          ),
        );
        if (mounted) {
          setState(() => _idFavorito = id);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Guardado en favoritos')),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('No se pudo completar: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _cargando = false);
    }
  }

  Future<void> _abrirEnMapas() async {
    final d = widget.destino;
    final consulta = d.tieneCoordenadas
        ? '${d.lat},${d.lng}'
        : Uri.encodeComponent('${d.nombre}, ${d.pais}');
    final uri = Uri.parse('geo:0,0?q=$consulta');

    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No hay una aplicación de mapas disponible'),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final d = widget.destino;
    final esquema = Theme.of(context).colorScheme;
    final textos = Theme.of(context).textTheme;
    final esFavorito = _idFavorito != null;

    return Scaffold(
      appBar: AppBar(
        title: Text(d.nombre),
        actions: [
          IconButton(
            tooltip: esFavorito ? 'Quitar de favoritos' : 'Guardar en favoritos',
            onPressed: _cargando ? null : _alternarFavorito,
            icon: Icon(
              esFavorito ? Icons.favorite : Icons.favorite_outline,
              color: esFavorito ? esquema.error : null,
            ),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
        children: [
          Container(
            height: 176,
            decoration: BoxDecoration(
              color: esquema.primaryContainer,
              borderRadius: BorderRadius.circular(18),
            ),
            child: Icon(
              Icons.photo_camera_back_outlined,
              size: 52,
              color: esquema.onPrimaryContainer.withValues(alpha: 0.55),
            ),
          ),
          const SizedBox(height: 20),

          Text(
            d.nombre,
            style: textos.headlineSmall?.copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              Icon(Icons.public, size: 16, color: esquema.onSurfaceVariant),
              const SizedBox(width: 6),
              Text(
                d.pais,
                style: TextStyle(color: esquema.onSurfaceVariant),
              ),
              const SizedBox(width: 14),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: esquema.tertiary.withValues(alpha: 0.16),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  d.categoria,
                  style: TextStyle(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w600,
                    color: esquema.tertiary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),

          if (d.descripcion.isNotEmpty) ...[
            Text('Descripción',
                style: textos.titleSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                )),
            const SizedBox(height: 6),
            Text(d.descripcion, style: textos.bodyMedium),
            const SizedBox(height: 22),
          ],

          FilledButton.icon(
            onPressed: _abrirEnMapas,
            icon: const Icon(Icons.map_outlined),
            label: const Text('Ver en el mapa'),
          ),
          const SizedBox(height: 10),
          OutlinedButton.icon(
            onPressed: _cargando ? null : _alternarFavorito,
            icon: Icon(
              esFavorito ? Icons.favorite : Icons.favorite_outline,
            ),
            label: Text(
              esFavorito ? 'Quitar de favoritos' : 'Guardar en favoritos',
            ),
          ),
        ],
      ),
    );
  }
}
