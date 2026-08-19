# Reglas de R8 para Travelia
#
# Los plugins de Firebase y Flutter incluyen sus propias reglas de consumo,
# por lo que no es necesario repetirlas. Aqui solo se conservan las clases
# que se resuelven por reflexion y que R8 no puede detectar analizando el
# codigo.

# Flutter
-keep class io.flutter.app.** { *; }
-keep class io.flutter.plugin.** { *; }
-keep class io.flutter.embedding.** { *; }

# Firebase: los modelos se serializan por reflexion
-keepattributes Signature
-keepattributes *Annotation*
-keepclassmembers class * {
    @com.google.firebase.firestore.PropertyName <fields>;
}

# Conservar los numeros de linea para poder interpretar los reportes de fallo
-keepattributes SourceFile,LineNumberTable
-renamesourcefileattribute SourceFile

# Play Core: el motor de Flutter referencia estas clases para la carga de
# modulos diferidos (deferred components). Travelia no usa esa funcion, por
# lo que la libreria no esta incluida y R8 no puede resolver las referencias.
# Se le indica que no advierta sobre ellas en lugar de agregar una
# dependencia que la aplicacion nunca ejecutaria.
-dontwarn com.google.android.play.core.**
-dontwarn io.flutter.embedding.engine.deferredcomponents.**
-dontwarn io.flutter.embedding.android.FlutterPlayStoreSplitApplication
