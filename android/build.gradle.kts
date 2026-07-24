allprojects {
    repositories {
        google()
        mavenCentral()
    }
}

// Some third-party plugins read flutter.* values directly from project properties.
// Provide a fallback map so those plugins can still configure Android correctly.
extra["flutter"] = mapOf(
    "compileSdkVersion" to 36,
    "minSdkVersion" to 23,
    "targetSdkVersion" to 36,
    "ndkVersion" to "27.0.12077973",
    "versionCode" to 1,
    "versionName" to "1.0"
)

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

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}
