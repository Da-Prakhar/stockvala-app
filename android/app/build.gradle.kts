plugins {
    id("com.android.application")
    id("kotlin-android")
    id("dev.flutter.flutter-gradle-plugin")
    // google-services removed: no per-brand Firebase config exists and the app
    // never calls Firebase.initializeApp — re-add with a rhynofx
    // google-services.json when push notifications are set up.
}

android {
    namespace = "com.stockvala.app"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        isCoreLibraryDesugaringEnabled = true
        sourceCompatibility = JavaVersion.VERSION_11
        targetCompatibility = JavaVersion.VERSION_11
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_11.toString()
    }

    defaultConfig {
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    // ── White-label product flavors ──────────────────────────────────────────
    // Each flavor = one client brand with its own package ID, name, and API domain.
    // Build: ./gradlew assembleAlphatradeRelease
    //   OR:  flutter build apk --flavor alphatrade --dart-define=BRAND=alphatrade
    flavorDimensions += "brand"

    productFlavors {
        create("stockvala") {
            dimension = "brand"
            applicationId = "com.stockvala.app"
            resValue("string", "app_name", "StockVala")
        }
        create("alphatrade") {
            dimension = "brand"
            applicationId = "com.alphatrade.app"
            resValue("string", "app_name", "AlphaTrade")
        }
        create("goldfx") {
            dimension = "brand"
            applicationId = "com.goldfx.app"
            resValue("string", "app_name", "GoldFX")
        }
        create("nexustrade") {
            dimension = "brand"
            applicationId = "com.nexustrade.app"
            resValue("string", "app_name", "NexusTrade")
        }
        create("rhynofx") {
            dimension = "brand"
            applicationId = "com.rhynofx.app"
            resValue("string", "app_name", "RhynoFX")
        }
    }

    buildTypes {
        release {
            // Minification off for test distribution — turn back on with a
            // reviewed proguard config before any store release.
            isMinifyEnabled = false
            isShrinkResources = false
            signingConfig = signingConfigs.getByName("debug") // replace with release keystore
        }
        debug {
            isDebuggable = true
        }
    }
}

flutter {
    source = "../.."
}


dependencies {
    coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.1.4")
}
