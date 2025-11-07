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
        sourceCompatibility = JavaVersion.VERSION_17  // ← ОБНОВИТЬ с 11 до 17
        targetCompatibility = JavaVersion.VERSION_17  // ← ОБНОВИТЬ с 11 до 17
    }

    kotlin {
        jvmToolchain(17)  // ← ОБНОВИТЬ с 11 до 17
    }

    defaultConfig {
        applicationId = "com.example.bird_identifier"
        minSdk = 24
        targetSdk = 36
        versionCode = 27
        versionName = "2.7.5"
    }

    buildTypes {
        getByName("release") {
            isShrinkResources = true
            isMinifyEnabled = true
            proguardFiles(
                getDefaultProguardFile("proguard-android-optimize.txt"),
                "proguard-rules.pro"
            )
            signingConfig = signingConfigs.getByName("debug")
        }
    }
}

flutter {
    source = "../.."
}