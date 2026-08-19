# Travelia

**Universidad del Valle de México · UVM Online**
Soluciones de Programación Móvil
Actividad 8: Proyecto Integrador — Etapa 3

**Alumno:** Eduardo Sebastián Sánchez Torres
**Profesor:** Mtro. Franklin Leonardo Tapia Penagos
Ciudad de México, 19 de agosto de 2026

---

## Introducción

Este repositorio contiene la aplicación móvil desarrollada en la tercera etapa
del Proyecto Integrador. En la Etapa 1 se identificó la problemática y se
definió la propuesta; en la Etapa 2 se seleccionaron las tecnologías y se
diseñaron las interfaces; en esta etapa corresponde construir la aplicación,
integrarla con un servicio de almacenamiento en la nube y verificar su
funcionamiento y seguridad.

## Objetivo

Desarrollar la aplicación móvil Travelia conforme a los requerimientos y
diseños establecidos previamente, implementando las operaciones básicas de un
CRUD integradas con Cloud Firestore, y comprobar su comportamiento mediante
pruebas estáticas y dinámicas de seguridad.

## Planteamiento

La planificación de un viaje obliga a consultar servicios distintos para
vuelos, hospedaje, transporte, actividades y restaurantes. Al estar la
información dispersa, el viajero alterna constantemente entre aplicaciones, lo
que incrementa el tiempo de organización y dificulta el control de reservas e
itinerarios.

Travelia centraliza esa información en una sola plataforma: permite
administrar viajes, organizar actividades por día y hora, controlar el
presupuesto, explorar destinos y guardar lugares de interés, con los datos
sincronizados en la nube y disponibles desde cualquier dispositivo.

---

## Tecnologías empleadas

| Categoría | Tecnología | Versión |
|---|---|---|
| Framework | Flutter | 3.47.0 |
| Lenguaje | Dart | 3.13.0 |
| Base de datos | Cloud Firestore | firebase_core 4.13 |
| Autenticación | Firebase Authentication | 6.5.7 |
| SDK de Android | Platform / Build-tools | API 36 / 36.0.0 |
| JDK | OpenJDK | 21 |
| Control de versiones | Git y GitHub | 2.50.1 |

---

## Operaciones CRUD

La entidad principal es el **viaje**, almacenado en `users/{uid}/viajes`.

| Operación | Pantalla | Método de Firestore |
|---|---|---|
| **Agregar** | Nuevo viaje | `add()` |
| **Recuperar** | Mis viajes · Detalle | `snapshots()` y `get()` |
| **Actualizar** | Editar viaje | `update()` |
| **Eliminar** | Detalle del viaje | `delete()` en lote |

Se implementa además un CRUD anidado sobre las actividades del itinerario, en
`users/{uid}/viajes/{viajeId}/actividades`, y operaciones de alta, consulta y
baja sobre los lugares favoritos.

### Borrado en cascada

Cloud Firestore no elimina las subcolecciones al borrar el documento que las
contiene. Un borrado directo dejaría las actividades del itinerario como
documentos huérfanos: invisibles desde la aplicación, pero presentes en la base
de datos. Por eso la eliminación se implementó como un lote atómico que
primero recoge las actividades, las marca para eliminación y borra el viaje en
la misma operación.

---

## Modelo de datos

```
users/{uid}                                   Perfil del usuario
  └── viajes/{viajeId}                        CRUD principal
        └── actividades/{actividadId}         CRUD anidado
  └── favoritos/{favoritoId}                  Lugares guardados

destinos/{destinoId}                          Catálogo público, solo lectura
```

Todos los datos personales cuelgan de `users/{uid}`, donde `uid` es el
identificador que emite Firebase Authentication. Esto permite que una sola
condición aísle por completo la información de cada cuenta.

---

## Estructura del proyecto

```
travelia/
├── lib/
│   ├── models/      Entidades de dominio
│   ├── services/    Acceso a Firebase Authentication y Cloud Firestore
│   ├── screens/     Interfaces de usuario por módulo
│   ├── theme/       Identidad visual, temas claro y oscuro
│   └── utils/       Validación y formato
├── test/            Pruebas unitarias
└── android/         Configuración de compilación y firma
```

La aplicación se organiza en capas. Las pantallas nunca invocan directamente el
SDK de Firebase: siempre pasan por la capa de servicios. Esto concentra el
control de acceso en un solo lugar y hace que las rutas se construyan siempre a
partir del identificador de la sesión activa.

---

## Funcionalidades

| Módulo | Funcionalidad |
|---|---|
| Autenticación | Registro, inicio y cierre de sesión, recuperación de contraseña |
| Viajes | Alta, consulta en tiempo real con filtros, edición y borrado |
| Itinerario | Actividades por fecha, hora, categoría y costo |
| Explorador | Búsqueda y filtrado del catálogo de destinos |
| Favoritos | Guardado y eliminación de lugares de interés |
| Perfil | Consulta y edición de nombre, idioma y moneda |
| Interfaz | Tema claro y oscuro, localización en español |

---

## Seguridad

La protección de los datos no depende del cliente. Se aplica en tres capas:

1. **Formulario** — validación de formato y rangos antes de enviar.
2. **Servicio** — las rutas se construyen a partir del identificador de la
   sesión activa, por lo que la aplicación no puede solicitar datos de otro
   usuario aunque se manipule la interfaz.
3. **Reglas de Seguridad de Cloud Firestore** — última palabra en el servidor.

Decisiones relevantes:

- Los errores de inicio de sesión se unifican en un mensaje genérico para
  evitar la enumeración de usuarios.
- Las marcas de tiempo se generan con `FieldValue.serverTimestamp()`, es decir
  con el reloj del servidor y no con el del dispositivo, que es manipulable.
- La colección `destinos` es de solo lectura para el cliente.
- Una regla final de denegación por defecto cubre cualquier ruta no
  contemplada.
- La configuración del proyecto de Firebase y las credenciales de firma no se
  versionan.

### Resultados de las pruebas

Se ejecutaron **10 pruebas estáticas y 12 dinámicas** sobre el APK de release y
sobre la aplicación en funcionamiento.

**Pruebas estáticas.** Se analizó el APK con MobSF 4.5.2, complementado con
`flutter analyze`, `apkanalyzer` y `apksigner`. El análisis del código no arrojó
errores ni advertencias, y las 16 pruebas unitarias resultaron correctas. Los
hallazgos de severidad alta reportados por la herramienta se verificaron uno a
uno contra el manifiesto real del APK y resultaron falsos positivos originados
en un fallo de lectura del `targetSdk`. Ninguno de los hallazgos de código
corresponde a código propio: todos provienen de bibliotecas de terceros.

Como resultado del análisis se aplicaron cuatro correcciones: firma con
keystore propio en lugar de la llave de depuración, deshabilitación de la copia
de seguridad, mitigación del secuestro de tareas y ofuscación del código.

**Pruebas dinámicas.** Se ejecutaron contra la API REST de Cloud Firestore, sin
pasar por la aplicación, empleando dos cuentas distintas para cruzar los
accesos. Se verificó que un usuario no puede leer ni escribir en el subárbol de
otro, que los datos inválidos son rechazados por el servidor aunque se evite el
formulario, que las rutas no declaradas quedan denegadas por defecto y que la
aplicación rechaza conexiones interceptadas por un proxy no confiable.

El resultado final fue de **12 de 12 pruebas con el comportamiento esperado**,
tras corregir un hallazgo detectado durante la primera ejecución.

---

## Compilación

La configuración del proyecto de Firebase no se versiona. Para compilar desde
cero:

1. Crear un proyecto en la consola de Firebase con Authentication por correo y
   contraseña, y Cloud Firestore en modo producción.
2. Registrar una aplicación Android con el paquete `com.uvm.travelia`.
3. Colocar el archivo descargado en `travelia/android/app/google-services.json`.
4. Generar `travelia/lib/firebase_options.dart` con `flutterfire configure`.
5. Publicar las Reglas de Seguridad en la consola.

```bash
cd travelia
flutter pub get
flutter test            # pruebas unitarias
flutter analyze         # análisis estático
flutter build apk --release --obfuscate --split-debug-info=build/symbols
```

### Nota sobre el espejo de Maven Central

`android/build.gradle.kts` consulta el espejo de Maven Central alojado por
Google antes que `mavenCentral()`. Durante el desarrollo, `repo1.maven.org`
entregaba los artefactos a unos 625 KB/s y en ocasiones dejaba la conexión
abierta sin enviar datos, bloqueando la compilación de forma indefinida. El
espejo sirve el mismo contenido de forma estable. Los tiempos de espera
configurados en `android/gradle.properties` evitan que una conexión inactiva
vuelva a detener la compilación.

---

## Conclusión

El desarrollo de esta etapa dejó claro que construir una aplicación implica
bastante más que escribir código. Buena parte del tiempo se fue en configurar
el entorno, diagnosticar fallos sin mensaje de error e interpretar los
resultados de las herramientas de análisis.

El caso más ilustrativo fue un bloqueo de la compilación que en un principio se
atribuyó a lentitud de la red. Medir el comportamiento del proceso mostró que
no avanzaba en absoluto, y localizar el punto exacto donde se detenía convirtió
un problema difuso en uno con causa identificable y solución verificable.

Algo similar ocurrió con las pruebas de seguridad. La herramienta asignó una
puntuación baja y reportó varios hallazgos de severidad alta. Revisar la regla
que los generaba y contrastarla contra el manifiesto real permitió determinar
que se trataba de falsos positivos. Un resultado automatizado es un punto de
partida, no una conclusión.

Las pruebas dinámicas aportaron la lección más útil: revelaron una
vulnerabilidad real que las pruebas estáticas no podían detectar, porque las
Reglas de Seguridad viven en el servidor y no en el binario, y porque la
aplicación se comportaba con normalidad. Ambos tipos de prueba resultan
necesarios, ya que cada uno observa aspectos que el otro no alcanza.

---

## Nota sobre el uso de inteligencia artificial

Durante el desarrollo de esta etapa se utilizó una herramienta de inteligencia
artificial como apoyo en la escritura de código, la configuración del entorno y
la redacción de la documentación.

Las decisiones de fondo del proyecto —la problemática abordada, la selección de
tecnologías, el modelo de datos, el alcance de cada etapa y el criterio para
aceptar o desestimar cada hallazgo de seguridad— corresponden al trabajo propio
del autor. Los resultados de las herramientas automatizadas fueron verificados
de forma independiente antes de incorporarse a este reporte.
