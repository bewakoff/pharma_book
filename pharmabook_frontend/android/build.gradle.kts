allprojects {
    repositories {
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
    project.layout.buildDirectory.value(
        newBuildDir.dir(project.name)
    )
}

tasks.register<Delete>("clean") {
    doLast {
        delete(rootProject.layout.buildDirectory)
    }
}