<img src="https://github.com/vinivendra/Gryphon/raw/master/Gryphon%20Logo.svg" alt="Gryphon logo" height="70">

## The Swift to Kotlin translator

Gryphon is a program that translates Swift code into Kotlin code. It was created to enable mobile app developers to share parts of an iOS app's codebase with Android.

- **Risk-free.** Stop using Gryphon whenever you want - you'll still be able to read and understand your Kotlin code, even the computer-generated parts.
- **No editing needed.** Translated Kotlin files work the same as the Swift files they came from.
- **Xcode integration.** Translate your iOS code to Android, compile the Android app, and see Kotlin's errors and warnings in the Swift lines that originated them - all without leaving Xcode.
- **Custom-made.** Use special comments and templates to customize your Kotlin translation, and use any platform-specific features you want - even in translated source files.

Check out the [project's website](https://vinivendra.github.io/Gryphon) for more information.

## 👍 Status

Gryphon is now in preview! 🎉

This means the main systems and ideas have already been implemented - for instance, it's been translating its own codebase for a while now. However, new users might still find some new bugs to be fixed. If that's the case, feel free to report a [new issue](https://github.com/vinivendra/Gryphon/issues/new/choose) on GitHub.

## 📲 Getting started

Gryphon supports **macOS**, **Linux**, and **Docker**. Xcode integration is only available on macOS, but Linux and Docker users can still translate Swift code that doesn't import the iOS frameworks.

Check out the [Tutorial](https://vinivendra.github.io/Gryphon/gettingStarted.html) to get started. It covers the basic information needed to begin using Gryphon:

- [Installing Gryphon](https://vinivendra.github.io/Gryphon/installingGryphon.html)
- [Translating command line programs](https://vinivendra.github.io/Gryphon/translatingCommandLinePrograms.html)
    - [Translating a single file](https://vinivendra.github.io/Gryphon/translatingCommandLinePrograms.html#translating-a-single-file)
    - [Translating multiple files](https://vinivendra.github.io/Gryphon/translatingCommandLinePrograms.html#translating-multiple-files)
- [Translating a new iOS app to Android](https://vinivendra.github.io/Gryphon/translatingANewiOSAppToAndroid.html)
  - [Building the Android app using Xcode](https://vinivendra.github.io/Gryphon/buildingTheAndroidAppUsingXcode.html)
  - [Adding the Gryphon libraries](https://vinivendra.github.io/Gryphon/addingTheGryphonLibraries.html)
  - [Adding manual translations](https://vinivendra.github.io/Gryphon/addingManualTranslations.html)
- [Adding Gryphon to an existing app](https://vinivendra.github.io/Gryphon/addingGryphonToAnExistingApp.html)

There are also in-depth guides on a few topics:

- [Using collections](https://vinivendra.github.io/Gryphon/collections.html)
- [Using translation comments](https://vinivendra.github.io/Gryphon/translationComments.html)
- [Using templates](https://vinivendra.github.io/Gryphon/templates.html)

If you would like to contribute to the project, check out the [Contributor's guide](https://vinivendra.github.io/Gryphon/contributing.html).
