plugins {
    id("com.android.application")
    id("kotlin-android")
    id("dev.flutter.flutter-gradle-plugin")
    id("com.google.gms.google-services")
}

android {
    namespace = "com.stockvala.app"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
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
            isMinifyEnabled = true
            isShrinkResources = true
            proguardFiles(getDefaultProguardFile("proguard-android-optimize.txt"), "proguard-rules.pro")
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
