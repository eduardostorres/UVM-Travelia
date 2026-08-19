import 'package:flutter/material.dart';

import '../models/destino.dart';
import '../models/usuario.dart';
import '../models/viaje.dart';
import '../services/destino_service.dart';
import '../services/usuario_service.dart';
import '../services/viaje_service.dart';
import '../utils/formato.dart';
import 'destinos/detalle_destino_screen.dart';
import 'navegacion_principal.dart';
import 'viajes/detalle_viaje_screen.dart';

/// Pantalla de inicio.
///
/// Centraliza el acceso a las funciones principales: muestra el proximo
/// viaje del usuario y una seleccion del catalogo de destinos.
class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final esquema = Theme.of(context).colorScheme;
    final textos = Theme.of(context).textTheme;

    return Scaffold(
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
          children: [
            // ---------- Saludo ----------
            StreamBuilder<Usuario?>(
              stream: UsuarioService().observar(),
              builder: (context, snapshot) {
                final nombre = snapshot.data?.nombre.split(' ').first ?? '';
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _saludo(),
                      style: textos.bodyLarge?.copyWith(
                        color: esquema.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      nombre.isEmpty ? 'Bienvenido' : nombre,
                      style: textos.headlineMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                );
              },
            ),
            const SizedBox(height: 22),

            // ---------- Buscador ----------
            InkWell(
              onTap: () => context.irAPestana(1),
              borderRadius: BorderRadius.circular(14),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 15,
                ),
                decoration: BoxDecoration(
                  color: esquema.surfaceContainerHighest.withValues(alpha: 0.45),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: esquema.outlineVariant),
                ),
                child: Row(
                  children: [
                    Icon(Icons.search, color: esquema.onSurfaceVariant),
                    const SizedBox(width: 12),
                    Text(
                      '¿A dónde quieres ir?',
                      style: TextStyle(color: esquema.onSurfaceVariant),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 26),

            // ---------- Proximo viaje ----------
            _Encabezado(
              titulo: 'Tu próximo viaje',
              accion: 'Ver todos',
              alTocarAccion: () => context.irAPestana(2),
            ),
            const SizedBox(height: 10),
            StreamBuilder<List<Viaje>>(
              stream: ViajeService().observar(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const _CargandoTarjeta(alto: 150);
                }

                final viajes = (snapshot.data ?? const <Viaje>[])
                    .where((v) => v.estado != EstadoViaje.finalizado)
                    .toList();

                if (viajes.isEmpty) {
                  return _TarjetaVacia(
                    icono: Icons.luggage_outlined,
                    mensaje: 'Todavía no has planeado ningún viaje',
                    accion: 'Crear uno',
                    alTocar: () => context.irAPestana(2),
                  );
                }

                return _TarjetaProximoViaje(viaje: viajes.first);
              },
            ),
            const SizedBox(height: 26),

            // ---------- Destinos recomendados ----------
            _Encabezado(
              titulo: 'Destinos recomendados',
              accion: 'Explorar',
              alTocarAccion: () => context.irAPestana(1),
            ),
            const SizedBox(height: 10),
            SizedBox(
              height: 196,
              child: StreamBuilder<List<Destino>>(
                stream: DestinoService().observar(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const _CargandoTarjeta(alto: 196);
                  }

                  final destinos = snapshot.data ?? const <Destino>[];

                  if (destinos.isEmpty) {
                    return _TarjetaVacia(
                      icono: Icons.public_off,
                      mensaje: 'El catálogo de destinos aún está vacío',
                      accion: null,
                      alTocar: null,
                    );
                  }

                  return ListView.separated(
                    scrollDirection: Axis.horizontal,
                    itemCount: destinos.length,
                    separatorBuilder: (_, _) => const SizedBox(width: 12),
                    itemBuilder: (context, i) =>
                        _TarjetaDestino(destino: destinos[i]),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  static String _saludo() {
    final hora = DateTime.now().hour;
    if (hora < 12) return 'Buenos días,';
    if (hora < 19) return 'Buenas tardes,';
    return 'Buenas noches,';
  }
}

class _Encabezado extends StatelessWidget {
  const _Encabezado({
    required this.titulo,
    this.accion,
    this.alTocarAccion,
  });

  final String titulo;
  final String? accion;
  final VoidCallback? alTocarAccion;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(
          titulo,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w700,
              ),
        ),
        const Spacer(),
        if (accion != null)
          TextButton(onPressed: alTocarAccion, child: Text(accion!)),
      ],
    );
  }
}

class _TarjetaProximoViaje extends StatelessWidget {
  const _TarjetaProximoViaje({required this.viaje});

  final Viaje viaje;

  @override
  Widget build(BuildContext context) {
    final esquema = Theme.of(context).colorScheme;

    return InkWell(
      borderRadius: BorderRadius.circular(18),
      onTap: () => Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => DetalleViajeScreen(viajeId: viaje.id),
        ),
      ),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [esquema.primary, esquema.primary.withValues(alpha: 0.72)],
          ),
          borderRadius: BorderRadius.circular(18),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.flight_takeoff, color: esquema.onPrimary, size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    viaje.titulo,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 19,
                      fontWeight: FontWeight.w700,
                      color: esquema.onPrimary,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              viaje.destinoCompleto,
              style: TextStyle(
                color: esquema.onPrimary.withValues(alpha: 0.92),
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: Text(
                    Formato.rango(viaje.fechaInicio, viaje.fechaFin),
                    style: TextStyle(
                      color: esquema.onPrimary.withValues(alpha: 0.92),
                      fontSize: 13,
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: esquema.onPrimary.withValues(alpha: 0.22),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    Formato.cuentaRegresiva(viaje.fechaInicio),
                    style: TextStyle(
                      color: esquema.onPrimary,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _TarjetaDestino extends StatelessWidget {
  const _TarjetaDestino({required this.destino});

  final Destino destino;

  @override
  Widget build(BuildContext context) {
    final esquema = Theme.of(context).colorScheme;

    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: () => Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => DetalleDestinoScreen(destino: destino),
        ),
      ),
      child: Container(
        width: 164,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: esquema.outlineVariant),
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              height: 104,
              width: double.infinity,
              color: esquema.primaryContainer,
              child: Icon(
                Icons.photo_camera_back_outlined,
                size: 34,
                color: esquema.onPrimaryContainer.withValues(alpha: 0.6),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(11),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    destino.nombre,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 14.5,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    destino.pais,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 12,
                      color: esquema.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TarjetaVacia extends StatelessWidget {
  const _TarjetaVacia({
    required this.icono,
    required this.mensaje,
    required this.accion,
    required this.alTocar,
  });

  final IconData icono;
  final String mensaje;
  final String? accion;
  final VoidCallback? alTocar;

  @override
  Widget build(BuildContext context) {
    final esquema = Theme.of(context).colorScheme;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 28, horizontal: 20),
      decoration: BoxDecoration(
        color: esquema.surfaceContainerHighest.withValues(alpha: 0.35),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icono, size: 34, color: esquema.onSurfaceVariant),
          const SizedBox(height: 10),
          Text(
            mensaje,
            textAlign: TextAlign.center,
            style: TextStyle(color: esquema.onSurfaceVariant, fontSize: 13.5),
          ),
          if (accion != null) ...[
            const SizedBox(height: 6),
            TextButton(onPressed: alTocar, child: Text(accion!)),
          ],
        ],
      ),
    );
  }
}

class _CargandoTarjeta extends StatelessWidget {
  const _CargandoTarjeta({required this.alto});

  final double alto;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: alto,
      child: const Center(child: CircularProgressIndicator()),
    );
  }
}
