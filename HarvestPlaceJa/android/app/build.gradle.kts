plugins {
    id("com.android.application")
    id("kotlin-android")
    id("dev.flutter.flutter-gradle-plugin")
    id("com.google.gms.google-services")
}

android {
    namespace = "com.theharvestplaceja.app"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = "28.2.13676358"

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_11
        targetCompatibility = JavaVersion.VERSION_11
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_11.toString()
    }

    defaultConfig {
        applicationId = "com.theharvestplaceja.app"
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion

        // Google Play requires a higher version code for every upload.
        versionCode = 31
        versionName = "1.0.4"
    }

    val cmKeystorePath = System.getenv("CM_KEYSTORE_PATH")
    val cmKeystorePassword = System.getenv("CM_KEYSTORE_PASSWORD")
    val cmKeyAlias = System.getenv("CM_KEY_ALIAS")
    val cmKeyPassword = System.getenv("CM_KEY_PASSWORD")

    val hasCodemagicSigning =
        !cmKeystorePath.isNullOrBlank() &&
        !cmKeystorePassword.isNullOrBlank() &&
        !cmKeyAlias.isNullOrBlank() &&
        !cmKeyPassword.isNullOrBlank()

    signingConfigs {
        create("release") {
            if (hasCodemagicSigning) {
                storeFile = file(cmKeystorePath!!)
                storePassword = cmKeystorePassword
                keyAlias = cmKeyAlias
                keyPassword = cmKeyPassword
            }
        }
    }

    buildTypes {
        release {
            if (!hasCodemagicSigning) {
                throw GradleException(
                    "Release signing variables are missing. " +
                        "Set CM_KEYSTORE_PATH, CM_KEYSTORE_PASSWORD, " +
                        "CM_KEY_ALIAS, and CM_KEY_PASSWORD in Codemagic."
                )
            }

            println("Using Codemagic release signing config.")
            signingConfig = signingConfigs.getByName("release")
        }

        debug {
            signingConfig = signingConfigs.getByName("debug")
        }
    }
}

flutter {
    source = "../.."
}
