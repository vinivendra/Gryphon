---
layout: tutorialLayout
---

# Installing Gryphon

## Step 1: Installing dependencies

### On macOS

For Gryphon to work properly, it depends on three external components:

1. The [Swift](https://swift.org/download/) compiler;

2. [Xcode](https://apps.apple.com/us/app/xcode/id497799835);

3. Ruby and [Xcodeproj](https://github.com/CocoaPods/Xcodeproj) (for Xcode integration) which can be installed with [homebrew](https://brew.sh):

    ```` bash
    $ brew install ruby
    $ [sudo] gem install xcodeproj
    ````

This guide will also assume you have:

1. The Kotlin compiler (for building Kotlin scripts), which can be installed via the [GitHub releases](https://github.com/JetBrains/kotlin/releases/tag/v1.3.72) or with [homebrew](https://brew.sh):

    ```` bash
    $ brew install kotlin
    ````

2. The [Java Runtime Environment](https://www.oracle.com/java/technologies/javase-jre8-downloads.html) (for running Kotlin programs);

3. And [Android Studio](https://developer.android.com/studio/), for creating Android apps.

### On Docker

Gryphon comes with a Dockerfile that configures a [Docker](https://www.docker.com) container. The container is based on the official `swift:latest` container, and includes the Swift compiler, the Kotlin compiler, and the Java Runtime Environment.

Docker users can translate any Swift files that don't import the iOS frameworks, but they don't have access to Xcode or the iOS SDK. Since there's no Xcode support, the Docker container does not include Ruby or Xcodeproj.

To clone the repository and build the Docker container:

```` bash
$ git clone https://github.com/vinivendra/Gryphon.git
$ cd Gryphon
$ docker build -t swift_ubuntu .
````

To run the container:

```` bash
$ docker run -it --rm --privileged -v /path/to/Gryphon/:/app/Gryphon swift_ubuntu
````

where `/path/to/Gryphon/` should be an absolute path to the current folder (i.e. the cloned Gryphon repository).

### On Linux

As with Docker, Linux users can translate any Swift files that don't import the iOS frameworks, but they don't have access to Xcode or the iOS SDK.

Gryphon on Linux depends on:

1. The [Swift](https://swift.org/download/) compiler;

2. The Kotlin compiler, which can be installed via the [GitHub releases](https://github.com/JetBrains/kotlin/releases/tag/v1.3.72);

3. And the [Java Runtime Environment](https://www.oracle.com/java/technologies/javase-jre8-downloads.html).

It can be complicated to install these dependencies depending on your Linux distribution. If you're having difficulties, consider using [Docker](https://www.docker.com).

## Step 2: Cloning and running the installation script

Open the terminal and run the commands below to clone the repository and run the installation script.

Note that if you're using Docker, you have already cloned the repository. Just run the script with the last command.

```` bash
$ git clone https://github.com/vinivendra/Gryphon.git
$ cd Gryphon
$ bash install.sh
````

## Step 3: Ensuring the installation worked

We can try out the installation by checking its version:

```` bash
$ gryphon --version
Gryphon version 0.5-beta
````

If everything works, then the cloned repository can be deleted:

```` bash
$ cd ..
$ rm -rf Gryphon
````

## What's next?

Now that the installation is ready, check out how to use Gryphon's command line interface to [translate a command line program](translatingCommandLinePrograms.html) in Swift, or go straight to iOS by [translating a new iOS app to Android](translatingANewiOSAppToAndroid.html) or by [adding Gryphon to an existing app](addingGryphonToAnExistingApp.html).


