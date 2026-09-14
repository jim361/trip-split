import java.util.Base64

plugins {
    id("com.android.application")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

val dartDefines = (project.findProperty("dart-defines") as? String)
    ?.split(",")?.mapNotNull { value ->
        val pair = String(Base64.getDecoder().decode(value), Charsets.UTF_8).split("=", limit = 2)
        if (pair.size == 2) pair[0] to pair[1] else null
    }?.toMap() ?: emptyMap()
val mapsKey = dartDefines["GOOGLE_MAPS_API_KEY"].orEmpty()
if (dartDefines["ENABLE_GOOGLE_MAPS"] == "true" && mapsKey.isBlank()) {
    throw GradleException("ENABLE_GOOGLE_MAPS requires GOOGLE_MAPS_API_KEY in local dart defines")
}

android {
    namespace = "com.jim361.tripsplit"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    defaultConfig {
        applicationId = "com.jim361.tripsplit"
        manifestPlaceholders["googleMapsApiKey"] = mapsKey
        minSdk = 24
        targetSdk = 36
        // Uses the version code from pubspec.yaml. When using split APKs, 1000 * ABI_VERSION
        // is added automatically by Flutter. (https://developer.android.com/studio/build/configure-apk-splits#configure-APK-versions)
        // You can force using the value of versionCode by specifying the `-P force-version-code-ignoring-abi=true`
        // flag during build.
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    buildTypes {
        release {
            // 내부 smoke build만 허용합니다. 배포 전 TASK-09에서 실제 signing config로 교체합니다.
            signingConfig = signingConfigs.getByName("debug")
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
