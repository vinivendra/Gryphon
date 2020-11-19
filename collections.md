---
layout: tutorialLayout
---
# Collections

When using collections like `Array` and `Dictionary` in Swift, you might notice Gryphon raises a warning:

````
main.swift:5:13: warning: Native type [Int] can lead to different behavior in Kotlin. Prefer List or MutableList instead.
let array = [1, 2, 3]
            ^~~~~~~~~
````

This warning is raised to help you avoid some hard-to-find bugs caused by differences in the way Swift and Kotlin collections work. Instead of using `Array` and `Dictionary`, it is recommended that you use Gryphon's implementation of `List`, `MutableList`, `Map`, and `MutableMap`. These classes have an API that will be familiar to Swift users, while avoiding problems when translated to Kotlin.

Gryphon's Swift Library (which contains these classes) can be generated with the following command, which will write them to a `GryphonSwiftLibrary.swift` file in the current directory:

```` bash
$ gryphon generate-libraries
````

Just copy the file to your Swift project and the classes will be available. This command also generates Gryphon's Kotlin Library, which should be added to the Kotlin project as it may be needed for some translations.

 This guide explains how to use Gryphon's `List`, `MutableList`, `Map`, and `MutableMap` collections. Since the recommendations for each one are very similar, the text focuses only on `List`, but the explanations are also applicable to the others.

- [Creating Lists](collections.html#creating-lists)
- [Creating Arrays from Lists](collections.html#creating-arrays-from-lists)
- [Lists vs. MutableLists](collections.html#lists-vs-mutablelists)
- [Casting Lists with different element types](collections.html#casting-lists-with-different-element-types)
- [Copying Lists](collections.html#copying-lists)
- [Using native Arrays](collections.html#using-native-arrays)

## Creating Lists

Gryphon's `List` is implemented as a wrapper for Swift's `Array`, meaning it redirects all methods and properties to the native `Array` implementation. This allows it to offer essentially the same APIs and behaviors:

```` swift
let list1: List = [1, 2, 3]

let list2: List<Int> = []

let array = [1, 2, 3]
let list3 = List(array)

func iWantAList(_ list: List<Int>) { }
iWantAList([1, 2, 3])
````

## Creating Arrays from Lists

Getting an `Array` from a `List` can be useful for interfacing translated code with platform-specific code. It can be done by accessing the `List`'s `array` property:

```` swift
let myList: List = [1, 2, 3]
let myArray = myList.array

func iWantAnArray(_ array: Array<Int>) { }
iWantAnArray(myList.array)
````

## Lists vs. MutableLists

Just like in Kotlin, Gryphon's `Lists` are immutable. Think of them as Swift's `let array` instead of `var array`. If we want to change a `List`, we create a `MutableList` instead:

```` swift
let list: MutableList = [1, 2, 3]
list.append(4)
list.append(5)
list.removeLast()
````

`Lists` can be converted to `MutableLists` using the `toMutableList()` method. `MutableLists` are a subclass of `List`, so they can be used wherever a `List` is required:

```` swift
var list: List = [1, 2, 3]

let mutableList = list.toMutableList()
mutableList.append(4)

list = mutableList
````

## Casting Lists with different element types

Casting the element type of a `List` can be done with couple of methods:

```` swift
let listOfInts: List<Int> = [1, 2, 3]

// How to do `listOfInts as? List<Any>`:
let listOfAnys1 = listOfInts.as(List<Any>.self)

// How to do `listOfInts as! List<Any>`:
let listOfAnys2 = listOfInts.forceCast(to: List<Any>.self)
````

## Copying Lists

Because `Lists` are passed by reference, they aren't copied automatically like `Arrays`. Copying lists can be done by using the `toList()` method (or `toMutableList()` to copy a `MutableList`):

```` swift
let original: MutableList = [1, 2, 3]
let copy = original.toMutableList()
copy.append(4)

print(original) // prints [1, 2, 3]
````

## Using native Arrays

Native `Arrays` (and `Dictionaries`) can still be useful, especially for some performance-critical algorithms. Gryphon will raise a warning to avoid accidental uses, but the warning can be silenced with a `// gryphon mute` comment:

```` swift
// gryphon mute
let myNativeArray: Array = [1, 2, 3]
````

With performance in mind, mutability is ignored: all `Arrays` are translated to `Lists`, and all `Dictionaries` are translated to `Maps`.

Performance-critical code can also be written in platform-specific files (that aren't translated), which would also allow access to other low-level language features (like concurrency and pointer manipulation) that may be unsupported by Gryphon.
