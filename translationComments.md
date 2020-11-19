---
layout: tutorialLayout
---
# Translation comments

When developing with Gryphon, there may be times when we want to directly manipulate the translated Kotlin code. This can happen, for instance, when dealing with Android-only functionalities, or when the input code is intended to behave differently than the translated code. In those cases, developers can use *translation comments* to change the generated code.

Translation comments can handle a variety of tasks, such as ignoring code in the Swift files, inserting code in the Kotlin files, etc. They are written as `// gryphon <keyword>`, with each keyword performing a different task.

- [List of translation comments](translationComments.html#list-of-translation-comments)
  - [Gryphon output](translationComments.html#gryphon-output)
  - [Gryphon insert](translationComments.html#gryphon-insert)
  - [Gryphon ignore](translationComments.html#gryphon-ignore)
  - [Gryphon value](translationComments.html#gryphon-value)
  - [Gryphon annotation](translationComments.html#gryphon-annotation)
  - [Gryphon generics](translationComments.html#gryphon-generics)
  - [Gryphon pure](translationComments.html#gryphon-pure)
  - [Gryphon mute](translationComments.html#gryphon-mute)
- [Placing translation comments](translationComments.html#placing-translation-comments)

## List of translation comments

### Gryphon output

Usually, each Swift file should have a `// gryphon output` comment specifying where that file's translation should be placed. The translated file can be written as an absolute path or a relative path. Relative paths should be relative to the directory from which Gryphon is called. When using the Gryphon target in Xcode, this is the directory that contains the Xcode project.

Source files that don't contain a `gryphon output` comment will have their translations printed to the standard output.

The path to a file's Kotlin translation is only valid if it has the `.kt` extension.

```` swift
// gryphon output: ../Android/src/SourceFile.kt
````

### Gryphon insert

The `// gryphon insert` comments can be used to insert a line of code into the Kotlin translation. The code will be inserted in a corresponding location (i.e. inside the same function, after the same statement, etc.) so its placement in the Swift file is important. The inserted code will not be changed, so it has to be valid Kotlin code in that location.

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

`Gryphon ignore` comments can be used to omit code from the translation. Code marked with this comment will be compiled by Swift, but will not be processed by Gryphon and will not show up in the translated code.

```` swift
func myButtonPressed() {
    // gryphon ignore
    iOSAnalytics.log("buttonPress")

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

`Gryphon value` replaces the expression that comes immediately after it.

```` swift
let languageName = /* gryphon value: "Kotlin" */ "Swift" 

print("Hello from \(languageName)!")
````

```` kotlin
val languageName: String = "Kotlin"

println("Hello from ${languageName}!")
````

### Gryphon annotation

`Gryphon annotation` comments can be used to add annotations to some declarations. This is allows you to add Kotlin-only annotations when they aren't included in Swift.

```` swift
protocol Drawable {
    func draw()
}

class Rectangle: Drawable {
    // gryphon annotation: override
    func draw() {
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

### Gryphon generics

`Gryphon generics` provide important type information that isn't available otherwise (due to a current limitation in SourceKit). They should be used when creating extensions for generic types:

```` swift
struct Box<T> {
    let x: T
}

// gryphon generics: T
extension Box {
    var a: Int {
        return 0
    }
}
````

Just include whatever generic types your `struct`, `class` or `enum` uses (in this case, the `T` from `struct Box<T>`) so that Gryphon can add it to the Kotlin code.

### Gryphon pure

`Gryphon pure` comments are used to tell Gryphon which functions are "pure" (that is, without side effects) so that it knows not to raise warnings for them.

Side-effect warnings are raised because translating Swift's `if let` statements requires defining the variables in `Kotlin` before checking their contents:

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

This can cause problems if a function in the `if let` produces side effects. For instance, the `downloadImage` function below is not called in Swift (because the `shouldDownloadImage` condition fails first) but it is called in Kotlin:

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
// gryphon pure
func downloadImage() -> Int? {
    // ...
}
````

### Gryphon mute

The `gryphon mute` comment mutes all warnings in a specific line of code. In the example below, the comment is muting a warning about using native [collections](collections.html).

```` swift
// gryphon mute
let array = [1, 2, 3]
````

## Placing translation comments

Translation comments should always be placed *before* the code they refer to. For example, the `gryphon annotation` comment below affects the `draw` function, and the `gryphon value` comment affects the `.yellow` expression:

```` swift
class Rectangle {
    // gryphon annotation: override
    func draw(
        screen: Screen,
        color: Color = /* gryphon value: BLUE */ .yellow)
    {
        // ...
    }
}
````

```` kotlin
internal open class Rectangle {
    override open fun draw(
        screen: Screen,
        color: Color = BLUE)
    {
        // ...
    }
}
````
