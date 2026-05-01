allprojects {
    repositories {
        // Tencent mirror: verified accessible from Iran (Apr 2026)
        maven { url = uri("https://mirrors.cloud.tencent.com/nexus/repository/maven-public") }
        google()
        mavenCentral()
        // Flutter engine artifacts (accessible from Iran)
        maven { url = uri("https://storage.googleapis.com/download.flutter.io") }
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
