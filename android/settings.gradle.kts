pluginManagement {
    resolutionStrategy {
        eachPlugin {
            if (requested.id.id == "com.android.application" || requested.id.id == "com.android.library") {
                useModule("com.android.tools.build:gradle:${requested.version}")
            }
            if (requested.id.id == "org.jetbrains.kotlin.android") {
                useModule("org.jetbrains.kotlin:kotlin-gradle-plugin:${requested.version}")
            }
            if (requested.id.id == "org.jetbrains.kotlin.jvm") {
                useModule("org.jetbrains.kotlin:kotlin-gradle-plugin:${requested.version}")
            }
            if (requested.id.id == "org.jetbrains.kotlin.kapt") {
                useModule("org.jetbrains.kotlin:kotlin-gradle-plugin:${requested.version}")
            }
            if (requested.id.id == "com.google.gms.google-services") {
                useModule("com.google.gms:google-services:${requested.version}")
            }
            if (requested.id.id == "org.gradle.kotlin.kotlin-dsl") {
                useModule("org.gradle.kotlin:gradle-kotlin-dsl-plugins:${requested.version}")
            }
        }
    }
    val flutterSdkPath = run {
        val properties = java.util.Properties()
        file("local.properties").inputStream().use { properties.load(it) }
        val flutterSdkPath = properties.getProperty("flutter.sdk")
        require(flutterSdkPath != null) { "flutter.sdk not set in local.properties" }
        flutterSdkPath
    }

    includeBuild("$flutterSdkPath/packages/flutter_tools/gradle")

    repositories {
        // Local repo with pre-cached plugin artifacts (Iran-friendly, instant resolution)
        maven { url = uri(java.io.File(System.getProperty("user.home"), ".gradle/local-maven-repo").toURI()) }
        // Tencent mirror: verified accessible from Iran
        maven { url = uri("https://mirrors.cloud.tencent.com/nexus/repository/maven-public") }
        google()
        mavenCentral()
    }
}

dependencyResolutionManagement {
    repositoriesMode.set(RepositoriesMode.PREFER_PROJECT)
    repositories {
        // Local repo with pre-cached plugin artifacts (Iran-friendly, instant resolution)
        maven { url = uri(java.io.File(System.getProperty("user.home"), ".gradle/local-maven-repo").toURI()) }
        // Tencent mirror: verified accessible from Iran
        maven { url = uri("https://mirrors.cloud.tencent.com/nexus/repository/maven-public") }
        google()
        mavenCentral()
    }
}

plugins {
    id("dev.flutter.flutter-plugin-loader") version "1.0.0"
    id("com.android.application") version "8.9.2" apply false
    id("org.jetbrains.kotlin.android") version "2.1.21" apply false
    id("com.google.gms.google-services") version "4.4.1" apply false
}

include(":app")
