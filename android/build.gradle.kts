import com.android.build.gradle.LibraryExtension

allprojects {
    repositories {
        maven { url = uri("https://maven.aliyun.com/repository/google") }
        maven { url = uri("https://maven.aliyun.com/repository/central") }
        maven { url = uri("https://maven.aliyun.com/repository/public") }
        google()
        mavenCentral()
    }
}

val newBuildDir: Directory =
    rootProject.layout.buildDirectory
        .dir("../../build")
        .get()
rootProject.layout.buildDirectory.value(newBuildDir)

subprojects {
    val newSubprojectBuildDir: Directory = newBuildDir.dir(project.name)
    project.layout.buildDirectory.value(newSubprojectBuildDir)
}
subprojects {
    project.evaluationDependsOn(":app")
}

fun Project.forceInstalledNdk() {
    val androidExt = extensions.findByName("android") ?: return
    val setter = androidExt.javaClass.methods.firstOrNull {
        it.name == "setNdkVersion" && it.parameterCount == 1
    }
    setter?.invoke(androidExt, "27.3.13750724")
}

fun Project.forceCompileSdk() {
    extensions.findByType(LibraryExtension::class.java)?.compileSdk = 35
}

fun Project.alignJvm17() {
    tasks.withType<JavaCompile>().configureEach {
        sourceCompatibility = JavaVersion.VERSION_17.toString()
        targetCompatibility = JavaVersion.VERSION_17.toString()
    }
}

fun Project.fixTesseractDuplicatePlugin() {
    if (name != "tesseract_ocr") {
        return
    }
    tasks.matching { it.name.startsWith("compile") && it.name.contains("Kotlin") }.configureEach {
        enabled = false
    }
}

subprojects {
    if (state.executed) {
        forceInstalledNdk()
        forceCompileSdk()
        alignJvm17()
        fixTesseractDuplicatePlugin()
    } else {
        afterEvaluate {
            forceInstalledNdk()
            forceCompileSdk()
            alignJvm17()
            fixTesseractDuplicatePlugin()
        }
    }
}

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}
