import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

/// Excepción de dominio con un mensaje legible para el usuario.
///
/// Se usa para no exponer en la interfaz los códigos internos de Firebase,
/// que pueden revelar información útil a un atacante (por ejemplo, si un
/// correo está o no registrado).
class AuthException implements Exception {
  const AuthException(this.mensaje);
  final String mensaje;

  @override
  String toString() => mensaje;
}

/// Encapsula el acceso a Firebase Authentication.
///
/// Toda la aplicación consume la sesión a través de este servicio, de modo
/// que las pantallas nunca manipulan directamente el SDK de Firebase.
class AuthService {
  AuthService({FirebaseAuth? auth, FirebaseFirestore? db})
      : _auth = auth ?? FirebaseAuth.instance,
        _db = db ?? FirebaseFirestore.instance;

  final FirebaseAuth _auth;
  final FirebaseFirestore _db;

  /// Emite el usuario actual cada vez que cambia el estado de la sesión.
  Stream<User?> get cambiosDeSesion => _auth.authStateChanges();

  User? get usuarioActual => _auth.currentUser;

  bool get haySesion => _auth.currentUser != null;

  String? get uid => _auth.currentUser?.uid;

  /// Registra una cuenta nueva y crea su documento de perfil en Firestore.
  ///
  /// El documento se escribe en `users/{uid}` usando el UID emitido por
  /// Firebase Authentication, que es lo que permite a las Reglas de Seguridad
  /// aislar la información de cada usuario.
  Future<User> registrar({
    required String nombre,
    required String correo,
    required String contrasena,
  }) async {
    try {
      final credencial = await _auth.createUserWithEmailAndPassword(
        email: correo.trim(),
        password: contrasena,
      );

      final user = credencial.user;
      if (user == null) {
        throw const AuthException('No fue posible crear la cuenta.');
      }

      await user.updateDisplayName(nombre.trim());

      await _db.collection('users').doc(user.uid).set({
        'nombre': nombre.trim(),
        'email': correo.trim(),
        'fotoUrl': null,
        'idioma': 'es',
        'moneda': 'MXN',
        'creadoEn': FieldValue.serverTimestamp(),
      });

      return user;
    } on FirebaseAuthException catch (e) {
      throw AuthException(_traducir(e.code));
    }
  }

  /// Inicia sesión con correo y contraseña.
  Future<User> iniciarSesion({
    required String correo,
    required String contrasena,
  }) async {
    try {
      final credencial = await _auth.signInWithEmailAndPassword(
        email: correo.trim(),
        password: contrasena,
      );
      final user = credencial.user;
      if (user == null) {
        throw const AuthException('No fue posible iniciar sesión.');
      }
      return user;
    } on FirebaseAuthException catch (e) {
      throw AuthException(_traducir(e.code));
    }
  }

  /// Envía el correo de recuperación de contraseña.
  Future<void> recuperarContrasena(String correo) async {
    try {
      await _auth.sendPasswordResetEmail(email: correo.trim());
    } on FirebaseAuthException catch (e) {
      throw AuthException(_traducir(e.code));
    }
  }

  Future<void> cerrarSesion() => _auth.signOut();

  /// Convierte los códigos de Firebase en mensajes en español.
  ///
  /// Nota de seguridad: los errores de credenciales se unifican en un solo
  /// mensaje genérico para no revelar si un correo existe en el sistema
  /// (enumeración de usuarios).
  String _traducir(String codigo) {
    switch (codigo) {
      case 'invalid-credential':
      case 'wrong-password':
      case 'user-not-found':
        return 'Correo o contraseña incorrectos.';
      case 'email-already-in-use':
        return 'Ese correo ya tiene una cuenta registrada.';
      case 'invalid-email':
        return 'El formato del correo no es válido.';
      case 'weak-password':
        return 'La contraseña es demasiado débil.';
      case 'user-disabled':
        return 'Esta cuenta se encuentra deshabilitada.';
      case 'too-many-requests':
        return 'Demasiados intentos. Espera un momento e inténtalo de nuevo.';
      case 'network-request-failed':
        return 'Sin conexión. Revisa tu acceso a internet.';
      case 'operation-not-allowed':
        return 'El acceso por correo y contraseña no está habilitado.';
      default:
        return 'Ocurrió un error al procesar la solicitud.';
    }
  }
}
