---
layout: tutorialLayout
---
# Templates

The templates system is a mechanism that can be used to define custom translations for common expressions. It is the system that Gryphon uses to translate references to the Swift standard library, references to the two Gryphon libraries, and even some internal methods in its source code.

The system was created in a way that lets developers take full advantage of its capabilities by defining their own templates.

- [Creating the gryphonTemplates function](templates.html#creating-the-gryphontemplates-function)
- [Declaring templates](templates.html#declaring-templates)
- [Adding placeholder variables](templates.html#adding-placeholder-variables)
- [Templates with Swift types](templates.html#templates-with-swift-types)

### Creating the gryphonTemplates function

Templates should be defined in top-level functions called `gryphonTemplates`. There can be several of these functions in a single codebase. It is recommended that any `gryphonTemplates` function be marked as `private` to avoid conflicts.

```` swift
func gryphonTemplates() {
    // ...
}
````

Functions called `gryphonTemplates` are assumed to be template declarations, so they are ignored during translation and don't show up in the output code.

### Declaring templates

Let's declare a custom translation for the expression `Int.random(in: 0...10)`, which we want to translate as `(0..10).random()`. The expression to be translated is called the "template", and the literal string that replaces it is the "translation".

When parsing `gryphonTemplates` functions, the algorithm starts by searching for String literals, which it assumes will be translations. When it finds one it looks above it for the closest expression, which is assumed to be the template.

```` swift
func gryphonTemplates() {
    Int.random(in: 0...10) // Swift template
    "(0..10).random()"     // Kotlin translation
}
````

Any comments in this function are ignored.

The Swift compiler may raise warnings for unused expressions, which can be avoided by turning them into empty assignments:

```` swift
func gryphonTemplates() {
    _ = Int.random(in: 0...10)
    _ = "(0..10).random()"
}
````

Lines of code that aren't String literals or that precede string literals are ignored. This allows us to define auxiliary variables if needed:

```` swift
func gryphonTemplates() {
    let index = 0 // This variable will be ignored

    _ = Int.random(in: 0...index)
    _ = "(0..index).random()"
}
````

### Adding placeholder variables

Templates are often more useful when they can be matched to several different expressions. For instance, the template defined above works only for random numbers between `0` and a variable named `index`:

```` swift
let index = 10
Int.random(in: 0...index) // OK
````

But it would be more useful if it matched calls with any two integers:

```` swift
let index = 10
Int.random(in: 5...index) // Doesn't match
Int.random(in: 0...10)    // Doesn't match
````

To do that, the `0` and `index` in the template need to be replaced with placholder variables:

```` swift
func gryphonTemplates() {
    let _startNumber = 0
    let _endNumber = 0

    _ = Int.random(in: _startNumber..._endNumber)
    _ = "(_startNumber.._endNumber).random()"
}
````

Placeholder variables are any variables whose name starts with an underscore (`_`). When these variables are found in a template declaration, they are allowed to match any expression that has a compatible type. For instance, the `_startNumber` variable in the template above is an `Int`, meaning it can match any expression that results in an `Int`:

```` swift
Int.random(in: 0...10)
Int.random(in: (5 + 3)...10)
Int.random(in: Database.fetchNumber().performCalculation()...10)
````

The matched expression will be translated, and the translation will be replaced accordingly in the template's translation:

```` kotlin
(0..10).random()
((5 + 3)..10).random()
(Database.fetchNumber().performCalculation()..10).random()
````

Placeholder variables will also match some expressions with compatible subtypes, though Gryphon's subtype checking algorithm is limited. For instance, a placeholer variable of type `Any` will match expressions of any type:

```` swift
func gryphonTemplates() {
    let _value: Any = 0

    _ = myFunction(_value)
    _ = "myFunction(value = _value)"
}

myFunction("Hello, world!") // OK
````

### Templates with Swift types

Some placeholder variables need to be defined according to native Swift types. For instance, a template for the `Array.sorted(by:)` method should work for any type that conforms to the `Comparable` protocol, but Swift doesn't let us declare a variable as being only `Comparable`.

Gryphon supports defining a few new types to work around these issues. They are treated much like `Any` and will match expressions of any type. It is recommended to always declare them as `private` to avoid name conflicts.

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
