---
layout: tutorialLayout
---
# Translation comments

While Gryphon is intended to be used for translating most of an application's logic code, there are times when automatic translations aren't enough to get the job done. This can happen, for instance, when including iOS-only method calls in the input code, or when the generated code is intended to behave differently. In those cases, developers can use *translation comments* to directly manipulate the generated code.

These comments can handle a variety of tasks, such as making Swift code be ignored, inserting Kotlin code in the output files, etc. They are written as `// gryphon <keyword>`, with each keyword performing a different task.

- [List of translation comments](translationComments.html#list-of-translation-comments)
  - [Gryphon output](translationComments.html#gryphon-output)
  - [Gryphon insert](translationComments.html#gryphon-insert)
  - [Gryphon ignore](translationComments.html#gryphon-ignore)
  - [Gryphon value](translationComments.html#gryphon-value)
  - [Gryphon annotation](translationComments.html#gryphon-annotation)
  - [Gryphon multiline](translationComments.html#gryphon-multiline)
  - [Gryphon pure](translationComments.html#gryphon-pure)
  - [Gryphon mute](translationComments.html#gryphon-mute)
  - [Gryphon inspect](translationComments.html#gryphon-inspect)
- [Placing translation comments](translationComments.html#placing-translation-comments)

## List of translation comments

### Gryphon output

Usually, each Swift file should have a `// gryphon output` comment specifying where that file's translation should be placed. The translated file can be written as an absolute path or a relative path. Relative paths should be relative to the directory from which Gryphon is called. When using the Gryphon target in Xcode, this is the directory that contains the Xcode project.

Source files that don't contain a `gryphon output` comment will have their translations printed to the standard output.

The path to a file's Kotlin translation is only valid if it has the `.kt` extension.

```` swift
// gryphon output: ../Android/src/SourceFile.kt
````

Some other extensions can also be used for debugging Gryphon. They correspond to different intermediate representations.

```` swift
// gryphon output: ../Android/src/SourceFile.kt
// gryphon output: Debug/SourceFile.swiftAST
// gryphon output: Debug/SourceFile.gryphonASTRaw
// gryphon output: Debug/SourceFile.gryphonAST
````

### Gryphon insert

The `// gryphon insert` comments can be used to insert a specific line of code into the translation. The code will be inserted in a corresponding location (i.e. inside the same function, after the same statement, etc.) so its placement in the Swift file is important. The inserted code will not be changed, so it has to be valid Kotlin code for that location.

```` swift
// gryphon insert: package com.example.androidApp

func myButtonPressed() {
    // gryphon insert: AndroidAnalytics.log("buttonPress")

    self.model.performButtonPress()
}
````

```` kotlin
package com.example.androidApp

internal fun myButtonPressed() {
    AndroidAnalytics.log("buttonPress")

    this.model.performButtonPress()
}
````

- **Gryphon insertInMain**

    When generating Kotlin files with a `main` function, any code added with the `// gryphon insert` comment is added to the top level of the Kotlin file. To add code to the `main` function, use the `// gryphon insertInMain` comment.

    ```` swift
    // gryphon insert: import java.util.*

    var message = "Hello from Gryphon!"
    // gryphon insertInMain: message = message + " This only appears in Kotlin!"
    print(message)
    ````

    ```` kotlin
    import java.util.*

    fun main(args: Array<String>) {
        var message: String = "Hello from Gryphon!"
        message = message + " This only appears in Kotlin!"
        println(message)
    }
    ````

### Gryphon ignore

`Gryphon ignore` comments can be used to omit code from the translation. Lines of code marked with this comment will be compiled by Swift, but will not be processed by Gryphon and will not show up in the translated code.

```` swift
func myButtonPressed() {
    iOSAnalytics.log("buttonPress") // gryphon ignore

    self.model.performButtonPress()
}
````

```` kotlin
internal fun myButtonPressed() {
    this.model.performButtonPress()
}
````

### Gryphon value

`Gryphon value` comments are essentially a combination of insert and ignore comments - they ignore a Swift value and insert a Kotlin value in its place. They can be used to provide a manual translation for specific expressions.

```` swift
let languageName = "Swift" // gryphon value: "Kotlin"

print("Hello from \(languageName)!")
````

```` kotlin
val languageName: String = "Kotlin"

println("Hello from ${languageName}!")
````

### Gryphon annotation

`Gryphon annotation` comments can be used to add annotations to some declarations. This is allows developers to add Kotlin-only annotations that can't be included in Swift.

It also compensates for current limitations of the Swift compiler. For instance, Kotlin requires class members that satisfy interface requirements to include an `override` keyword, but the Swift compiler doesn't specify these cases, so Gryphon doesn't know which is which. The `gryphon annotation` comment can be used to add the `override` keyword manually when necessary.

```` swift
protocol Drawable {
    func draw()
}

class Rectangle: Drawable {
    func draw() { // gryphon annotation: override
        // ...
    }
}
````

```` kotlin
internal interface Drawable {
    fun draw() { }
}

internal open class Rectangle: Drawable {
    override open fun draw() {
        // ...
    }
}
````

### Gryphon multiline

Both Swift and Kotlin support multiline strings literals. However, due to a limitation of the Swift compiler, Gryphon doesn't know if a string literal in Swift is being written in many lines or in a single line. As a workaround, the `// gryphon multiline` comment can be used to translate string literals as a multiline strings.

```` swift
// gryphon multiline
let message = """

    This is a message with many lines.

    It's a very, very, very, very, very
    long message.

"""
````

```` kotlin
val message: String = """
    This is a message with many lines.

    It's a very, very, very, very, very
    long message.
"""
````

*Note: Swift and Kotlin parse newlines in multiline strings differently; the two strings above correspond to the same string.*

### Gryphon pure

`Gryphon pure` comments are used to tell Gryphon which functions are "pure" (that is, without side effects) so that it knows not to raise side effect warnings for them. Side effect warnings can be raised because of the following issue.

Translating Swift's `if let` statements requires defining the variables in `Kotlin` before checking their contents:

```` swift
if let image = downloadImage() {
    // ...
}
````

```` kotlin
val image: Image? = downloadImage()

if (image != null) {
    // ...
}
````

This can cause problems if a function in the `if let` produces side effects. For instance, the `downloadImage` function below is not called in Swift (because the `shouldDownloadImage` condition fails first) but it is called in the Kotlin:

```` swift
let shouldDownloadImage = false

if shouldDownloadImage,
    let image = downloadImage()
{
    // ...
}
````

```` kotlin
val shouldDownloadImage: Boolean = false

val image: Image? = downloadImage()

if (shouldDownloadImage && image != null) {
    // ...
}
````

In this case, the image will be downloaded in Kotlin, even though the code says it shouldn't.

Gryphon raises a warning when it detects these cases so the developer can avoid these types of bugs. If the function has no relevant side effects it can be marked as "pure" to silence the warning:

```` swift
func downloadImage() -> Int? { // gryphon pure
    // ...
}
````

### Gryphon mute

The `gryphon mute` comment mutes all warnings in a specific line of code.

```` swift
let array = [1, 2, 3] // gryphon mute
````

### Gryphon inspect

`Gryphon inspect` comments are meant mainly for debugging Gryphon. When used, the intermediate representations of an expression will be printed to the standard output.

```` swift
val x = 0 // gryphon inspect
````

## Placing translation comments

Translation comments that refer to Swift code should always be placed in the first line of the declaration or statement they refer to. In the code below, for instance, the `gryphon annotation` comment affects the `draw` function, which starts in that line, and the `gryphon value` comment affects the `.yellow` expression, which starts (and ends) in that line:

```` swift
class Rectangle {
    func draw( // gryphon annotation: override
        screen: Screen,
        color: Color = .yellow // gryphon value: BLUE
        )
    {
        // ...
    }
}
````

```` kotlin
internal open class Rectangle {
    override open fun draw(screen: Screen, color: Color = BLUE) {
        // ...
    }
}
````
