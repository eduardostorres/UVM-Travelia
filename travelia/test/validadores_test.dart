import 'package:flutter_test/flutter_test.dart';
import 'package:travelia/models/viaje.dart';
import 'package:travelia/utils/validadores.dart';

/// Pruebas unitarias de la capa de validación de Travelia.
///
/// Forman parte de las pruebas estáticas de la Etapa 3: verifican que la
/// aplicación rechace entradas inválidas antes de enviarlas a Cloud
/// Firestore, complementando lo que imponen las Reglas de Seguridad.
void main() {
  group('Validadores.correo', () {
    test('acepta un correo con formato válido', () {
      expect(Validadores.correo('eduardo@uvm.edu.mx'), isNull);
    });

    test('rechaza un correo vacío', () {
      expect(Validadores.correo(''), isNotNull);
    });

    test('rechaza un correo sin dominio', () {
      expect(Validadores.correo('eduardo@'), isNotNull);
    });

    test('rechaza un correo sin arroba', () {
      expect(Validadores.correo('eduardo.uvm.mx'), isNotNull);
    });
  });

  group('Validadores.contrasena', () {
    test('acepta una contraseña con letras y números', () {
      expect(Validadores.contrasena('Travelia2026'), isNull);
    });

    test('rechaza contraseñas de menos de 8 caracteres', () {
      expect(Validadores.contrasena('Trav1'), isNotNull);
    });

    test('rechaza contraseñas sin números', () {
      expect(Validadores.contrasena('SoloLetras'), isNotNull);
    });

    test('rechaza contraseñas sin letras', () {
      expect(Validadores.contrasena('12345678'), isNotNull);
    });
  });

  group('Validadores.confirmacion', () {
    test('acepta contraseñas coincidentes', () {
      expect(Validadores.confirmacion('Travelia2026', 'Travelia2026'), isNull);
    });

    test('rechaza contraseñas distintas', () {
      expect(Validadores.confirmacion('Travelia2026', 'Otra2026'), isNotNull);
    });
  });

  group('Validadores.monto', () {
    test('acepta un monto positivo', () {
      expect(Validadores.monto('15000'), isNull);
    });

    test('rechaza montos negativos, igual que las Reglas de Seguridad', () {
      expect(Validadores.monto('-100'), isNotNull);
    });

    test('rechaza texto que no es numérico', () {
      expect(Validadores.monto('mucho dinero'), isNotNull);
    });
  });

  group('Modelo Viaje', () {
    test('calcula la duración incluyendo el día de inicio', () {
      final viaje = Viaje(
        id: 'x',
        titulo: 'Japón 2026',
        destino: 'Tokio',
        pais: 'Japón',
        fechaInicio: DateTime(2026, 10, 1),
        fechaFin: DateTime(2026, 10, 10),
        presupuesto: 45000,
        moneda: 'MXN',
        estado: EstadoViaje.proximo,
      );
      expect(viaje.duracionDias, 10);
      expect(viaje.destinoCompleto, 'Tokio, Japón');
    });

    test('serializa el estado con el valor que esperan las reglas', () {
      final mapa = Viaje.nuevo().copiarCon(estado: EstadoViaje.enCurso).aMapa();
      expect(mapa['estado'], 'en_curso');
    });

    test('EstadoViaje.desdeValor usa "proximo" ante un valor desconocido', () {
      expect(EstadoViaje.desdeValor('inventado'), EstadoViaje.proximo);
    });
  });
}
