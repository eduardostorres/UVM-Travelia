import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import 'firebase_options.dart';
import 'screens/auth/inicio_sesion_screen.dart';
import 'screens/auth/splash_screen.dart';
import 'screens/navegacion_principal.dart';
import 'services/auth_service.dart';
import 'theme/app_theme.dart';

/// Punto de entrada de Travelia.
///
/// Proyecto Integrador - Etapa 3
/// UVM Online | Soluciones de Programación Móvil
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  runApp(const TraveliaApp());
}

class TraveliaApp extends StatelessWidget {
  const TraveliaApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Travelia',
      debugShowCheckedModeBanner: false,

      // Los dialogos del sistema (selectores de fecha y hora, menus de
      // seleccion de texto) toman su idioma de aqui. Sin esta configuracion
      // aparecen en ingles aunque el resto de la interfaz este en espanol.
      locale: const Locale('es', 'MX'),
      supportedLocales: const [
        Locale('es', 'MX'),
        Locale('es'),
        Locale('en'),
      ],
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],

      theme: AppTheme.claro,
      darkTheme: AppTheme.oscuro,
      themeMode: ThemeMode.system,
      home: const SplashScreen(),
    );
  }
}

/// Decide la pantalla inicial según el estado de la sesión.
///
/// Se apoya en [AuthService.cambiosDeSesion] para que el cierre de sesión o
/// la expiración del token devuelvan al usuario al inicio de sesión sin
/// necesidad de navegación manual.
class PuertaDeAcceso extends StatelessWidget {
  const PuertaDeAcceso({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = AuthService();

    return StreamBuilder(
      stream: auth.cambiosDeSesion,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }
        if (snapshot.hasData) {
          return const NavegacionPrincipal();
        }
        return const InicioSesionScreen();
      },
    );
  }
}
