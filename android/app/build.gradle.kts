import java.util.Properties

plugins {
    id("com.android.application")
    id("com.google.gms.google-services")
    id("dev.flutter.flutter-gradle-plugin")
}

android {
    namespace = "com.dali951.task_tracker_admin"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    defaultConfig {
        applicationId = "com.dali951.task_tracker_admin"
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        val verName = flutter.versionName
        val parts = verName.split(".")
        val major = parts.getOrElse(0) { "0" }.toIntOrNull() ?: 0
        val minor = parts.getOrElse(1) { "0" }.toIntOrNull() ?: 0
        val patch = parts.getOrElse(2) { "0" }.toIntOrNull() ?: 0
        versionCode = major * 10000 + minor * 100 + patch
        versionName = verName
    }

    buildTypes {
        release {
            val keyPropertiesFile = rootProject.file("key.properties")
            if (keyPropertiesFile.exists()) {
                val keyProperties = Properties()
                keyPropertiesFile.inputStream().use { keyProperties.load(it) }
                signingConfig = signingConfigs.create("release") {
                    storeFile = file(keyProperties["storeFile"] as String)
                    storePassword = keyProperties["storePassword"] as String
                    keyAlias = keyProperties["keyAlias"] as String
                    keyPassword = keyProperties["keyPassword"] as String
                }
            } else {
                signingConfig = signingConfigs.getByName("debug")
            }
        }
    }
}

kotlin {
    compilerOptions {
        jvmTarget = org.jetbrains.kotlin.gradle.dsl.JvmTarget.JVM_17
    }
}

flutter {
    source = "../.."
}
