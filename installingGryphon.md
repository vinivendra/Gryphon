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

### Homebrew

The easiest way to install Gryphon is with [Homebrew](https://brew.sh), which also installs all dependencies.

```` bash
$ brew install vinivendra/gryphon/gryphon
````

### Manually

You can also skip homebrew and install Gryphon manually. You can do it using the Swift Package Manager via [Mint](https://github.com/yonaskolb/Mint):

```` bash
$ mint install vinivendra/Gryphon
````

Or building from the source:

```` bash
$ git clone https://github.com/vinivendra/Gryphon.git
$ cd Gryphon
$ ./install.sh
````

Make sure you also download any dependencies you need. Gryphon uses Ruby and the [Xcodeproj](https://github.com/CocoaPods/Xcodeproj) tool for [Xcode](https://apps.apple.com/us/app/xcode/id497799835) integration. You might also want to get [Kotlin](https://github.com/JetBrains/kotlin/releases/tag/v1.3.72), [Java](https://www.oracle.com/java/technologies/javase-jre8-downloads.html), and [Android Studio](https://developer.android.com/studio/) to follow the tutorials.

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

The first time you run the container, you can install Gryphon in it with:

```` bash
$ ./install.sh
````

## Option 3: Using Gryphon on GitPod

The Docker container is also available as a [GitPod workspace](http://gitpod.io/#github.com/vinivendra/Gryphon) where you can use Gryphon online, without having to install it or download it.

## What's next?

Now that the installation is ready, check out how to use Gryphon's command line interface to [translate a command line program](translatingCommandLinePrograms.html) in Swift, or go straight to iOS by [translating a new iOS app to Android](translatingANewiOSAppToAndroid.html) or by [adding Gryphon to an existing app](addingGryphonToAnExistingApp.html).


