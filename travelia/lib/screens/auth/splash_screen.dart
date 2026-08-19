import 'dart:async';

import 'package:flutter/material.dart';

import '../../main.dart';
import '../../theme/app_theme.dart';

/// Pantalla de bienvenida.
///
/// Presenta la identidad de Travelia mientras la aplicación termina de
/// inicializar Firebase y de resolver el estado de la sesión. Corresponde a
/// la primera interfaz definida en la Etapa 2 del Proyecto Integrador.
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controlador;
  late final Animation<double> _aparicion;
  late final Animation<double> _escala;
  Timer? _temporizador;

  @override
  void initState() {
    super.initState();

    _controlador = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );

    _aparicion = CurvedAnimation(
      parent: _controlador,
      curve: Curves.easeOut,
    );

    _escala = Tween<double>(begin: 0.85, end: 1.0).animate(
      CurvedAnimation(parent: _controlador, curve: Curves.easeOutBack),
    );

    _controlador.forward();

    _temporizador = Timer(const Duration(milliseconds: 2200), _continuar);
  }

  void _continuar() {
    if (!mounted) return;
    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        transitionDuration: const Duration(milliseconds: 400),
        pageBuilder: (_, _, _) => const PuertaDeAcceso(),
        transitionsBuilder: (_, animacion, _, hijo) =>
            FadeTransition(opacity: animacion, child: hijo),
      ),
    );
  }

  @override
  void dispose() {
    _temporizador?.cancel();
    _controlador.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        // El Scaffold entrega restricciones flojas en anchura: sin estas dos
        // lineas el contenedor se encoge al ancho de su hijo mas ancho y el
        // degradado solo cubre una franja de la pantalla.
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFF0D9488),
              Color(0xFF0F766E),
              Color(0xFF134E4A),
            ],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              const Spacer(flex: 3),
              FadeTransition(
                opacity: _aparicion,
                child: ScaleTransition(
                  scale: _escala,
                  child: Column(
                    children: [
                      Container(
                        width: 116,
                        height: 116,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(30),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.2),
                              blurRadius: 24,
                              offset: const Offset(0, 10),
                            ),
                          ],
                        ),
                        child: const Icon(
                          Icons.travel_explore,
                          size: 66,
                          color: AppTheme.semilla,
                        ),
                      ),
                      const SizedBox(height: 28),
                      const Text(
                        'Travelia',
                        style: TextStyle(
                          fontSize: 42,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                          letterSpacing: 1.2,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        'Tu asistente digital de viajes',
                        style: TextStyle(
                          fontSize: 15,
                          color: Colors.white.withValues(alpha: 0.9),
                          letterSpacing: 0.4,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const Spacer(flex: 2),
              FadeTransition(
                opacity: _aparicion,
                child: const SizedBox(
                  width: 34,
                  height: 34,
                  child: CircularProgressIndicator(
                    strokeWidth: 3,
                    valueColor: AlwaysStoppedAnimation(Colors.white),
                  ),
                ),
              ),
              const SizedBox(height: 40),
              FadeTransition(
                opacity: _aparicion,
                child: Text(
                  'UVM Online · Proyecto Integrador',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.white.withValues(alpha: 0.7),
                  ),
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
}
