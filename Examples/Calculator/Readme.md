# Calculator app

## Origin

This application was originally created by Apple and posted on its developer portal as an example for Swift programmers on how to use unit and UI tests on iOS and macOS apps. The original source code, last accessed in May 2018, can be found [here] (https://developer.apple.com/library/content/samplecode/UnitTests/Listings/Shared_Code_Calculator_swift.html#/).

This app implements a simple calculator. It has a very clear distinction between model and UI code, which allows us to know exactly what should and shouldn't be translated by Gryphon.

It also includes simple unit and UI tests, allowing us to:

- Adapt the original Swift code to be compatible with Gryphon and still be sure that it still works, and
- Manually translate the tests to Kotlin, so that we can to make sure the automatic Kotlin translations also work.

## The Swift version

The Swift version of this app is somewhat different from the original. Firstly, the macOS part of the app was deleted, as macOS-compatible translations are beyond Gryphon's scope. Secondly, the model code has been adapted to only use Gryphon-compatible code wherever possible, and to provide manual translations otherwise. Hopefully, the code is still easy to understand, and a quick look at the original and the adapted versions side by side shows that the modifications are quite trivial.

## The Kotlin version

The Kotlin version of the app was first created as a manual translation of the original Swift app provided by apple. Its model has since been replaced by the automatic translation provided by Gryphon, but the UI code and the code for the automated tests are still the results of that initial manual translation.

## Replicating the translation

As of the time of writing this description, Gryphon doesn't yet support translating multiple files at once. In order to obtain a translation for this app's model, follow these steps:

1. Copy the code for the three model files in `Examples/Calculator/iOS/Shared Code` (which are `CalculatorError.swift`, `CalculatorKitExtensions.swift` and `Calculator.swift`), one after the other and in this order, into the `test.swift` file in the package's root folder.
1. Try to compile this file using `$swiftc test.swift`. The compiler will complain that some functions are duplicated (which they are). These special functions must be present in all files (for now) but obviously can't appear more than once in a single file, so just delete any of the duplications to allow it to compile.
1. Run `$perl dump-ast.pl test.swift` in the package's root folder.
1. (Optional) make sure that the `test.swift` file is set as the `filePath` in `Sources/Gryphon/main.swift`. Also, make sure that the transpiler is set to generate the Kotlin code (a few lines below). This configuration is the current setup, so right now nothing has to be changed, but it doesn't hurt to be sure.
1. Run Gryphon (running `$swift run` on the package's root should be enough). If all goes well, it will print the translated code.
1. Copy the printed code into the respective Kotlin files. This is pretty straightforward, but you can use the original Swift code as reference if you don't know what goes where.
1. Remember the duplicated functions we had to delete before? These were responsible for adding `package com.example.gryphon.calculator` to our Kotlin source files. Make sure to manually add this line now to the top of each of the three Kotlin files, otherwise Android won't compile the app.
1. It's done! You can run the Android unit and UI tests if you want to make sure the translation is working.