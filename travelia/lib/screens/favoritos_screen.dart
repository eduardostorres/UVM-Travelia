import 'package:flutter/material.dart';

import '../models/favorito.dart';
import '../services/favorito_service.dart';
import '../utils/formato.dart';

/// Lugares guardados por el usuario.
///
/// Demuestra las operaciones Recuperar y Eliminar sobre la coleccion
/// `users/{uid}/favoritos`.
class FavoritosScreen extends StatefulWidget {
  const FavoritosScreen({super.key});

  @override
  State<FavoritosScreen> createState() => _FavoritosScreenState();
}

class _FavoritosScreenState extends State<FavoritosScreen> {
  final _servicio = FavoritoService();
  TipoFavorito? _filtro;

  IconData _icono(TipoFavorito tipo) {
    switch (tipo) {
      case TipoFavorito.destino:
        return Icons.place_outlined;
      case TipoFavorito.hotel:
        return Icons.hotel_outlined;
      case TipoFavorito.restaurante:
        return Icons.restaurant_outlined;
      case TipoFavorito.atraccion:
        return Icons.attractions_outlined;
    }
  }

  Future<void> _eliminar(Favorito favorito) async {
    final confirmado = await showDialog<bool>(
      context: context,
      builder: (c) => AlertDialog(
        title: const Text('Quitar de favoritos'),
        content: Text('¿Quitar "${favorito.nombre}" de tus favoritos?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(c).pop(false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(c).colorScheme.error,
            ),
            onPressed: () => Navigator.of(c).pop(true),
            child: const Text('Quitar'),
          ),
        ],
      ),
    );

    if (confirmado != true) return;

    try {
      await _servicio.eliminar(favorito.id);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Se quitó "${favorito.nombre}"')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('No se pudo quitar: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final esquema = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Favoritos'),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(56),
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Row(
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: FilterChip(
                    label: const Text('Todos'),
                    selected: _filtro == null,
                    onSelected: (_) => setState(() => _filtro = null),
                  ),
                ),
                for (final t in TipoFavorito.values)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: FilterChip(
                      label: Text(t.etiqueta),
                      selected: _filtro == t,
                      onSelected: (_) => setState(
                        () => _filtro = _filtro == t ? null : t,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
      body: StreamBuilder<List<Favorito>>(
        stream: _filtro == null
            ? _servicio.observar()
            : _servicio.observarPorTipo(_filtro!),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Text('No se pudo cargar: ${snapshot.error}'),
              ),
            );
          }

          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final favoritos = snapshot.data ?? const <Favorito>[];

          if (favoritos.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(34),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.favorite_border,
                      size: 62,
                      color: esquema.onSurfaceVariant,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      _filtro == null
                          ? 'Aún no tienes favoritos'
                          : 'Sin favoritos en "${_filtro!.etiqueta}"',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Guarda destinos desde el explorador para tenerlos '
                      'siempre a la mano.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: esquema.onSurfaceVariant,
                        fontSize: 13.5,
                      ),
                    ),
                  ],
                ),
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
            itemCount: favoritos.length,
            itemBuilder: (context, i) {
              final f = favoritos[i];
              return Card(
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: esquema.primaryContainer,
                    child: Icon(
                      _icono(f.tipo),
                      color: esquema.onPrimaryContainer,
                      size: 20,
                    ),
                  ),
                  title: Text(
                    f.nombre,
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                  subtitle: Text(
                    '${f.tipo.etiqueta} · ${f.pais}'
                    '${f.creadoEn != null ? ' · ${Formato.fechaCorta(f.creadoEn!)}' : ''}',
                    style: const TextStyle(fontSize: 12.5),
                  ),
                  trailing: IconButton(
                    tooltip: 'Quitar',
                    icon: Icon(Icons.delete_outline, color: esquema.error),
                    onPressed: () => _eliminar(f),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
