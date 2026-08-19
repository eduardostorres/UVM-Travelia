import 'package:flutter/material.dart';

import '../../models/viaje.dart';
import '../../services/viaje_service.dart';
import '../../utils/formato.dart';
import 'detalle_viaje_screen.dart';
import 'formulario_viaje_screen.dart';

/// Pantalla "Mis viajes".
///
/// Demuestra la operación **Recuperar** del CRUD: consume el stream de
/// `users/{uid}/viajes` y refleja en tiempo real cualquier cambio hecho desde
/// la aplicación o directamente desde la consola de Firebase.
class MisViajesScreen extends StatefulWidget {
  const MisViajesScreen({super.key});

  @override
  State<MisViajesScreen> createState() => _MisViajesScreenState();
}

class _MisViajesScreenState extends State<MisViajesScreen> {
  final _servicio = ViajeService();
  EstadoViaje? _filtro;

  Future<void> _nuevoViaje() async {
    final creado = await Navigator.of(context).push<bool>(
      MaterialPageRoute(builder: (_) => const FormularioViajeScreen()),
    );
    if (creado == true && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Viaje agregado correctamente')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final esquema = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Mis viajes'),

        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(56),
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Row(
              children: [
                _Filtro(
                  etiqueta: 'Todos',
                  activo: _filtro == null,
                  alSeleccionar: () => setState(() => _filtro = null),
                ),
                for (final e in EstadoViaje.values)
                  _Filtro(
                    etiqueta: e.etiqueta,
                    activo: _filtro == e,
                    alSeleccionar: () => setState(() => _filtro = e),
                  ),
              ],
            ),
          ),
        ),
      ),

      floatingActionButton: FloatingActionButton.extended(
        onPressed: _nuevoViaje,
        icon: const Icon(Icons.add),
        label: const Text('Nuevo viaje'),
      ),

      body: StreamBuilder<List<Viaje>>(
        stream: _filtro == null
            ? _servicio.observar()
            : _servicio.observarPorEstado(_filtro!),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return _Mensaje(
              icono: Icons.cloud_off,
              titulo: 'No se pudo cargar la información',
              detalle: '${snapshot.error}',
              color: esquema.error,
            );
          }

          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final viajes = snapshot.data ?? const <Viaje>[];

          if (viajes.isEmpty) {
            return _Mensaje(
              icono: Icons.luggage_outlined,
              titulo: _filtro == null
                  ? 'Aún no tienes viajes'
                  : 'Sin viajes en "${_filtro!.etiqueta}"',
              detalle: _filtro == null
                  ? 'Toca "Nuevo viaje" para planear tu primer destino.'
                  : 'Cambia el filtro para ver otros viajes.',
              color: esquema.onSurfaceVariant,
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 96),
            itemCount: viajes.length,
            itemBuilder: (context, i) => _TarjetaViaje(
              viaje: viajes[i],
              alTocar: () => Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => DetalleViajeScreen(viajeId: viajes[i].id),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _Filtro extends StatelessWidget {
  const _Filtro({
    required this.etiqueta,
    required this.activo,
    required this.alSeleccionar,
  });

  final String etiqueta;
  final bool activo;
  final VoidCallback alSeleccionar;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: FilterChip(
        label: Text(etiqueta),
        selected: activo,
        onSelected: (_) => alSeleccionar(),
      ),
    );
  }
}

class _TarjetaViaje extends StatelessWidget {
  const _TarjetaViaje({required this.viaje, required this.alTocar});

  final Viaje viaje;
  final VoidCallback alTocar;

  Color _colorEstado(ColorScheme esquema) {
    switch (viaje.estado) {
      case EstadoViaje.proximo:
        return esquema.primary;
      case EstadoViaje.enCurso:
        return esquema.tertiary;
      case EstadoViaje.finalizado:
        return esquema.outline;
    }
  }

  @override
  Widget build(BuildContext context) {
    final esquema = Theme.of(context).colorScheme;
    final textos = Theme.of(context).textTheme;
    final colorEstado = _colorEstado(esquema);

    return Card(
      child: InkWell(
        onTap: alTocar,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 46,
                    height: 46,
                    decoration: BoxDecoration(
                      color: colorEstado.withValues(alpha: 0.14),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(Icons.place_outlined, color: colorEstado),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          viaje.titulo,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: textos.titleMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          viaje.destinoCompleto,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: textos.bodySmall?.copyWith(
                            color: esquema.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 5,
                    ),
                    decoration: BoxDecoration(
                      color: colorEstado.withValues(alpha: 0.14),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      viaje.estado.etiqueta,
                      style: TextStyle(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w600,
                        color: colorEstado,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  _Dato(
                    icono: Icons.calendar_today_outlined,
                    texto: Formato.rango(viaje.fechaInicio, viaje.fechaFin),
                  ),
                  const SizedBox(width: 16),
                  _Dato(
                    icono: Icons.schedule,
                    texto: '${viaje.duracionDias} días',
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  _Dato(
                    icono: Icons.account_balance_wallet_outlined,
                    texto: Formato.dinero(viaje.presupuesto, viaje.moneda),
                  ),
                  const Spacer(),
                  if (viaje.estado != EstadoViaje.finalizado)
                    Text(
                      Formato.cuentaRegresiva(viaje.fechaInicio),
                      style: textos.labelMedium?.copyWith(
                        color: esquema.primary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Dato extends StatelessWidget {
  const _Dato({required this.icono, required this.texto});

  final IconData icono;
  final String texto;

  @override
  Widget build(BuildContext context) {
    final esquema = Theme.of(context).colorScheme;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icono, size: 15, color: esquema.onSurfaceVariant),
        const SizedBox(width: 5),
        Text(
          texto,
          style: TextStyle(fontSize: 12.5, color: esquema.onSurfaceVariant),
        ),
      ],
    );
  }
}

class _Mensaje extends StatelessWidget {
  const _Mensaje({
    required this.icono,
    required this.titulo,
    required this.detalle,
    required this.color,
  });

  final IconData icono;
  final String titulo;
  final String detalle;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final textos = Theme.of(context).textTheme;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icono, size: 64, color: color.withValues(alpha: 0.6)),
            const SizedBox(height: 18),
            Text(
              titulo,
              textAlign: TextAlign.center,
              style: textos.titleMedium?.copyWith(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            Text(
              detalle,
              textAlign: TextAlign.center,
              style: textos.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
