<img src="https://github.com/vinivendra/Gryphon/raw/master/Gryphon%20Logo.svg" alt="Gryphon logo" height="70">

## The Swift to Kotlin translator

[![Swift package manager compatible](https://img.shields.io/badge/SPM-compatible-brightgreen)](https://www.firsttimersonly.com/)
[![open ethical](https://img.shields.io/badge/open-ethical-%234baaaa)](https://ethicalsource.dev)
[![licensed ethically](https://img.shields.io/badge/licensed-ethically-%234baaaa)](https://ethicalsource.dev)
[![Gitpod Ready-to-Code](https://img.shields.io/badge/Gitpod-Ready--to--Code-blue?logo=gitpod)](https://gitpod.io/#https://github.com/vinivendra/Gryphon)
[![first-timers-only](https://img.shields.io/badge/first--timers--only-friendly-blue.svg)](https://www.firsttimersonly.com/)
[![Follow on Twitter](https://img.shields.io/twitter/follow/gryphonblog?label=Follow&style=social)](https://twitter.com/gryphonblog)

Gryphon is a program that translates Swift code into Kotlin code. It was created to enable mobile app developers to share parts of an iOS app's codebase with Android.

- **Risk-free.** Stop using Gryphon whenever you want - you'll still be able to read and understand your Kotlin code, even the computer-generated parts.
- **No editing needed.** Translated Kotlin files work the same as the Swift files they came from.
- **Xcode integration.** Translate your iOS code to Android, compile the Android app, and see Kotlin's errors and warnings in the Swift lines that originated them - all without leaving Xcode.
- **Custom-made.** Use special comments and templates to customize your Kotlin translation, and use any platform-specific features you want - even in translated source files.

## 👍 Status

Gryphon is now in preview! 🎉

This means the main systems and ideas have already been implemented - for instance, it's been translating its own codebase for a while now. However, new users might still find some new bugs to be fixed. If that's the case, feel free to report a [new issue](https://github.com/vinivendra/Gryphon/issues/new/choose) on GitHub.

## 📲 Installing

Gryphon supports both **macOS** and **Linux**. You can install it with:

### Mint

Use [Mint](https://github.com/yonaskolb/Mint) to install programs that use the Swift package manager:

```` bash
$ brew install mint
$ mint install vinivendra/Gryphon
$ gryphon --version
Gryphon version 0.7
````

### GitPod

Try it out on [GitPod](https://www.gitpod.io) before downloading:

[![Open in Gitpod](https://gitpod.io/button/open-in-gitpod.svg)](https://gitpod.io/#https://github.com/vinivendra/Gryphon)

### Installation script

Clone the repo run the installation script:

```` bash
$ git clone https://github.com/vinivendra/Gryphon.git
$ cd Gryphon
$ bash install.sh
$ gryphon --version
Gryphon version 0.7
````

### Docker

Install it in a [Docker](https://www.docker.com) container:

```` bash
$ git clone https://github.com/vinivendra/Gryphon.git
$ cd Gryphon
$ docker build -t gryphon .
$ docker run -it --rm --privileged -v /absolute/path/to/current/directory/:/app/Gryphon gryphon
# bash install.sh
# gryphon --version
Gryphon version 0.7
````


## 🔨 Xcode integration

Users on macOS can also take advantage of Xcode integration; for that, they'll need [Xcodeproj](https://github.com/CocoaPods/Xcodeproj):

```` bash
$ [sudo] gem install xcodeproj
````

## 📖 Guides

Check out the [Tutorial](https://vinivendra.github.io/Gryphon/gettingStarted.html) to get started. It covers the basic information needed to begin using Gryphon, whether you want to [translate command line programs](https://vinivendra.github.io/Gryphon/translatingCommandLinePrograms.html), [translate a new iOS app to Android](https://vinivendra.github.io/Gryphon/translatingANewiOSAppToAndroid.html), or [add Gryphon to an existing app](https://vinivendra.github.io/Gryphon/addingGryphonToAnExistingApp.html).

There are also more advanced guides on  [using collections](https://vinivendra.github.io/Gryphon/collections.html), [using translation comments](https://vinivendra.github.io/Gryphon/translationComments.html), and [using templates](https://vinivendra.github.io/Gryphon/templates.html)


## 📘 Frequently asked questions

#### What is Gryphon?

Gryphon is a command line application that can translate Swift code into Kotlin code. It was especially designed to enable app developers to translate platform-independent parts of their iOS apps into code they can use in their Android apps.

#### Can I compile and run the translated code or do I need to fix it first?

Gryphon's output code is meant to behave just like the input code that created it. It's still possible technically to generate Kotlin code that doesn't compile - for instance, if you try to translate unsupported Swift features, or if there's a bug - but as a rule, **you should be able to translate, compile and run supported code without the need for post-translation edits**.

#### Will I be able to understand the translated code?

One of Gryphon's main goals is to make sure translated code can be understood by human beings. As a rule, **if you understand the input Swift code, you should also be able to understand the translated Kotlin code** - if you don't, feel free to [file a bug](https://github.com/vinivendra/Gryphon/issues).

This is done within some realistic constraints: the priority is that the translated code has to behave correctly, for instance. Gryphon attempts to find a "reasonably understandable Kotlin" middle ground somewhere between "machine-code-like Kotlin" and "perfectly idiomatic Kotlin".

#### Can I translate anything written in Swift?

Gryphon's support for Swift features is constantly evolving. **It is currently capable of translating many of the main features one might expect** - classes, structs, enums, closures, extensions, protocols, etc - enough that it currently translates around 97% of its own codebase (the other 3% are platform-specific files). Some Swift features are just waiting to be implemented, while others can't be translated to Kotlin and may never be supported.

#### Can Gryphon help translate my existing iOS app?

**Yes - but it will need some adaptations** (though probably less than your average multiplatform framework). This depends on your application - how similar app's architecture is to its Android counterpart, how often your code uses Swift features unsupported by Gryphon, etc.

It's worth noting that, like [other transpilers](https://developers.google.com/j2objc/) for app development, Gryphon is best suited for translating platform-independent logic code. There's currently no support for translating calls to UIKit, for instance - and there's no telling if that will happen someday.

It is recommended that you start by translating only a few platform-independent parts of your code, adding new files incrementally. It might helo to use architectures with clear separations between UI code and logic code - like [MVP](https://en.wikipedia.org/wiki/Model–view–presenter) and [MVC](https://en.wikipedia.org/wiki/Model–view–controller) to separate the code that can be translated. For more information, check out [Adding Gryphon to an existing app](https://vinivendra.github.io/Gryphon/addingGryphonToAnExistingApp.html).

#### Can I use Gryphon to translate a non-iOS app?

**Yes.** While Gryphon's main focus is on iOS-to-Android support, it is primarily a Swift to Kotlin translator, and it doesn't require anything iOS-specific to run. You can use it on Linux to translate command line tools, for example. Even Gryphon's own source code can be translated, and that's just a command-line tool with nothing iOS-related.

#### Will it ever support translating Kotlin code to Swift? What about other languages?

**Probably not.** The challenges involved in translating Swift code into Kotlin are very specific for these two languages. Translating Kotlin into Swift would require a new front-end for Kotlin, a new back-end for Swift, and all-new logic in the middle to turn one into the other - basically, a whole new Gryphon. The same goes for other combinations of languages.

#### How can I help?

Thanks for the offer!

If you want to suggest a way to improve Gryphon, feel free to [open a new issue](https://github.com/vinivendra/Gryphon/issues/new/choose) - all bug reports and feature requests are welcome and encouraged.

If you would like to contribute directly, first check out the [contributor's guide](https://vinivendra.github.io/Gryphon/contributing.html) to learn to set up your environment. Then, if you're looking for inspiration, take a look at some [good first issues](https://github.com/vinivendra/Gryphon/labels/good%20first%20issue) (if you're new to Gryphon) or the beginner-friendly [first timers only](https://github.com/vinivendra/Gryphon/labels/first-timers-only) (if you're new to open source) - or, if you already know what you want to do, [open an issue](https://github.com/vinivendra/Gryphon/issues/new/choose) and let's talk about it.

If you're going to contribute, you should probably read the [code of conduct](https://github.com/vinivendra/Gryphon/blob/master/CODE_OF_CONDUCT.md) too.
