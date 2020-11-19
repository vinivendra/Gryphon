---
layout: tutorialLayout
---
# Templates

The templates system can be used to define custom translations for Swift expressions. It's especially useful for translations that are common in your code, so translating them manually with [translation comments](translationComments.html) would be cumbersome.

For example: let's say our project often uses a third-party library for file handling, with a method that checks if a file was modified after the other. The Swift version of that method might have a Swift-y name...

```` swift
fileHandler.file(aFile, wasModifiedAfter: anotherFile)
````

...while its Kotlin version might have a different, more Kotlin-y name:

```` kotlin
fileHandler.fileWasModifiedAfter(aFile, anotherFile)
````

We can tell Gryphon how to translate this method's name correctly using templates.

- [Creating the gryphonTemplates function](templates.html#creating-the-gryphontemplates-function)
- [Declaring templates](templates.html#declaring-templates)
- [Adding placeholder variables](templates.html#adding-placeholder-variables)
- [Structured templates](templates.html#structured-templates)
- [Templates with Swift types](templates.html#templates-with-swift-types)


### Creating the gryphonTemplates function

All templates should be stored in a function called `gryphonTemplates`, which can be anywhere in your code. You can have several templates in the same `gryphonTemplates` function, and several of these functions in the same project, if needed. It's recommended that you mark the function as `private` to avoid conflicts.

```` swift
private func gryphonTemplates() {
    // ...
}
````

Functions called `gryphonTemplates` are ignored during the translation and don't show up in your Kotlin code.


### Declaring templates

In this example, we want to translate Swift's `fileHandler.file(aFile, wasModifiedAfter: anotherFile)` into the Kotlin code `"fileHandler.fileWasModifiedAfter(aFile, anotherFile)"`. To do that, we type the Swift expression followed by the literal string of Kotlin code that replaces it:

```` swift
func gryphonTemplates() {
    let fileHandler = FileHandler()
    let aFile = File()
    let anotherFile = File()

    fileHandler.file(aFile, wasModifiedAfter: anotherFile) // Swift template
    "fileHandler.fileWasModifiedAfter(aFile, anotherFile)" // Kotlin translation
}
````

String literals in a `gryphonTemplates()` function are interpreted as Kotlin translations, and the expressions before them are interpreted as Swift templates. Everything else (like the variable declarations at the start of the function) is ignored.

The Swift compiler may raise warnings for unused expressions, which can be avoided by turning them into empty assignments:

```` swift
func gryphonTemplates() {
    let fileHandler = FileHandler()
    let aFile = File()
    let anotherFile = File()

    _ = fileHandler.file(aFile, wasModifiedAfter: anotherFile)
    _ = "fileHandler.fileWasModifiedAfter(aFile, anotherFile)"
}
````

### Adding placeholder variables

Templates are often more useful when they can be matched to several different expressions. For instance, the template above only works if we have variables named `fileHandler`, `aFile` and `anotherFile`:

```` swift
// OK
fileHandler.file(aFile, wasModifiedAfter: anotherFile)

// Doesn't match
myFileHandler.file(file1, wasModifiedAfter: file2)
````

To fix that, we need to add an `_` to the start of our template's variable names:

```` swift
func gryphonTemplates() {
    let _fileHandler = FileHandler()
    let _aFile = File()
    let _anotherFile = File()

    _ = _fileHandler.file(_aFile, wasModifiedAfter: _anotherFile)
    _ = "_fileHandler.fileWasModifiedAfter(_aFile, _anotherFile)"
}
````

Variables that start with an `_` are treated as placeholders. They are allowed to match any expression that has a compatible type. For instance, the `_fileHandler` variable in the template above is a `FileHandler`, meaning it can match any expression that results in a `FileHandler`:

```` swift
// OK
fileHandler.file(aFile, wasModifiedAfter: anotherFile)

// Also OK
myFileHandler.file(file1, wasModifiedAfter: file2)

// Also OK
self.getFileHandler().file(file1, wasModifiedAfter: file2)
````

Placeholder variables will also match some expressions with compatible subtypes, though Gryphon's subtype checking algorithm is limited. For instance, a placeholder variable of type `Any` will match expressions of any type:

```` swift
func gryphonTemplates() {
    let _value: Any = 0

    _ = print(_value)
    _ = "println(_value)"
}

print("Hello, world!") // OK
````

### Structured templates

Our template is now working correctly, but we could give Gryphon more information so it can improve its translations. For example, it doesn't know that our literal Kotlin code is made up of a dot expression (`_fileHandler.fileWasModifiedAfter`) that is then called with the `(_aFile, _anotherFile)` arguments. We can tell it about this structure using the `GRYTemplate` class:

```` swift
func gryphonTemplates() {
    let _fileHandler = FileHandler()
    let _aFile = File()
    let _anotherFile = File()

    _ = _fileHandler.file(_aFile, wasModifiedAfter: _anotherFile)
    _ = GRYTemplate.call(.dot("_fileHandler", "fileWasModifiedAfter"), ["_aFile", "_anotherFile"])
}
````

The `GRYTemplates` class is declared in the `GryphonSwiftLibrary.swift` file, which also includes some templates you can use as inspiration. The `GryphonSwiftLibrary.swift` file can be generated with the following command:

```` bash
$ gryphon generate-libraries
````

Just add this file to your project and you can use the template classes inside it.

Now that Gryphon knows our template contains a function call, it can (for instance) warn us about potential [unintended side-effects](translationComments.html#gryphon-pure). We can use a `// gryphon pure` [translation comment](translationComments.html) to tell it not to worry:

```` swift
func gryphonTemplates() {
    let _fileHandler = FileHandler()
    let _aFile = File()
    let _anotherFile = File()

    _ = _fileHandler.file(_aFile, wasModifiedAfter: _anotherFile)
    // gryphon pure
    _ = GRYTemplate.call(.dot("_fileHandler", "fileWasModifiedAfter"), ["_aFile", "_anotherFile"])
}
````

### Templates with Swift types

Sometimes, a template's placeholder variables need to be defined using native Swift types that can't be instantiated. For instance, a template for the `Array.sorted(by:)` method should work for any type that conforms to the `Comparable` protocol, but Swift doesn't let us declare a variable as being only `Comparable`.

To work around this issue, you can define types with similar names, but starting with a `_`. They'll be treated like `Any` and will match expressions of any type. It is recommended to always declare them as `private` to avoid name conflicts.

```` swift
// Replacement for Hashable
private struct _Hashable: Hashable { }

// Replacement for Comparable
private struct _Comparable: Comparable {
    static func < (lhs: _Comparable, rhs: _Comparable) -> Bool {
        return false
    }
}

// Replacement for Optional
private struct _Optional { }

// Replacement for Any
private struct _Any: CustomStringConvertible, LosslessStringConvertible {
    init() { }

    var description: String = ""

    init?(_ description: String) {
        return nil
    }
}

private func gryphonTemplates() {
    let _comparableArray: Array<_Comparable> = []
    let _closure: (_Comparable, _Comparable) -> Bool = { _, _ in true }

    _ = _comparableArray.sorted(by: _closure)
    _ = "_comparableArray.quicksort(isAscending = _closure)"
}

````
