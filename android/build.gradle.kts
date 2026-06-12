allprojects {
    repositories {
        // Local repo with pre-cached plugin artifacts (Iran-friendly, instant resolution)
        maven { url = uri(java.io.File(System.getProperty("user.home"), ".gradle/local-maven-repo").toURI()) }
        // Tencent mirror: verified accessible from Iran
        maven { url = uri("https://mirrors.cloud.tencent.com/nexus/repository/maven-public") }
        google()
        mavenCentral()
        // Flutter engine artifacts
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
