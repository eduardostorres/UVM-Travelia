import 'package:flutter/material.dart';

import '../../services/auth_service.dart';
import '../../utils/validadores.dart';

/// Pantalla de registro de usuario.
///
/// Crea la cuenta en Firebase Authentication y su documento de perfil en
/// `users/{uid}` dentro de Cloud Firestore.
class RegistroScreen extends StatefulWidget {
  const RegistroScreen({super.key});

  @override
  State<RegistroScreen> createState() => _RegistroScreenState();
}

class _RegistroScreenState extends State<RegistroScreen> {
  final _formulario = GlobalKey<FormState>();
  final _nombre = TextEditingController();
  final _correo = TextEditingController();
  final _contrasena = TextEditingController();
  final _confirmacion = TextEditingController();
  final _auth = AuthService();

  bool _cargando = false;
  bool _ocultarContrasena = true;
  bool _aceptaTerminos = false;
  String? _error;

  @override
  void dispose() {
    _nombre.dispose();
    _correo.dispose();
    _contrasena.dispose();
    _confirmacion.dispose();
    super.dispose();
  }

  Future<void> _registrar() async {
    setState(() => _error = null);

    if (!_formulario.currentState!.validate()) return;

    if (!_aceptaTerminos) {
      setState(() => _error = 'Debes aceptar los términos y condiciones.');
      return;
    }

    FocusScope.of(context).unfocus();
    setState(() => _cargando = true);

    try {
      await _auth.registrar(
        nombre: _nombre.text,
        correo: _correo.text,
        contrasena: _contrasena.text,
      );
      if (!mounted) return;
      // Al crearse la sesión, PuertaDeAcceso muestra el área autenticada.
      Navigator.of(context).popUntil((ruta) => ruta.isFirst);
    } on AuthException catch (e) {
      if (mounted) setState(() => _error = e.mensaje);
    } finally {
      if (mounted) setState(() => _cargando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final esquema = Theme.of(context).colorScheme;
    final textos = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(title: const Text('Crear cuenta')),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: Form(
                key: _formulario,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      'Únete a Travelia',
                      style: textos.headlineSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Crea tu cuenta para guardar y sincronizar tus viajes',
                      style: textos.bodyMedium?.copyWith(
                        color: esquema.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 28),

                    if (_error != null) ...[
                      Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: esquema.errorContainer,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.error_outline,
                              size: 20,
                              color: esquema.onErrorContainer,
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                _error!,
                                style: TextStyle(
                                  color: esquema.onErrorContainer,
                                  fontSize: 13.5,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 18),
                    ],

                    TextFormField(
                      controller: _nombre,
                      enabled: !_cargando,
                      textCapitalization: TextCapitalization.words,
                      textInputAction: TextInputAction.next,
                      decoration: const InputDecoration(
                        labelText: 'Nombre completo',
                        prefixIcon: Icon(Icons.person_outline),
                      ),
                      validator: Validadores.nombre,
                    ),
                    const SizedBox(height: 16),

                    TextFormField(
                      controller: _correo,
                      enabled: !_cargando,
                      keyboardType: TextInputType.emailAddress,
                      textInputAction: TextInputAction.next,
                      autocorrect: false,
                      decoration: const InputDecoration(
                        labelText: 'Correo electrónico',
                        hintText: 'nombre@correo.com',
                        prefixIcon: Icon(Icons.mail_outline),
                      ),
                      validator: Validadores.correo,
                    ),
                    const SizedBox(height: 16),

                    TextFormField(
                      controller: _contrasena,
                      enabled: !_cargando,
                      obscureText: _ocultarContrasena,
                      textInputAction: TextInputAction.next,
                      decoration: InputDecoration(
                        labelText: 'Contraseña',
                        helperText: 'Mínimo 8 caracteres, con letras y números',
                        prefixIcon: const Icon(Icons.lock_outline),
                        suffixIcon: IconButton(
                          icon: Icon(
                            _ocultarContrasena
                                ? Icons.visibility_outlined
                                : Icons.visibility_off_outlined,
                          ),
                          onPressed: () => setState(
                            () => _ocultarContrasena = !_ocultarContrasena,
                          ),
                        ),
                      ),
                      validator: Validadores.contrasena,
                    ),
                    const SizedBox(height: 16),

                    TextFormField(
                      controller: _confirmacion,
                      enabled: !_cargando,
                      obscureText: _ocultarContrasena,
                      textInputAction: TextInputAction.done,
                      onFieldSubmitted: (_) => _registrar(),
                      decoration: const InputDecoration(
                        labelText: 'Confirmar contraseña',
                        prefixIcon: Icon(Icons.lock_reset_outlined),
                      ),
                      validator: (v) =>
                          Validadores.confirmacion(v, _contrasena.text),
                    ),
                    const SizedBox(height: 8),

                    CheckboxListTile(
                      value: _aceptaTerminos,
                      onChanged: _cargando
                          ? null
                          : (v) => setState(() => _aceptaTerminos = v ?? false),
                      controlAffinity: ListTileControlAffinity.leading,
                      contentPadding: EdgeInsets.zero,
                      title: Text(
                        'Acepto los términos y condiciones y el aviso de privacidad',
                        style: textos.bodySmall,
                      ),
                    ),
                    const SizedBox(height: 16),

                    FilledButton(
                      onPressed: _cargando ? null : _registrar,
                      child: _cargando
                          ? const SizedBox(
                              width: 22,
                              height: 22,
                              child: CircularProgressIndicator(
                                strokeWidth: 2.5,
                                valueColor:
                                    AlwaysStoppedAnimation(Colors.white),
                              ),
                            )
                          : const Text('Registrarse'),
                    ),
                    const SizedBox(height: 12),

                    TextButton(
                      onPressed:
                          _cargando ? null : () => Navigator.of(context).pop(),
                      child: const Text('Ya tengo una cuenta'),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
