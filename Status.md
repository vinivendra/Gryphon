# Swift standard library - translation status

This document tracks Gryphon's current capabilities of translating references to the Swift standard library. This includes translating the standard library's types, their properties and methods, etc.

Any features that aren't listed below haven't been considered yet, meaning we don't yet know if we can translate them or not.

**If you want us to prioritize something or add something to the list, let us know! User requests usually have priority over day-to-day development.** You can ask us via [GitHub](https://github.com/vinivendra/Gryphon/issues/new/choose), [email](mailto:gryphontranspiler@gmail.com), or [twitter](http://twitter.com/gryphonblog), we read everything.

## Status

### Legend

- ⏱ **We haven't fully considered this feature yet.** Parts of it may already have been implemented, and the rest is in the to-do list.
- ❌ **There are no known ways to translate this feature.** We looked at it but we couldn't find a good Kotlin translation (if you know one, please [tell us](https://github.com/vinivendra/Gryphon/issues/new/choose)).
- ☑️ **This feature is done.** Everything that we managed to translate has been implemented, and everything we couldn't translate has been marked with ❌.
- 📖 **This feature is supported, but it depends on the [Gryphon libraries](https://vinivendra.github.io/Gryphon/addingTheGryphonLibraries.html).** This usually means either the Swift code or the Kotlin translation references something implemented in the Gryphon libraries.

### Types
This section includes types with translations that are already supported, as well as all of their features that we have already implemented (or decided not to implement).

- ⏱ `Bool` ➡️ `Boolean`

- ⏱ `Int` ➡️ `Int`
	- Initializers
		- `Int(float)` ➡️ `float.toInt()`
		- `Int(double)` ➡️ `double.toInt()`
		- `Int(string)` ➡️ `string.toInt()`
	- Static variables
		- `Int.max` ➡️ `Int.MAX_VALUE`
		- `Int.min` ➡️ `Int.MIN_VALUE`
	- Operators
		- `int1...int2` ➡️ `int1..int2`
		- `int1..<int2` ➡️ `int1 until int2`

- ⏱ `Int8` ➡️ `Byte`

- ⏱ `Int16` ➡️ `Short`

- ⏱ `Int32` ➡️ `Int`

- ⏱ `Int64` ➡️ `Long`
	- Initializers
		- `Int64(string)` ➡️ `string.toLong()`

- ⏱ `Float` ➡️ `Float`
	- Initializers
		- `Float(int)` ➡️ `int.toFloat()`
		- `Float(double)` ➡️ `double.toFloat()`
		- `Float(string)` ➡️ `string.toFloat()`

- ⏱ `Float32` ➡️ `Float`

- ⏱ `Float64` ➡️ `Double`

- ⏱ `Double` ➡️ `Double`
	- Initializers
		- `Double(int)` ➡️ `int.toDouble()`
		- `Double(float)` ➡️ `float.toDouble()`
		- `Double(string)` ➡️ `string.toDouble()`
	- Operators
		- `double1...double2` ➡️ `double1.rangeTo(double2)`

- ⏱ `UInt8` ➡️ `UByte`

- ⏱ `UInt16` ➡️ `UShort`

- ⏱ `UInt32` ➡️ `UInt`

- ⏱ `UInt64` ➡️ `ULong`
	- Initializers
		- `UInt64(string)` ➡️ `string.toULong()`

- ⏱ `Range<Int>` ➡️ `IntRange`
	- Initializers
		- `Range<Int>(uncheckedBounds: (lower: index1, upper: index2))` ➡️ `IntRange(index1, index2)`
	- Properties
		- `range.lowerBound` ➡️ `range.start`
		- `range.upperBound` ➡️ `range.endInclusive`

- ⏱ `Error` ➡️ `Exception`

- ⏱ `Optional` ➡️  [`Nullable type`](https://kotlinlang.org/docs/reference/null-safety.html)
	- Methods
		- `optional.map(closure)` ➡️ `optional?.let(closure)`

- ⏱ `String` ➡️ `String`
	- `String.Index` ➡️ `Int`
	- Initializers
		- `String(any)` ➡️ `any.toString()`
		- `String(substring)` ➡️ `substring`
	- Properties
		- `string.isEmpty` ➡️ `string.isEmpty()`
		- `string.count` ➡️ `string.length`
		- `string.indices` ➡️ `string.indices`
		- `string.first` ➡️ `string,firstOrNull()`
		- `string.last` ➡️ `string.lastOrNull()`
		- `string.startIndex` ➡️ `0`
		- `string.endIndex` ➡️ `string.length`
		- `string.capitalized` ➡️ `string.capitalize()`
	- Methods
		- `string.uppercased()` ➡️ `string.toUpperCase()`
		- `string1.append(string2)` ➡️ `string1 += string2`
		- `string.append(character)` ➡️ `string += character`
		- `string.dropLast()` ➡️ `string.dropLast(1)`
		- `string.dropLast(int)` ➡️ `string.dropLast(int)`
		- `string.dropFirst()` ➡️ `string.drop(1)`
		- `string.dropFirst(int)` ➡️ `string.drop(int)`
		- `string.drop(while: closure)` ➡️ `string.dropWhile(closure)`
		- `string.firstIndex(of: character)` ➡️ `string.indexOrNull(character)`
		- `string.firstIndex(of: character)!` ➡️ `string.indexOf(character)`
		- `string.contains(where: closure)` ➡️ `(string.find(closure) != null)`
		- `string.prefix(int)` ➡️ `string.substring(0, int)`
		- `string.prefix(upTo: index)` ➡️ `string.substring(0, index)`
		- `string.prefix(while: closure)` ➡️ `string.takeWhile(closure)`
		- `string.suffix(from: index)` ➡️ 📖 `string.suffix(startIndex = index)`
		- `string1.hasPrefix(string2)` ➡️ `string1.startsWith(string)`
		- `string1.hasSuffix(_string2)` ➡️ `string1.endsWith(string2)`
		- `string.formIndex(before: &index)` ➡️ `index -= 1`
		- `string.index(before: index)` ➡️ `index - 1`
		- `string.index(after: index)` ➡️ `index + 1`
		- `string.index(index, offsetBy: int)` ➡️ `index + int`
		- `string1.replacingOccurrences(of: string2, with: string3)` ➡️ `string1.replace(_string2, _string3)`
	- Subscripts
		- `string[index...]` ➡️ `string.substring(index)`
		- `string[..<index]` ➡️ `string.substring(0, index)`
		- `string[...index]` ➡️ `string.substring(0, index + 1)`
		- `string[index1..<index2]` ➡️ `string.substring(index1, index2)`
		- `string[index1...index2]` ➡️ `string.substring(index1, index2 + 1)`

- ⏱ `Substring` ➡️ `String`
	- Methods
		- `substring.index(index, offsetBy: int)` ➡️ `index + int`

- ⏱ `Character` ➡️ `Char`
	- Methods
		- `character.uppercased()` ➡️ `character.toUpperCase()`

- ⏱ `Array` ➡️ `List`
	- [In general, prefer using Gryphon's List and MutableList types instead of Array](https://vinivendra.github.io/Gryphon/collections.html), unless you know what you're doing. The translations below work for `Array`, `List` and `MutableList`.
	- Properties
		- `array.isEmpty` ➡️ `array.isEmpty()`
		- `array.count` ➡️ `array.size`
		- `array.indices` ➡️ `array.indices`
		- `array.startIndex` ➡️ `0`
		- `array.endIndex` ➡️ `array.size`
		- `array.first` ➡️ `array.firstOrNull()`
		- `array.last` ➡️ `array.lastOrNull()`
	- Methods
		- `array.sorted()` ➡️ `array.sorted()`
		- `array.sorted(by: closure)` ➡️ 📖 `array.sorted(isAscending = closure)`
		- `array.firstIndex(where: closure)` ➡️ `array.indexOfFirst(closure)`
		- `array.firstIndex(of: any)` ➡️ `array.indexOf(any)`
		- `array.first(where: closure)` ➡️ `array.find(closure)`
		- `array.last(where: closure)` ➡️ `array.findLast(closure)`
		- `array.contains(any)` ➡️ `array.contains(any)`
		- `array.contains(where: closure)` ➡️ `(array.find(closure)  != null)`
		- `array.prefix(while: closure)` ➡️ `array.takeWhile(closure)`
		- `array.index(after: int)` ➡️ `int + 1`
		- `array.index(before: int)` ➡️ `int - 1`
		- `array.append(any)` ➡️ `array.add(any)`
		- `array.insert(any, at: int)` ➡️ `array.add(int, any)`
		- `array1.append(contentsOf: array2)` ➡️ `array.addAll(array2)`
		- `array.dropFirst()` ➡️ `array.drop(1)`
		- `array.dropLast()` ➡️ `array.dropLast(1)`
		- `array.removeFirst()` ➡️ `array.removeAt(0)`
		- `array.removeLast()` ➡️ 📖 `array.removeLast()`
		- `array.remove(at: int)` ➡️ `array.removeAt(int)`
		- `array.removeAll()` ➡️ `array.clear()`
		- `array.map(closure)` ➡️ `array.map(closure)`
		- `array.flatMap(closure)` ➡️ `array.flatMap(closure)`
		- `array.compactMap(closure)` ➡️ `array.map(closure).filterNotNull()`
		- `array.filter(closure)` ➡️ `array.filter(closure)`
		- `array.reduce(any, closure)` ➡️ `array.fold(any, closure)`
		- `stringArray.joined(separator: string)` ➡️ `stringArray.joinToString(separator = string)`
		- `stringArray.joined()` ➡️ `stringArray.joinToString(separator: "")`

- ⏱ `Dictionary` ➡️ `Map`
	- [In general, prefer using Gryphon's Map and MutableMap types instead of Dictionary](https://vinivendra.github.io/Gryphon/collections.html), unless you know what you're doing. The translations below work for `Dictionary `, `Map ` and `MutableMap `.
	- Properties
		- `dictionary.count` ➡️ `dictionary.size`
		- `dictionary.isEmpty` ➡️ `dictionary.isEmpty()`
	- Methods
		- `dictionary.map(closure)` ➡️ `dictionary.map(closure)`

- ⏱ `Equatable`
	- Swift structs that implicitly conform to `Equatable` become Kotlin data classes, which are always equatable by default.
	- Explicit declarations of `==` functions get translated into Kotlin's `equals` functions:

	```` swift
	// Swift
	static func ==(lhs: A, rhs: A) -> Bool {
		// User code
		return lhs.x > 0
	}
	````
	```` kotlin
	// Kotlin
	override open fun equals(other: Any?): Boolean {
		val lhs: A = this
		val rhs: Any? = other
		if (rhs is A) {
			// User code
			return lhs.x > 0
		}
		else {
			return false
		}
	}
	````

- ⏱ `Hashable`
	- Swift structs that implicitly conform to `Hashable` become Kotlin data classes, which are always hashable by default.

- ⏱ `CustomStringConvertible`
	- When a type conforms to `CustomStringConvertible` and declares a `var description: String`, that declaration becomes a `fun toString`:

	```` swift
	// Swift
	var description: String {
		return "my description"
	}
	````
	```` kotlin
	// Kotlin
	override open fun toString(): String {
		return "my description"
	}
	````

	- References to these declarations are also translated, from `customStringConvertible.description` to `customStringConvertible.toString()`.

- ⏱ `Range<T>`
- ⏱ `LosslessStringConvertible`
- ⏱ `CustomDebugStringConvertible`
- ⏱ `CaseIterable`
- ⏱ `RawRepresentable`
- ⏱ `Encodable`
- ⏱ `Decodable`
- ⏱ `CodingKey`
- ⏱ `CodingUserInfoKey`
- ⏱ `Encoder`
- ⏱ `Decoder`
- ⏱ `ExpressibleByArrayLiteral`
- ⏱ `ExpressibleByDictionaryLiteral`
- ⏱ `ExpressibleByIntegerLiteral`
- ⏱ `ExpressibleByFloatLiteral`
- ⏱ `ExpressibleByBooleanLiteral`
- ⏱ `ExpressibleByNilLiteral`
- ⏱ `ExpressibleByStringLiteral`
- ⏱ `ExpressibleByExtendedGraphemeClusterLiteral`
- ⏱ `ExpressibleByUnicodeScalarLiteral`
- ⏱ `ExpressibleByStringInterpolation`
- ⏱ `CommandLine`
- ⏱ `TextOutputStream`
- ⏱ `TextOutputStreamable`
- ⏱ `CustomReflectable`
- ⏱ `CustomLeafReflectable`
- ⏱ `CustomPlaygroundDisplayConvertible`
- ⏱ `KeyPath`
- ⏱ `PartialKeyPath`
- ⏱ `AnyKeyPath`
- ⏱ `WritableKeyPath`
- ⏱ `ReferenceWritableKeyPath`
- ⏱ `Hasher`
- ⏱ `Comparable`
- ⏱ `Identifiable`
- ⏱ `Set`
- ⏱ `Unicode`
- ⏱ `Result`
- ⏱ `ClosedRange`
- ⏱ `StaticString`
- ⏱ `OptionSet`

### Free functions

This section includes free functions, that is, functions that aren't methods of any specific type.

- ⏱ `print(Any, separator: String, terminator: String)`
	- `print(any)` ➡️ `println(any)`.
	- `print(any, terminator: "")` ➡️ `print(any)`.
- ⏱ `readLine(strippingNewLine: Bool)`
- ⏱ `debugPrint(Any, separator: String, terminator: String)`
- ⏱ `debugPrint<Target>(Any, separator: String, terminator: String, to: inout Target)`
- ⏱ `dump(T, name: String?, indent: Int, maxDepth: Int, maxItems: Int)`
- ⏱ `dump(T, to: TargetStream, name: String?, indent: Int, maxDepth: Int, maxItems: Int)`
- ⏱ `assert(Bool, String, file: StaticString, line: UInt)`
	- `assert(bool)` ➡️ `assert(bool)`.
- ⏱ `assertionFailure(String, file: StaticString, line: UInt)`
- ⏱ `precondition(Bool, String, file: StaticString, line: UInt)`
- ⏱ `preconditionFailure(String, file: StaticString, line: UInt)`
- ⏱ `fatalError(String, file: StaticString, line: UInt)`
	- `fatalError(string)` ➡️ `println("Fatal error: ${string}"); exitProcess(-1)`
- ⏱ `zip(sequence1, sequence2)`
	- `zip(array1, array2)` ➡️ `array1.zip(array2)` *(Also works for `Lists` and `MutableLists`)*
- ☑️ `min(int1, int2)` ➡️ `Math.min(int1, int2)`.

### Darwin
Translations for the `Darwin` module. Requires the use of `import Darwin` in Swift.

- ☑️ `sqrt(Double)` ➡️ `Math.sqrt(Double)`.


