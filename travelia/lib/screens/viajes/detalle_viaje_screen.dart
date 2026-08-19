import 'package:flutter/material.dart';

import '../../models/actividad.dart';
import '../../models/viaje.dart';
import '../../services/viaje_service.dart';
import '../../utils/formato.dart';
import 'formulario_actividad_screen.dart';
import 'formulario_viaje_screen.dart';

/// Detalle de un viaje.
///
/// Reúne las operaciones **Recuperar** (documento y subcolección),
/// **Actualizar** (a través del formulario) y **Eliminar** del CRUD.
class DetalleViajeScreen extends StatefulWidget {
  const DetalleViajeScreen({super.key, required this.viajeId});

  final String viajeId;

  @override
  State<DetalleViajeScreen> createState() => _DetalleViajeScreenState();
}

class _DetalleViajeScreenState extends State<DetalleViajeScreen> {
  final _servicio = ViajeService();

  Viaje? _viaje;
  bool _cargando = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _cargar();
  }

  Future<void> _cargar() async {
    setState(() {
      _cargando = true;
      _error = null;
    });
    try {
      final v = await _servicio.obtener(widget.viajeId);
      if (!mounted) return;
      setState(() {
        _viaje = v;
        _cargando = false;
      });
    } on ViajeException catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.mensaje;
        _cargando = false;
      });
    }
  }

  Future<void> _editar() async {
    if (_viaje == null) return;
    final actualizado = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => FormularioViajeScreen(viaje: _viaje),
      ),
    );
    if (actualizado == true) {
      await _cargar();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Viaje actualizado correctamente')),
        );
      }
    }
  }

  /// Elimina el viaje previa confirmación explícita del usuario.
  ///
  /// El borrado es irreversible y arrastra las actividades del itinerario,
  /// por lo que se advierte de forma clara antes de ejecutarlo.
  Future<void> _eliminar() async {
    final viaje = _viaje;
    if (viaje == null) return;

    final confirmado = await showDialog<bool>(
      context: context,
      builder: (contexto) => AlertDialog(
        icon: const Icon(Icons.warning_amber_rounded, size: 32),
        title: const Text('Eliminar viaje'),
        content: Text(
          '¿Seguro que quieres eliminar "${viaje.titulo}"?\n\n'
          'Se borrarán también todas las actividades de su itinerario. '
          'Esta acción no se puede deshacer.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(contexto).pop(false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(contexto).colorScheme.error,
            ),
            onPressed: () => Navigator.of(contexto).pop(true),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );

    if (confirmado != true) return;

    try {
      await _servicio.eliminar(viaje.id);
      if (!mounted) return;
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Se eliminó "${viaje.titulo}"')),
      );
    } on ViajeException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.mensaje)),
      );
    }
  }

  Future<void> _nuevaActividad() async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => FormularioActividadScreen(
          viajeId: widget.viajeId,
          fechaSugerida: _viaje?.fechaInicio,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final esquema = Theme.of(context).colorScheme;
    final textos = Theme.of(context).textTheme;

    if (_cargando) {
      return Scaffold(
        appBar: AppBar(title: const Text('Detalle del viaje')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (_error != null || _viaje == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Detalle del viaje')),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.error_outline, size: 56, color: esquema.error),
                const SizedBox(height: 16),
                Text(
                  _error ?? 'El viaje ya no existe.',
                  textAlign: TextAlign.center,
                  style: textos.titleMedium,
                ),
                const SizedBox(height: 20),
                FilledButton(
                  onPressed: _cargar,
                  child: const Text('Reintentar'),
                ),
              ],
            ),
          ),
        ),
      );
    }

    final viaje = _viaje!;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Detalle del viaje'),
        actions: [
          IconButton(
            tooltip: 'Editar',
            icon: const Icon(Icons.edit_outlined),
            onPressed: _editar,
          ),
          IconButton(
            tooltip: 'Eliminar',
            icon: const Icon(Icons.delete_outline),
            color: esquema.error,
            onPressed: _eliminar,
          ),
        ],
      ),

      floatingActionButton: FloatingActionButton.extended(
        onPressed: _nuevaActividad,
        icon: const Icon(Icons.add),
        label: const Text('Actividad'),
      ),

      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 96),
        children: [
          // ---------- Encabezado ----------
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [esquema.primary, esquema.primary.withValues(alpha: 0.75)],
              ),
              borderRadius: BorderRadius.circular(18),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        viaje.titulo,
                        style: TextStyle(
                          fontSize: 23,
                          fontWeight: FontWeight.w700,
                          color: esquema.onPrimary,
                        ),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 11,
                        vertical: 5,
                      ),
                      decoration: BoxDecoration(
                        color: esquema.onPrimary.withValues(alpha: 0.22),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        viaje.estado.etiqueta,
                        style: TextStyle(
                          fontSize: 11.5,
                          fontWeight: FontWeight.w600,
                          color: esquema.onPrimary,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Icon(Icons.place_outlined,
                        size: 17, color: esquema.onPrimary.withValues(alpha: 0.9)),
                    const SizedBox(width: 6),
                    Text(
                      viaje.destinoCompleto,
                      style: TextStyle(
                        fontSize: 15,
                        color: esquema.onPrimary.withValues(alpha: 0.95),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 18),
                Row(
                  children: [
                    _Metrica(
                      etiqueta: 'Duración',
                      valor: '${viaje.duracionDias} días',
                      color: esquema.onPrimary,
                    ),
                    const SizedBox(width: 28),
                    _Metrica(
                      etiqueta: 'Presupuesto',
                      valor: Formato.dinero(viaje.presupuesto, viaje.moneda),
                      color: esquema.onPrimary,
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 22),

          // ---------- Fechas ----------
          _Bloque(
            titulo: 'Fechas',
            hijos: [
              _Renglon(
                icono: Icons.flight_takeoff,
                etiqueta: 'Salida',
                valor: Formato.fechaLarga(viaje.fechaInicio),
              ),
              _Renglon(
                icono: Icons.flight_land,
                etiqueta: 'Regreso',
                valor: Formato.fechaLarga(viaje.fechaFin),
              ),
              if (viaje.estado != EstadoViaje.finalizado)
                _Renglon(
                  icono: Icons.timelapse,
                  etiqueta: 'Cuenta regresiva',
                  valor: Formato.cuentaRegresiva(viaje.fechaInicio),
                ),
            ],
          ),

          // ---------- Notas ----------
          if (viaje.notas != null && viaje.notas!.trim().isNotEmpty) ...[
            const SizedBox(height: 18),
            _Bloque(
              titulo: 'Notas',
              hijos: [
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Text(viaje.notas!, style: textos.bodyMedium),
                ),
              ],
            ),
          ],

          const SizedBox(height: 18),

          // ---------- Itinerario (subcolección) ----------
          Row(
            children: [
              Text(
                'ITINERARIO',
                style: TextStyle(
                  fontSize: 11.5,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.8,
                  color: esquema.primary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),

          StreamBuilder<List<Actividad>>(
            stream: _servicio.observarActividades(widget.viajeId),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Padding(
                  padding: EdgeInsets.symmetric(vertical: 24),
                  child: Center(child: CircularProgressIndicator()),
                );
              }

              final actividades = snapshot.data ?? const <Actividad>[];

              if (actividades.isEmpty) {
                return Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 30),
                  decoration: BoxDecoration(
                    color: esquema.surfaceContainerHighest.withValues(alpha: 0.35),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Column(
                    children: [
                      Icon(Icons.event_note_outlined,
                          size: 40, color: esquema.onSurfaceVariant),
                      const SizedBox(height: 10),
                      Text(
                        'Sin actividades registradas',
                        style: textos.bodyMedium?.copyWith(
                          color: esquema.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                );
              }

              return Column(
                children: [
                  for (final a in actividades)
                    _TarjetaActividad(
                      actividad: a,
                      viajeId: widget.viajeId,
                      servicio: _servicio,
                    ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}

class _Metrica extends StatelessWidget {
  const _Metrica({
    required this.etiqueta,
    required this.valor,
    required this.color,
  });

  final String etiqueta;
  final String valor;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          etiqueta,
          style: TextStyle(
            fontSize: 11.5,
            color: color.withValues(alpha: 0.8),
          ),
        ),
        const SizedBox(height: 2),
        Text(
          valor,
          style: TextStyle(
            fontSize: 15.5,
            fontWeight: FontWeight.w700,
            color: color,
          ),
        ),
      ],
    );
  }
}

class _Bloque extends StatelessWidget {
  const _Bloque({required this.titulo, required this.hijos});

  final String titulo;
  final List<Widget> hijos;

  @override
  Widget build(BuildContext context) {
    final esquema = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          titulo.toUpperCase(),
          style: TextStyle(
            fontSize: 11.5,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.8,
            color: esquema.primary,
          ),
        ),
        const SizedBox(height: 10),
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: esquema.outlineVariant),
          ),
          child: Column(children: hijos),
        ),
      ],
    );
  }
}

class _Renglon extends StatelessWidget {
  const _Renglon({
    required this.icono,
    required this.etiqueta,
    required this.valor,
  });

  final IconData icono;
  final String etiqueta;
  final String valor;

  @override
  Widget build(BuildContext context) {
    final esquema = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Icon(icono, size: 19, color: esquema.primary),
          const SizedBox(width: 12),
          Text(
            etiqueta,
            style: TextStyle(fontSize: 13.5, color: esquema.onSurfaceVariant),
          ),
          const Spacer(),
          Flexible(
            child: Text(
              valor,
              textAlign: TextAlign.right,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _TarjetaActividad extends StatelessWidget {
  const _TarjetaActividad({
    required this.actividad,
    required this.viajeId,
    required this.servicio,
  });

  final Actividad actividad;
  final String viajeId;
  final ViajeService servicio;

  IconData get _icono {
    switch (actividad.categoria) {
      case CategoriaActividad.transporte:
        return Icons.directions_transit;
      case CategoriaActividad.hospedaje:
        return Icons.hotel_outlined;
      case CategoriaActividad.comida:
        return Icons.restaurant_outlined;
      case CategoriaActividad.atraccion:
        return Icons.attractions_outlined;
      case CategoriaActividad.otro:
        return Icons.event_note_outlined;
    }
  }

  @override
  Widget build(BuildContext context) {
    final esquema = Theme.of(context).colorScheme;

    return Dismissible(
      key: ValueKey(actividad.id),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 22),
        margin: const EdgeInsets.symmetric(vertical: 5),
        decoration: BoxDecoration(
          color: esquema.errorContainer,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Icon(Icons.delete_outline, color: esquema.onErrorContainer),
      ),
      confirmDismiss: (_) async {
        return await showDialog<bool>(
              context: context,
              builder: (c) => AlertDialog(
                title: const Text('Eliminar actividad'),
                content: Text('¿Eliminar "${actividad.titulo}" del itinerario?'),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.of(c).pop(false),
                    child: const Text('Cancelar'),
                  ),
                  FilledButton(
                    style: FilledButton.styleFrom(
                      backgroundColor: esquema.error,
                    ),
                    onPressed: () => Navigator.of(c).pop(true),
                    child: const Text('Eliminar'),
                  ),
                ],
              ),
            ) ??
            false;
      },
      onDismissed: (_) => servicio.eliminarActividad(viajeId, actividad.id),
      child: Card(
        child: ListTile(
          leading: CircleAvatar(
            backgroundColor: esquema.primaryContainer,
            child: Icon(_icono, size: 20, color: esquema.onPrimaryContainer),
          ),
          title: Text(
            actividad.titulo,
            style: TextStyle(
              fontWeight: FontWeight.w600,
              decoration: actividad.completada
                  ? TextDecoration.lineThrough
                  : TextDecoration.none,
            ),
          ),
          subtitle: Text(
            '${Formato.fechaConDia(actividad.fecha)} · ${actividad.hora}'
            '${actividad.costo > 0 ? ' · \$${actividad.costo.toStringAsFixed(0)}' : ''}',
            style: const TextStyle(fontSize: 12.5),
          ),
          trailing: Checkbox(
            value: actividad.completada,
            onChanged: (v) => servicio.actualizarActividad(
              viajeId,
              actividad.copiarCon(completada: v ?? false),
            ),
          ),
          onTap: () => Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => FormularioActividadScreen(
                viajeId: viajeId,
                actividad: actividad,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
