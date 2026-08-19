import 'package:flutter/material.dart';

import 'destinos/explorador_screen.dart';
import 'favoritos_screen.dart';
import 'home_screen.dart';
import 'perfil/perfil_screen.dart';
import 'viajes/mis_viajes_screen.dart';

/// Contenedor del área autenticada.
///
/// La Etapa 2 definió una barra de navegación inferior como eje de la
/// aplicación. Se usa un [IndexedStack] para que cada sección conserve su
/// estado de desplazamiento y sus suscripciones a Firestore al cambiar de
/// pestaña, en lugar de reconstruirse desde cero.
class NavegacionPrincipal extends StatefulWidget {
  const NavegacionPrincipal({super.key});

  @override
  State<NavegacionPrincipal> createState() => _NavegacionPrincipalState();
}

class _NavegacionPrincipalState extends State<NavegacionPrincipal> {
  int _indice = 0;

  static const List<Widget> _pantallas = [
    HomeScreen(),
    ExploradorScreen(),
    MisViajesScreen(),
    FavoritosScreen(),
    PerfilScreen(),
  ];

  static const List<NavigationDestination> _destinos = [
    NavigationDestination(
      icon: Icon(Icons.home_outlined),
      selectedIcon: Icon(Icons.home),
      label: 'Inicio',
    ),
    NavigationDestination(
      icon: Icon(Icons.explore_outlined),
      selectedIcon: Icon(Icons.explore),
      label: 'Explorar',
    ),
    NavigationDestination(
      icon: Icon(Icons.luggage_outlined),
      selectedIcon: Icon(Icons.luggage),
      label: 'Mis viajes',
    ),
    NavigationDestination(
      icon: Icon(Icons.favorite_outline),
      selectedIcon: Icon(Icons.favorite),
      label: 'Favoritos',
    ),
    NavigationDestination(
      icon: Icon(Icons.person_outline),
      selectedIcon: Icon(Icons.person),
      label: 'Perfil',
    ),
  ];

  /// Permite que otras pantallas cambien de pestaña, por ejemplo el botón
  /// "Ver todos" del inicio.
  void irA(int indice) => setState(() => _indice = indice);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(index: _indice, children: _pantallas),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _indice,
        onDestinationSelected: irA,
        destinations: _destinos,
      ),
    );
  }
}

/// Acceso al contenedor desde las pantallas hijas.
extension NavegacionContexto on BuildContext {
  void irAPestana(int indice) {
    findAncestorStateOfType<_NavegacionPrincipalState>()?.irA(indice);
  }
}
