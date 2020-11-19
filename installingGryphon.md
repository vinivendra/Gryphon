---
layout: tutorialLayout
---

# Installing Gryphon

Welcome! Here's everything you'll need to install Gryphon and follow the tutorials on this website.

- [Option 1: Using Gryphon on macOS or Linux](installingGryphon.html#option-1-using-gryphon-on-macos-or-linux)
- [Option 2: Using Gryphon on Docker](installingGryphon.html#option-2-using-gryphon-on-docker)
- [Option 3: Using Gryphon on GitPod](installingGryphon.html#option-3-using-gryphon-on-gitpod)
- [Using different Swift versions](installingGryphon.html#using-different-swift-versions)

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
$ ./Scripts/install.sh
````

Make sure you also download any dependencies you need. Gryphon uses Ruby and the [Xcodeproj](https://github.com/CocoaPods/Xcodeproj) tool for Xcode integration. You might also want to get [Kotlin](https://github.com/JetBrains/kotlin/releases/tag/v1.4.10), [Java](https://www.oracle.com/java/technologies/javase-jre8-downloads.html), and [Android Studio](https://developer.android.com/studio/) to follow some of the tutorials.

## Option 2: Using Gryphon on Docker

[Docker](https://www.docker.com) containers are guaranteed to work the same in all compatible systems, so they can be useful if you have problems with the installation or the dependencies. The [Gryphon repository](https://github.com/vinivendra/Gryphon) includes a Dockerfile that builds a Docker container already loaded with Swift, Kotlin and Java. You can build the container with

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

Once the container is running you can build Gryphon, create a shortcut to the built binary, then run it:

```` bash
$ swift build
$ ln -s .build/debug/gryphon gryphon
$ ./gryphon "Test files/test.swift"
````

## Option 3: Using Gryphon on GitPod

The Docker container is also available as a [GitPod workspace](http://gitpod.io/#github.com/vinivendra/Gryphon) where you can use Gryphon online, without having to install it or download it. You can run Gryphon in the workspace directly with

```` bash
$ ./gryphon "Test files/test.swift"
````

## Using different Swift versions

Gryphon executables are linked with the Swift version used to build them. For example, if you install Gryphon using Swift 5.3, the resulting `gryphon` executable will be linked to the Swift 5.3 parser, and will always parse Swift code following the Swift 5.3 rules:

```` bash
$ swift --version
Apple Swift version 5.3
$ brew install vinivendra/gryphon/gryphon
$ gryphon --version
Gryphon version x.y.z, using the Swift 5.3 parser
````

If you ever need Gryphon to use a different Swift version, just install it again using the Swift version of your choice.

When using Docker, the Swift version is defined in the first line of the Dockerfile. You can change that line and call `docker build` again to change the Swift version:

````
FROM swift:5.3
````

## What's next?

Now that the installation is ready, check out how to use Gryphon's command line interface to [translate a command line program](translatingCommandLinePrograms.html) in Swift, or go straight to iOS by [translating a new iOS app to Android](translatingANewiOSAppToAndroid.html) or by [adding Gryphon to an existing app](addingGryphonToAnExistingApp.html).


