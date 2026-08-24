import java.io.FileInputStream
import java.util.Properties

plugins {
    id("com.android.application")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

// Release signing credentials, kept out of the repo. `key.properties` and any
// `*.jks` are gitignored (see android/.gitignore); nothing here has a default
// that would silently commit a password.
//
// A fresh clone has no key.properties, and must still be able to build and run
// debug — so its absence is a supported state, not an error. In that case the
// release build falls back to the Android debug key and is fit for local
// smoke-testing only, never for anything you hand to someone else.
val keystorePropertiesFile = rootProject.file("key.properties")
val hasReleaseKeystore = keystorePropertiesFile.exists()
val keystoreProperties = Properties().apply {
    if (hasReleaseKeystore) {
        FileInputStream(keystorePropertiesFile).use { load(it) }
    }
}

android {
    namespace = "com.cashcompass.cash_compass"
    compileSdk = flutter.compileSdkVersion

    // NDK 28.2.13676358, required by the `jni` plugin that supabase_flutter
    // pulls in. It must be installed manually with the new Android CLI:
    //   android sdk install "ndk/28.2.13676358"
    // Gradle's own auto-install fails here because it still calls the
    // deprecated sdkmanager with the old `ndk;<version>` semicolon syntax,
    // which the replacement CLI parses as two separate package names.
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    defaultConfig {
        applicationId = "com.cashcompass.cash_compass"
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        // Uses the version code from pubspec.yaml. When using split APKs, 1000 * ABI_VERSION
        // is added automatically by Flutter. (https://developer.android.com/studio/build/configure-apk-splits#configure-APK-versions)
        // You can force using the value of versionCode by specifying the `-P force-version-code-ignoring-abi=true`
        // flag during build.
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    signingConfigs {
        if (hasReleaseKeystore) {
            create("release") {
                keyAlias = keystoreProperties.getProperty("keyAlias")
                keyPassword = keystoreProperties.getProperty("keyPassword")
                storeFile = file(keystoreProperties.getProperty("storeFile"))
                storePassword = keystoreProperties.getProperty("storePassword")
            }
        }
    }

    buildTypes {
        release {
            signingConfig = if (hasReleaseKeystore) {
                signingConfigs.getByName("release")
            } else {
                logger.warn(
                    "WARNING: android/key.properties not found — signing the release " +
                        "build with the Android debug key. Do not distribute this APK."
                )
                signingConfigs.getByName("debug")
            }

            // R8 only reaches the Java/Kotlin plugin layer; the Dart code is
            // already compiled to native in libapp.so, and is obfuscated
            // separately via `flutter build apk --obfuscate`. The win here is
            // mostly dead-code and resource stripping.
            isMinifyEnabled = true
            isShrinkResources = true
            proguardFiles(
                getDefaultProguardFile("proguard-android-optimize.txt"),
                "proguard-rules.pro",
            )
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
