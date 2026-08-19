import 'package:flutter/material.dart';

import '../../models/usuario.dart';
import '../../services/auth_service.dart';
import '../../services/usuario_service.dart';
import '../../utils/formato.dart';
import '../../utils/validadores.dart';

/// Perfil del usuario.
///
/// Demuestra las operaciones Recuperar y Actualizar sobre el documento
/// `users/{uid}` y concentra el cierre de sesion.
class PerfilScreen extends StatefulWidget {
  const PerfilScreen({super.key});

  @override
  State<PerfilScreen> createState() => _PerfilScreenState();
}

class _PerfilScreenState extends State<PerfilScreen> {
  final _servicio = UsuarioService();
  final _auth = AuthService();

  static const List<String> _monedas = ['MXN', 'USD', 'EUR', 'JPY', 'CAD'];
  static const Map<String, String> _idiomas = {'es': 'Español', 'en': 'English'};

  Future<void> _editarNombre(Usuario usuario) async {
    final controlador = TextEditingController(text: usuario.nombre);
    final formulario = GlobalKey<FormState>();

    final nuevo = await showDialog<String>(
      context: context,
      builder: (c) => AlertDialog(
        title: const Text('Editar nombre'),
        content: Form(
          key: formulario,
          child: TextFormField(
            controller: controlador,
            autofocus: true,
            textCapitalization: TextCapitalization.words,
            decoration: const InputDecoration(labelText: 'Nombre completo'),
            validator: Validadores.nombre,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(c).pop(),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () {
              if (formulario.currentState!.validate()) {
                Navigator.of(c).pop(controlador.text.trim());
              }
            },
            child: const Text('Guardar'),
          ),
        ],
      ),
    );

    controlador.dispose();
    if (nuevo == null) return;

    try {
      await _servicio.actualizar(nombre: nuevo);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Nombre actualizado')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('No se pudo actualizar: $e')),
      );
    }
  }

  Future<void> _cerrarSesion() async {
    final confirmado = await showDialog<bool>(
      context: context,
      builder: (c) => AlertDialog(
        title: const Text('Cerrar sesión'),
        content: const Text('¿Deseas salir de tu cuenta?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(c).pop(false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(c).pop(true),
            child: const Text('Cerrar sesión'),
          ),
        ],
      ),
    );

    if (confirmado == true) await _auth.cerrarSesion();
  }

  @override
  Widget build(BuildContext context) {
    final esquema = Theme.of(context).colorScheme;
    final textos = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(title: const Text('Perfil')),
      body: StreamBuilder<Usuario?>(
        stream: _servicio.observar(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final usuario = snapshot.data;
          if (usuario == null) {
            return const Center(child: Text('No se encontró el perfil.'));
          }

          return ListView(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
            children: [
              // ---------- Encabezado ----------
              Center(
                child: Column(
                  children: [
                    CircleAvatar(
                      radius: 44,
                      backgroundColor: esquema.primaryContainer,
                      child: Text(
                        usuario.iniciales,
                        style: TextStyle(
                          fontSize: 30,
                          fontWeight: FontWeight.w700,
                          color: esquema.onPrimaryContainer,
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),
                    Text(
                      usuario.nombre,
                      style: textos.titleLarge?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      usuario.email,
                      style: TextStyle(color: esquema.onSurfaceVariant),
                    ),
                    if (usuario.creadoEn != null) ...[
                      const SizedBox(height: 6),
                      Text(
                        'Miembro desde ${Formato.fechaLarga(usuario.creadoEn!)}',
                        style: TextStyle(
                          fontSize: 12,
                          color: esquema.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 28),

              // ---------- Informacion personal ----------
              _Seccion('Información personal'),
              Card(
                child: Column(
                  children: [
                    ListTile(
                      leading: const Icon(Icons.badge_outlined),
                      title: const Text('Nombre'),
                      subtitle: Text(usuario.nombre),
                      trailing: const Icon(Icons.edit_outlined, size: 20),
                      onTap: () => _editarNombre(usuario),
                    ),
                    const Divider(height: 1),
                    ListTile(
                      leading: const Icon(Icons.mail_outline),
                      title: const Text('Correo electrónico'),
                      subtitle: Text(usuario.email),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // ---------- Preferencias ----------
              _Seccion('Preferencias'),
              Card(
                child: Column(
                  children: [
                    ListTile(
                      leading: const Icon(Icons.language),
                      title: const Text('Idioma'),
                      trailing: DropdownButton<String>(
                        value: _idiomas.containsKey(usuario.idioma)
                            ? usuario.idioma
                            : 'es',
                        underline: const SizedBox.shrink(),
                        items: [
                          for (final e in _idiomas.entries)
                            DropdownMenuItem(
                              value: e.key,
                              child: Text(e.value),
                            ),
                        ],
                        onChanged: (v) {
                          if (v != null) _servicio.actualizar(idioma: v);
                        },
                      ),
                    ),
                    const Divider(height: 1),
                    ListTile(
                      leading: const Icon(Icons.payments_outlined),
                      title: const Text('Moneda'),
                      trailing: DropdownButton<String>(
                        value: _monedas.contains(usuario.moneda)
                            ? usuario.moneda
                            : 'MXN',
                        underline: const SizedBox.shrink(),
                        items: [
                          for (final m in _monedas)
                            DropdownMenuItem(value: m, child: Text(m)),
                        ],
                        onChanged: (v) {
                          if (v != null) _servicio.actualizar(moneda: v);
                        },
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // ---------- Seguridad ----------
              _Seccion('Seguridad'),
              Card(
                child: Column(
                  children: [
                    ListTile(
                      leading: const Icon(Icons.fingerprint),
                      title: const Text('Identificador de la cuenta'),
                      subtitle: SelectableText(
                        _auth.uid ?? '-',
                        style: const TextStyle(
                          fontFamily: 'monospace',
                          fontSize: 11.5,
                        ),
                      ),
                    ),
                    const Divider(height: 1),
                    ListTile(
                      leading: Icon(Icons.logout, color: esquema.error),
                      title: Text(
                        'Cerrar sesión',
                        style: TextStyle(color: esquema.error),
                      ),
                      onTap: _cerrarSesion,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              Center(
                child: Text(
                  'Travelia · Proyecto Integrador Etapa 3\nUVM Online',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 11.5,
                    color: esquema.onSurfaceVariant,
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _Seccion extends StatelessWidget {
  const _Seccion(this.titulo);
  final String titulo;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 8),
      child: Text(
        titulo.toUpperCase(),
        style: TextStyle(
          fontSize: 11.5,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.8,
          color: Theme.of(context).colorScheme.primary,
        ),
      ),
    );
  }
}
