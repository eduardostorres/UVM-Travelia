// Espejo de Maven Central alojado por Google.
//
// En la red usada para este proyecto, repo1.maven.org (Maven Central detras
// de Cloudflare) entrega los artefactos a ~625 KB/s y en ocasiones deja la
// conexion abierta sin enviar datos, lo que bloquea la compilacion de forma
// indefinida. El espejo de Google sirve exactamente el mismo contenido a
// ~8 MB/s de manera estable, por lo que se consulta primero y se conserva
// mavenCentral() como respaldo.
val espejoMavenCentral = "https://maven-central.storage-download.googleapis.com/maven2"

allprojects {
    repositories {
        google()
        // Sustituye a mavenCentral(): sirve el mismo contenido de forma
        // estable. Se omite mavenCentral() a proposito, porque al dejarlo
        // como respaldo Gradle vuelve a caer en el y la compilacion se
        // bloquea de nuevo.
        maven { url = uri(espejoMavenCentral) }
    }
}

val newBuildDir: Directory =
    rootProject.layout.buildDirectory
        .dir("../../build")
        .get()
rootProject.layout.buildDirectory.value(newBuildDir)

subprojects {
    val newSubprojectBuildDir: Directory = newBuildDir.dir(project.name)
    project.layout.buildDirectory.value(newSubprojectBuildDir)
}
subprojects {
    project.evaluationDependsOn(":app")
}

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}
