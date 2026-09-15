allprojects {
    repositories {
        google()
        mavenCentral()
    }
}

val localBuildDir = providers.environmentVariable("SIGNSPEAK_BUILD_DIR")
val newBuildDir: Directory =
    if (localBuildDir.isPresent) {
        layout.projectDirectory.dir(localBuildDir.get())
    } else {
        rootProject.layout.buildDirectory
            .dir("../../build")
            .get()
    }
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
