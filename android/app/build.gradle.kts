plugins {
    id("com.android.application")
    id("kotlin-android")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

android {
    namespace = "com.simasjid.simasjid_app"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_17.toString()
    }

    defaultConfig {
        // TODO: Specify your own unique Application ID (https://developer.android.com/studio/build/application-id.html).
        applicationId = "com.simasjid.simasjid_app"
        // You can update the following values to match your application needs.
        // For more information, see: https://flutter.dev/to/review-gradle-config.
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    buildTypes {
        release {
            // TODO: Add your own signing config for the release build.
            // Signing with the debug keys for now, so `flutter run --release` works.
            signingConfig = signingConfigs.getByName("debug")
        }
    }

    // Satu codebase, di-build ulang per lembaga (flavor) dengan applicationId,
    // nama app, ikon, dan splash berbeda — lihat lib/config/flavor_config.dart
    // dan README bagian "Multi-Tenant (Flavor)".
    flavorDimensions += "tenant"
    productFlavors {
        create("tpqalazharcilacap") {
            dimension = "tenant"
            applicationId = "com.simasjid.simasjid_app.tpqalazharcilacap"
            resValue("string", "app_name", "TPQ Al-Azhar Cilacap")
        }
    }
}

flutter {
    source = "../.."
}
