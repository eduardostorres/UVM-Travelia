import 'package:flutter/material.dart';

import '../../models/destino.dart';
import '../../services/destino_service.dart';
import 'detalle_destino_screen.dart';

/// Explorador de destinos.
///
/// Lee la coleccion publica `destinos`, compartida por todos los usuarios.
/// El filtrado y el orden se resuelven en el cliente para no exigir indices
/// compuestos en Firestore, que en el plan gratuito deben crearse a mano.
class ExploradorScreen extends StatefulWidget {
  const ExploradorScreen({super.key});

  @override
  State<ExploradorScreen> createState() => _ExploradorScreenState();
}

class _ExploradorScreenState extends State<ExploradorScreen> {
  final _servicio = DestinoService();
  final _busqueda = TextEditingController();

  String _texto = '';
  String? _categoria;

  static const Map<String, String> _categorias = {
    'playa': 'Playa',
    'ciudad': 'Ciudad',
    'montana': 'Montaña',
    'cultural': 'Cultural',
  };

  @override
  void dispose() {
    _busqueda.dispose();
    super.dispose();
  }

  List<Destino> _filtrar(List<Destino> destinos) {
    final texto = _texto.trim().toLowerCase();
    return destinos.where((d) {
      final coincideTexto = texto.isEmpty ||
          d.nombre.toLowerCase().contains(texto) ||
          d.pais.toLowerCase().contains(texto);
      final coincideCategoria = _categoria == null || d.categoria == _categoria;
      return coincideTexto && coincideCategoria;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final esquema = Theme.of(context).colorScheme;
    final textos = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(title: const Text('Explorar destinos')),
      body: SafeArea(
        child: Column(
          children: [
            // ---------- Buscador ----------
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 10),
              child: TextField(
                controller: _busqueda,
                onChanged: (v) => setState(() => _texto = v),
                decoration: InputDecoration(
                  hintText: 'Buscar por ciudad o país',
                  prefixIcon: const Icon(Icons.search),
                  suffixIcon: _texto.isEmpty
                      ? null
                      : IconButton(
                          icon: const Icon(Icons.close),
                          onPressed: () {
                            _busqueda.clear();
                            setState(() => _texto = '');
                          },
                        ),
                ),
              ),
            ),

            // ---------- Categorias ----------
            SizedBox(
              height: 46,
              child: ListView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 12),
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: FilterChip(
                      label: const Text('Todas'),
                      selected: _categoria == null,
                      onSelected: (_) => setState(() => _categoria = null),
                    ),
                  ),
                  for (final entrada in _categorias.entries)
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      child: FilterChip(
                        label: Text(entrada.value),
                        selected: _categoria == entrada.key,
                        onSelected: (_) => setState(
                          () => _categoria =
                              _categoria == entrada.key ? null : entrada.key,
                        ),
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 6),

            // ---------- Resultados ----------
            Expanded(
              child: StreamBuilder<List<Destino>>(
                stream: _servicio.observar(),
                builder: (context, snapshot) {
                  if (snapshot.hasError) {
                    return _Aviso(
                      icono: Icons.cloud_off,
                      titulo: 'No se pudo cargar el catálogo',
                      detalle: '${snapshot.error}',
                    );
                  }

                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  final todos = snapshot.data ?? const <Destino>[];

                  if (todos.isEmpty) {
                    return const _Aviso(
                      icono: Icons.public_off,
                      titulo: 'El catálogo está vacío',
                      detalle:
                          'La colección "destinos" es de solo lectura para la '
                          'aplicación. Su contenido se administra desde la '
                          'consola de Firebase.',
                    );
                  }

                  final destinos = _filtrar(todos);

                  if (destinos.isEmpty) {
                    return const _Aviso(
                      icono: Icons.search_off,
                      titulo: 'Sin resultados',
                      detalle: 'Prueba con otra búsqueda o cambia la categoría.',
                    );
                  }

                  return ListView.builder(
                    padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
                    itemCount: destinos.length,
                    itemBuilder: (context, i) {
                      final d = destinos[i];
                      return Card(
                        child: ListTile(
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 10,
                          ),
                          leading: Container(
                            width: 52,
                            height: 52,
                            decoration: BoxDecoration(
                              color: esquema.primaryContainer,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Icon(
                              Icons.place_outlined,
                              color: esquema.onPrimaryContainer,
                            ),
                          ),
                          title: Text(
                            d.nombre,
                            style: const TextStyle(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const SizedBox(height: 2),
                              Text(d.pais, style: textos.bodySmall),
                              const SizedBox(height: 4),
                              Row(
                                children: [
                                  Icon(
                                    Icons.local_fire_department_outlined,
                                    size: 14,
                                    color: esquema.tertiary,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    'Popularidad ${d.popularidad}',
                                    style: TextStyle(
                                      fontSize: 11.5,
                                      color: esquema.onSurfaceVariant,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                          trailing: const Icon(Icons.chevron_right),
                          onTap: () => Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => DetalleDestinoScreen(destino: d),
                            ),
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Aviso extends StatelessWidget {
  const _Aviso({
    required this.icono,
    required this.titulo,
    required this.detalle,
  });

  final IconData icono;
  final String titulo;
  final String detalle;

  @override
  Widget build(BuildContext context) {
    final esquema = Theme.of(context).colorScheme;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(34),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icono, size: 56, color: esquema.onSurfaceVariant),
            const SizedBox(height: 16),
            Text(
              titulo,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
            ),
            const SizedBox(height: 8),
            Text(
              detalle,
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
}
