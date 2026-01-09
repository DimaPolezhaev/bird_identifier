plugins {
    id("com.android.application")
    id("kotlin-android")
    id("dev.flutter.flutter-gradle-plugin")
}

android {
    namespace = "com.example.bird_identifier"
    compileSdk = 36
    ndkVersion = "27.0.12077973"

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    kotlin {
        jvmToolchain(17)
    }

    defaultConfig {
        applicationId = "com.example.bird_identifier"
        minSdk = 24
        targetSdk = 36
        versionCode = 27
        versionName = "2.8.0"
    }

    // Конфигурация подписи (прямое указание ключей)
    signingConfigs {
        create("release") {
            keyAlias = "upload"
            keyPassword = "PeroZhizni2024"
            storeFile = file("C:/Users/Admin/Documents/bird_identifier/release.keystore")
            storePassword = "PeroZhizni2024"
        }
    }

    buildTypes {
        getByName("release") {
            isShrinkResources = true
            isMinifyEnabled = true
            signingConfig = signingConfigs.getByName("release")  // Используем release-ключ
            proguardFiles(
                getDefaultProguardFile("proguard-android-optimize.txt"),
                "proguard-rules.pro"
            )
        }
    }
}

flutter {
    source = "../.."
}