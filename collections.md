---
layout: tutorialLayout
---
# Collections

Swift and Kotlin are very similar languages in many ways, but they differ in one key aspect: Swift passes its native collections (such as `Array` and `Dictionary`) by value...

```` swift
var original = [1, 2, 3]

var other = original // Creates a copy
other[0] = 10

// The original array is still the same
print(original) // [1, 2, 3]
````

...while Kotlin passes its native collections (such as `List` and `Map`) by reference.

```` kotlin
var original = mutableListOf(1, 2, 3)

var other = original // Creates a reference
other[0] = 10

// The original array has changed too
println(original) // [10, 2, 3]
````

This unfortunately means Gryphon can't just perform the straightforward translation (from `Arrays` to `Lists` and from `Dictionaries` to `Maps`). That would often cause the generated code to behave differently from the input code in ways that can be hard to debug.

Ideally, the solution would be to preserve Swift's API by making Kotlin pass its collections by value. However, that solution isn't feasible due to some [technical differences](collections.html#why-cant-kotlins-lists-be-passed-by-value) in the languages.

Therefore, Gryphon does the contrary: it passes Swift's collections by reference. This is done by defining two classes in the Gryphon Swift Library that wrap Swift's native collections, offering the same API but with reference semantics. For simplicity, these classes are also called `List` and `Map`, just like the Kotlin collections they correspond to.

This guide explains how to use Gryphon's `List` and `Map` collections. Since the recommendations are very similar for both, the text focuses only on `Lists`, but the explanations are also applicable to `Maps`.

- [Using Lists](collections.html#using-lists)
  - [Creating Lists from Arrays](collections.html#creating-lists-from-arrays)
  - [Creating Arrays from Lists](collections.html#creating-arrays-from-lists)
  - [Lists vs. MutableLists](collections.html#lists-vs-mutablelists)
  - [Casting Lists with different element types](collections.html#casting-lists-with-different-element-types)
  - [Copying Lists](collections.html#copying-lists)
  - [Using native Arrays](collections.html#using-native-arrays)
- [Why can't Kotlin's Lists be passed by value?](collections.html#why-cant-kotlins-lists-be-passed-by-value)

## Using Lists

### Creating Lists from Arrays

Gryphon's `Lists` are implemented as wrappers for Swift `Arrays`, meaning they redirect all methods and properties to the native `Array` implementation. This allows them to offer the same APIs and behaviors as `Arrays` - except, of course, for being passed by reference.

```` swift
let list1: List<Int> = []
let list2: List = [1, 2, 3]

let list3 = List<Int>([])
let list4 = List([1, 2, 3])

let array = [1, 2, 3]
let list5 = List(array)

func iWantAList(_ list: List<Int>) { }
iWantAList([1, 2, 3])
````

### Creating Arrays from Lists

Getting an `Array` from a `List` can be useful for interfacing translated code with platform-speficic code. It can be done by accessing `List`'s `array` property:

```` swift
let myList: List = [1, 2, 3]
let myArray = myList.array

func iWantAnArray(_ array: Array<Int>) { }
iWantAnArray(myList.array)
````

### Lists vs. MutableLists

Just like in Kotlin, Gryphon's `Lists` are immutable by nature, which allows the compiler to perform some optimizations on them - think of them as Swift's `let array` instead of `var array`. If we want to change a `List`, we create a `MutableList` instead:

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

### Casting Lists with different element types

Casting the element type of a `List` is a task that is complicated by technical limitations in both Swift and Kotlin.\* Because of this, Gryphon implements this feature as couple of methods:

```` swift
let listOfInts: List<Int> = [1, 2, 3]

// How to do `listOfInts as? List<Any>`:
let listOfAnys1 = listOfInts.as(List<Any>.self)

// How to do `listOfInts as! List<Any>`:
let listOfAnys2 = listOfInts.forceCast(to: List<Any>.self)
````

These functions use the `as?` and `as!` operators internally, so they have the same behavior. Their Kotlin translations, available in the Gryphon Kotlin Library, also implement this behavior.

### Copying Lists

Because `Lists` are passed by reference, they aren't copied automatically like `Arrays`. Copying lists can be done by using the `toList()` method (or `toMutableList()` to copy a `MutableList`):

```` swift
let original: MutableList = [1, 2, 3]
let copy = original.toMutableList()
copy.append(4)

print(original) // prints [1, 2, 3]
````

### Using native Arrays

Native `Arrays` (and `Dictionaries`) can still be useful, especially for some performance-critical algorithms. Gryphon will raise a warning to avoid accidental uses, but the warnings can be silenced using a `// gryphon mute` comment:

```` swift
let myNativeArray: Array = [1, 2, 3] // gryphon mute
````

With performance in mind, mutablility is ignored: all `Arrays` are translated to `Lists`, and all `Dictionaries` are translated to `Maps`.

Performance-critical code can also be written in platform-specific files (that aren't translated), which would allow access to low-level language features that may be unsupported by Gryphon.

## Why can't Kotlin's Lists be passed by value?

An ideal way of solving this value/reference problem would keep Swift's APIs intact - for instance, by passing Kotlin's collections by value, like Swift does. This can't be done mainly because of performance concerns. Swift can only pull off copying arrays because it knows it only has to copy the array when

1. there is more than one reference to the array, and
2. one of the references to the array tries to change it.

This optimization is called *copy-on-write*, and it lets Swift get away with not having to copy the arrays in most cases. Kotlin, however, uses a garbage collector instead of counting references, there's no way to know if there is more than one reference to the array or not. This means we'd have to copy arrays every time they're changed, which can cause apps to become really slow.

Kotlin does have access to Java's [CopyOnWriteArrayList](https://docs.oracle.com/javase/8/docs/api/java/util/concurrent/CopyOnWriteArrayList.html), but it uses a different optimization than Swift's copy-on-write Arrays and is meant only for very specific use cases.

---

\* *In Swift, user-defined types can't be covariant; in Kotlin, generic information on the element type is not available at runtime.*
