import java.util.Properties

plugins {
    id("com.android.application")
    // START: FlutterFire Configuration
    id("com.google.gms.google-services")
    // END: FlutterFire Configuration
    id("kotlin-android")
    id("dev.flutter.flutter-gradle-plugin")
}

// .env 파일 읽기 함수 추가
fun loadEnvFile(): Properties {
    val envFile = file("../../.env")
    val properties = Properties()
    if (envFile.exists()) {
        envFile.inputStream().use { properties.load(it) }
    }
    return properties
}

val keyProperties = Properties()
val keyPropertiesFile = rootProject.file("key.properties")
if (keyPropertiesFile.exists()) {
    keyPropertiesFile.inputStream().use { keyProperties.load(it) }
}

android {
    namespace = "com.example.frontend"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = "29.0.13113456"

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_11
        targetCompatibility = JavaVersion.VERSION_11
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_11.toString()
    }

    defaultConfig {
        applicationId = "com.example.frontend"
        //minSdkVersion flutter.minSdkVersion
        minSdkVersion(24)
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName

        // .env에서 값들 읽어오기
        val envProps = loadEnvFile()
        val backendUrl = envProps.getProperty("BACKEND_URL") ?: "http://localhost:8080"
        val nativeAppKey = envProps.getProperty("NATIVE_APP_KEY") ?: "URL"

        // URL에서 호스트만 추출
        val backendHost = backendUrl.replace(Regex("^https?://"), "").replace(Regex(":.*$"), "")

        manifestPlaceholders["NATIVE_APP_KEY"] = nativeAppKey
        manifestPlaceholders["BACKEND_HOST"] = backendHost

        println("🔧 Build config:")
        println("   Backend URL: $backendUrl")
        println("   Backend Host: $backendHost")
        println("   Native App Key: ${if (nativeAppKey.isNotEmpty()) "설정됨" else "미설정"}")
    }

    buildTypes {
        getByName("release") {
            isMinifyEnabled = true
            isShrinkResources = true
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

dependencies {
    implementation("com.google.mlkit:text-recognition:16.0.1")
    implementation("com.google.mlkit:text-recognition-korean:16.0.1")
}
