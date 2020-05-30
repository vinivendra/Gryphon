---
layout: tutorialLayout
---

# Installing Gryphon

Welcome! Here's everything you'll need to install Gryphon and follow the tutorials on this website.

- [Option 1: Using Gryphon on macOS or Linux](installingGryphon.html#option-1-using-gryphon-on-macos-or-linux)
	- [Step 1: Installing Swift](installingGryphon.html#step-1-installing-swift)
	- [Step 2: Installing Gryphon](installingGryphon.html#step-2-installing-gryphon)
	- [Step 3: Bonus dependencies](installingGryphon.html#step-3-bonus-dependencies)
- [Option 2: Using Gryphon on Docker](installingGryphon.html#option-2-using-gryphon-on-docker)
- [Option 3: Using Gryphon on GitPod](installingGryphon.html#option-3-using-gryphon-on-gitpod)

## Option 1: Using Gryphon on macOS or Linux

### Step 1: Installing Swift

First of all, Gryphon translates Swift code - and, for that, it needs the Swift compiler. If you don't have it already, download the standalone version [here](https://swift.org/download/) or get the one that's bundled with [Xcode](https://apps.apple.com/us/app/xcode/id497799835). In any case, make sure you're running Swift 5.1 or 5.2:

```` bash
$ swift --version
Apple Swift version 5.2.2 (swiftlang-1103.0.32.6 clang-1103.0.32.51)
Target: x86_64-apple-darwin19.4.0
````

### Step 2: Installing Gryphon

Gryphon supports the Swift package manager, so the easiest way to install it is probably with Mint. If you're on macOS, you can get Mint using [homebrew](https://brew.sh):

```` bash
$ brew install mint
$ mint install vinivendra/Gryphon
$ gryphon --version
Gryphon version 0.6.1
````

If you're on Linux (or if you don't wanna use Mint), it might be easier to install Gryphon from the source:

```` bash
$ git clone https://github.com/vinivendra/Gryphon.git
$ cd Gryphon
$ bash install.sh
$ gryphon --version
Gryphon version 0.6.1
````

### Step 3: Bonus dependencies

If you don't have them already, you may also want to install the Kotlin compiler (for compiling Kotlin code) and the Java Runtime Environment (for running Kotlin code). You can get the Kotlin compiler via the [GitHub releases](https://github.com/JetBrains/kotlin/releases/tag/v1.3.72) or with [homebrew](https://brew.sh):

```` bash
$ brew install kotlin
````

And you can get the Java Runtime Environment [here](https://www.oracle.com/java/technologies/javase-jre8-downloads.html).

If you're planning on integrating Gryphon with [Xcode](https://apps.apple.com/us/app/xcode/id497799835) in your computer, you'll also need the [Xcodeproj](https://github.com/CocoaPods/Xcodeproj) tool. You can get Xcodeproj using Ruby, and you can get Ruby using [homebrew](https://brew.sh):

```` bash
$ brew install ruby
$ [sudo] gem install xcodeproj
````

Finally, if you're planning on compiling and running Android apps, you might need [Android Studio](https://developer.android.com/studio/).

## Option 2: Using Gryphon on Docker

The [Gryphon repository](https://github.com/vinivendra/Gryphon) includes a Dockerfile that builds a [Docker](https://www.docker.com) container already loaded with Swift, Kotlin and Java. Docker containers are guaranteed to work the same in all compatible systems, so they can be useful if you have problems with the installation or the dependencies. You can build the container with

```` bash
$ git clone https://github.com/vinivendra/Gryphon.git
$ cd Gryphon
$ docker build -t gryphon .
````

Then, whenever you want to run the container:

```` bash
$ docker run -it --rm --privileged -v /path/to/Gryphon/:/app/Gryphon gryphon
````

where `/path/to/Gryphon/` should be an absolute path to the current folder (i.e. the cloned Gryphon repository).

The first time you run the container, you can install Gryphon with:

```` bash
$ bash install.sh
$ gryphon --version
Gryphon version 0.6.1
````

## Option 3: Using Gryphon on GitPod

The Docker container is also available as a [GitPod workspace](http://gitpod.io/#github.com/vinivendra/Gryphon) where you can use Gryphon online, without having to install it or download it.

## What's next?

Now that the installation is ready, check out how to use Gryphon's command line interface to [translate a command line program](translatingCommandLinePrograms.html) in Swift, or go straight to iOS by [translating a new iOS app to Android](translatingANewiOSAppToAndroid.html) or by [adding Gryphon to an existing app](addingGryphonToAnExistingApp.html).


