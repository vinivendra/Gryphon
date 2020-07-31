//
// Copyright 2018 Vinicius Jorge Vendramini
//
// Licensed under the Hippocratic License, Version 2.1;
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
// https://firstdonoharm.dev/version/2/1/license.md
//
// To the full extent allowed by law, this software comes "AS IS,"
// WITHOUT ANY WARRANTY, EXPRESS OR IMPLIED, and licensor and any other
// contributor shall not be liable to anyone for any damages or other
// liability arising from, out of, or in connection with the sotfware
// or this license, under any kind of legal claim.
// See the License for the specific language governing permissions and
// limitations under the License.
//

// gryphon output: Test cases/Bootstrap Outputs/standardLibrary.swiftAST
// gryphon output: Test cases/Bootstrap Outputs/standardLibrary.gryphonASTRaw
// gryphon output: Test cases/Bootstrap Outputs/standardLibrary.gryphonAST
// gryphon output: Test cases/Bootstrap Outputs/standardLibrary.kt

import Foundation

// MARK: - Define template classes and operators

// gryphon ignore
private class _GRYTemplate {
	static func dot(_ left: _GRYTemplate, _ right: String) -> _GRYDotTemplate {
		return _GRYDotTemplate(left, right)
	}

	static func dot(_ left: String, _ right: String) -> _GRYDotTemplate {
		return _GRYDotTemplate(_GRYLiteralTemplate(string: left), right)
	}

	static func call(_ function: _GRYTemplate, _ parameters: [_GRYParameterTemplate]) -> _GRYCallTemplate {
		return _GRYCallTemplate(function, parameters)
	}

	static func call(_ function: String, _ parameters: [_GRYParameterTemplate]) -> _GRYCallTemplate {
		return _GRYCallTemplate(function, parameters)
	}
}

// gryphon ignore
private class _GRYDotTemplate: _GRYTemplate {
	let left: _GRYTemplate
	let right: String

	init(_ left: _GRYTemplate, _ right: String) {
		self.left = left
		self.right = right
	}
}

// gryphon ignore
private class _GRYCallTemplate: _GRYTemplate {
	let function: _GRYTemplate
	let parameters: [_GRYParameterTemplate]

	init(_ function: _GRYTemplate, _ parameters: [_GRYParameterTemplate]) {
		self.function = function
		self.parameters = parameters
	}

	//
	init(_ function: String, _ parameters: [_GRYParameterTemplate]) {
		self.function = _GRYLiteralTemplate(string: function)
		self.parameters = parameters
	}
}

// gryphon ignore
private class _GRYParameterTemplate: ExpressibleByStringLiteral {
	let label: String?
	let template: _GRYTemplate

	private init(_ label: String?, _ template: _GRYTemplate) {
		if let existingLabel = label {
			if existingLabel == "_" || existingLabel == "" {
				self.label = nil
			}
			else {
				self.label = label
			}
		}
		else {
			self.label = label
		}

		self.template = template
	}

	required init(stringLiteral: String) {
		self.label = nil
		self.template = _GRYLiteralTemplate(string: stringLiteral)
	}

	static func labeledParameter(_ label: String?, _ template: _GRYTemplate) -> _GRYParameterTemplate {
		return _GRYParameterTemplate(label, template)
	}

	static func labeledParameter(_ label: String?, _ template: String) -> _GRYParameterTemplate {
		return _GRYParameterTemplate(label, _GRYLiteralTemplate(string: template))
	}

	static func dot(_ left: _GRYTemplate, _ right: String) -> _GRYParameterTemplate {
		return _GRYParameterTemplate(nil, _GRYDotTemplate(left, right))
	}

	static func dot(_ left: String, _ right: String) -> _GRYParameterTemplate {
		return _GRYParameterTemplate(nil, _GRYDotTemplate(_GRYLiteralTemplate(string: left), right))
	}

	static func call(_ function: _GRYTemplate, _ parameters: [_GRYParameterTemplate]) -> _GRYParameterTemplate {
		return _GRYParameterTemplate(nil, _GRYCallTemplate(function, parameters))
	}

	static func call(_ function: String, _ parameters: [_GRYParameterTemplate]) -> _GRYParameterTemplate {
		return _GRYParameterTemplate(nil, _GRYCallTemplate(function, parameters))
	}
}

// gryphon ignore
private class _GRYLiteralTemplate: _GRYTemplate {
	let string: String

	init(string: String) {
		self.string = string
	}
}

// gryphon ignore
private class _GRYConcatenatedTemplate: _GRYTemplate {
	let left: _GRYTemplate
	let right: _GRYTemplate

	init(left: _GRYTemplate, right: _GRYTemplate) {
		self.left = left
		self.right = right
	}
}

// gryphon ignore
private func + (left: _GRYTemplate, right: _GRYTemplate) -> _GRYConcatenatedTemplate {
	_GRYConcatenatedTemplate(left: left, right: right)
}

// gryphon ignore
private func + (left: String, right: _GRYTemplate) -> _GRYConcatenatedTemplate {
	_GRYConcatenatedTemplate(left: _GRYLiteralTemplate(string: left), right: right)
}

// gryphon ignore
private func + (left: _GRYTemplate, right: String) -> _GRYConcatenatedTemplate {
	_GRYConcatenatedTemplate(left: left, right: _GRYLiteralTemplate(string: right))
}

// MARK: - Define special types as stand-ins for some protocols and other types

// Replacement for Hashable
// gryphon ignore
private struct _Hashable: Hashable { }

// Replacement for Comparable
// gryphon ignore
private struct _Comparable: Comparable {
	static func < (lhs: _Comparable, rhs: _Comparable) -> Bool {
		return false
	}
}

// Replacement for Optional
// gryphon ignore
private struct _Optional { }

// Replacement for CustomStringConvertible
// gryphon ignore
private struct _CustomStringConvertible: CustomStringConvertible {
	var description: String = ""
}

// Replacement for Any
// gryphon ignore
private struct _Any: CustomStringConvertible, LosslessStringConvertible {
	init() { }

	var description: String = ""

	init?(_ description: String) {
		return nil
	}
}

// MARK: - Define the templates
private func gryphonTemplates() {

	// MARK: Declare placeholder variables to use in the templates
	var _bool: Bool = true
	var _strArray: [String] = []
	var _array: [Any] = []
	var _array1: [Any] = []
	var _array2: [Any] = []
	let _array3: [Any] = []
	var _arrayOfOptionals: [Any?] = []
	var _comparableArray: [_Comparable] = []
	let _comparable = _Comparable()
	var _index: String.Index = "abc".endIndex
	let _index1: String.Index = "abc".startIndex
	let _index2: String.Index = "abc".startIndex
	var _string: String = "abc"
	var _string1: String = "abc"
	let _string2: String = "abc"
	let _string3: String = "abc"
	let _character: Character = "a"
	let _substring: Substring = "abc".dropLast()
	let _range: Range<String.Index> = _string.startIndex..<_string.endIndex
	let _any: Any = "abc"
	let _anyType: _Any = _Any()
	let _customStringConvertible = _CustomStringConvertible()
	let _optional: _Optional? = _Optional()
	let _float: Float = 0
	let _double: Double = 0
	let _double1: Double = 0
	let _double2: Double = 0
	let _int: Int = 0
	let _int1: Int = 0
	let _int2: Int = 0
	let _dictionary: [_Hashable: Any] = [:]
	let _closure: (Any, Any) -> Any = { a, b in a }
	let _closure2: (Any) -> Any = { a in a }
	let _closure3: (Any) -> Bool = { _ in true }
	let _closure4: (_Optional) -> Any = { _ in true }
	let _closure5: (Character) -> Bool = { _ in true }
	let _closure6: (Any) -> Any? = { a in a }
	let _closure7: (_Comparable, _Comparable) -> Bool = { _, _ in true }

	// MARK: Declare the templates

	// System
	_ = print(_any)
	_ = _GRYTemplate.call("println", ["_any"])

	_ = print(_any, terminator: "")
	_ = _GRYTemplate.call("print", ["_any"])

	_ = fatalError(_string)
	_ = _GRYTemplate.call("println",
			["\"Fatal error: ${_string}\""]) +
		"; " +
		_GRYTemplate.call("exitProcess", ["-1"])

	_ = assert(_bool)
	_ = _GRYTemplate.call("assert", ["_bool"])

	// Darwin
	_ = sqrt(_double)
	_ = _GRYTemplate.call(.dot("Math", "sqrt"), ["_double"])

	// Numerics
	_ = Double(_int)
	_ = "_int.toDouble()"

	_ = Float(_int)
	_ = "_int.toFloat()"

	_ = Double(_float)
	_ = "_float.toDouble()"

	_ = Int(_float)
	_ = "_float.toInt()"

	_ = Float(_double)
	_ = "_double.toFloat()"

	_ = Int(_double)
	_ = "_double.toInt()"

	// String
	_ = String(_anyType)
	_ = _GRYTemplate.call(.dot("_anyType", "toString"), [])

	_ = _customStringConvertible.description
	_ = _GRYTemplate.call(.dot("_customStringConvertible", "toString"), [])

	_ = _string.isEmpty
	_ = _GRYTemplate.call(.dot("_string", "isEmpty"), [])

	_ = _string.count
	_ = _GRYTemplate.dot("_string", "length")

	_ = _string.first
	_ = _GRYTemplate.call(.dot("_string", "firstOrNull"), [])

	_ = _string.last
	_ = _GRYTemplate.call(.dot("_string", "lastOrNull"), [])

	_ = Double(_string)
	_ = _GRYTemplate.call(.dot("_string", "toDouble"), [])

	_ = Float(_string)
	_ = _GRYTemplate.call(.dot("_string", "toFloat"), [])

	_ = UInt64(_string)
	_ = _GRYTemplate.call(.dot("_string", "toULong"), [])

	_ = Int64(_string)
	_ = _GRYTemplate.call(.dot("_string", "toLong"), [])

	_ = Int(_string)
	_ = _GRYTemplate.call(.dot("_string", "toIntOrNull"), [])

	_ = _string.dropLast()
	_ = _GRYTemplate.call(.dot("_string", "dropLast"), ["1"])

	_ = _string.dropLast(_int)
	_ = _GRYTemplate.call(.dot("_string", "dropLast"), ["_int"])

	_ = _string.dropFirst()
	_ = _GRYTemplate.call(.dot("_string", "drop"), ["1"])

	_ = _string.dropFirst(_int)
	_ = _GRYTemplate.call(.dot("_string", "drop"), ["_int"])

	_ = _string.drop(while: _closure5)
	_ = _GRYTemplate.call(.dot("_string", "dropWhile"), ["_closure5"])

	_ = _string.indices
	_ = _GRYTemplate.dot("_string", "indices")

	_ = _string.firstIndex(of: _character)!
	_ = _GRYTemplate.call(.dot("_string", "indexOf"), ["_character"])

	_ = _string.contains(where: _closure5)
	_ = "(" + _GRYTemplate.call(.dot("_string", "find"), ["_closure5"]) + " != null)"

	_ = _string.firstIndex(of: _character)
	_ = _GRYTemplate.call(.dot("_string", "indexOrNull"), ["_character"])

	_ = _string.prefix(_int)
	_ = _GRYTemplate.call(.dot("_string", "substring"), ["0", "_int"])

	_ = _string.prefix(upTo: _index)
	_ = _GRYTemplate.call(.dot("_string", "substring"), ["0", "_index"])

	_ = _string[_index...]
	_ = _GRYTemplate.call(.dot("_string", "substring"), ["_index"])

	_ = _string[..<_index]
	_ = _GRYTemplate.call(.dot("_string", "substring"), ["0", "_index"])

	_ = _string[..._index]
	_ = _GRYTemplate.call(.dot("_string", "substring"), ["0", "_index + 1"])

	_ = _string[_index1..<_index2]
	_ = _GRYTemplate.call(.dot("_string", "substring"), ["_index1", "_index2"])

	_ = _string[_index1..._index2]
	_ = _GRYTemplate.call(.dot("_string", "substring"), ["_index1", "_index2 + 1"])

	_ = String(_substring)
	_ = "_substring"

	_ = _string.endIndex
	_ = _GRYTemplate.dot("_string", "length")

	_ = _string.startIndex
	_ = "0"

	_ = _string.formIndex(before: &_index)
	_ = "_index -= 1"

	_ = _string.index(after: _index)
	_ = "_index + 1"

	_ = _string.index(before: _index)
	_ = "_index - 1"

	_ = _string.index(_index, offsetBy: _int)
	_ = "_index + _int"

	_ = _substring.index(_index, offsetBy: _int)
	_ = "_index + _int"


	_ = _string1.replacingOccurrences(of: _string2, with: _string3)
	_ = _GRYTemplate.call(.dot("_string1", "replace"), ["_string2", "_string3"])

	_ = _string1.prefix(while: _closure5)
	_ = _GRYTemplate.call(.dot("_string1", "takeWhile"), ["_closure5"])

	_ = _string1.hasPrefix(_string2)
	_ = _GRYTemplate.call(.dot("_string1", "startsWith"), ["_string2"])

	_ = _string1.hasSuffix(_string2)
	_ = _GRYTemplate.call(.dot("_string1", "endsWith"), ["_string2"])

	_ = _range.lowerBound
	_ = _GRYTemplate.dot("_range", "start")

	_ = _range.upperBound
	_ = _GRYTemplate.dot("_range", "endInclusive")

	_ = Range<String.Index>(uncheckedBounds: (lower: _index1, upper: _index2))
	_ = _GRYTemplate.call("IntRange", ["_index1", "_index2"])


	_ = _string1.append(_string2)
	_ = "_string1 += _string2"

	_ = _string.append(_character)
	_ = "_string += _character"

	_ = _string.capitalized
	_ = _GRYTemplate.call(.dot("_string", "capitalize"), [])

	_ = _string.uppercased()
	_ = _GRYTemplate.call(.dot("_string", "toUpperCase"), [])

	// Character
	_ = _character.uppercased()
	_ = _GRYTemplate.call(.dot("_character", "toUpperCase"), [])

	// Array
	_ = _array.append(_any)
	_ = _GRYTemplate.call(.dot("_array", "add"), ["_any"])

	_ = _array.insert(_any, at: _int)
	_ = _GRYTemplate.call(.dot("_array", "add"), ["_int", "_any"])

	_ = _arrayOfOptionals.append(nil)
	_ = _GRYTemplate.call(.dot("_arrayOfOptionals", "add"), ["null"])

	_ = _array1.append(contentsOf: _array2)
	_ = _GRYTemplate.call(.dot("_array1", "addAll"), ["_array2"])

	_ = _array1.append(contentsOf: _array3)
	_ = _GRYTemplate.call(.dot("_array1", "addAll"), ["_array3"])

	_ = _array.isEmpty
	_ = _GRYTemplate.call(.dot("_array", "isEmpty"), [])

	_ = _strArray.joined(separator: _string)
	_ = _GRYTemplate.call(
		.dot("_strArray", "joinToString"),
		[.labeledParameter("separator", "_string")])

	_ = _strArray.joined()
	_ = _GRYTemplate.call(
		.dot("_strArray", "joinToString"),
		[.labeledParameter("separator", "\"\"")])

	_ = _array.count
	_ = _GRYTemplate.dot("_array", "size")

	_ = _array.indices
	_ = _GRYTemplate.dot("_array", "indices")

	_ = _array.startIndex
	_ = "0"

	_ = _array.endIndex
	_ = _GRYTemplate.dot("_array", "size")

	_ = _array.index(after: _int)
	_ = "_int + 1"

	_ = _array.index(before: _int)
	_ = "_int - 1"

	_ = _array.first
	_ = _GRYTemplate.call(.dot("_array", "firstOrNull"), [])

	_ = _array.first(where: _closure3)
	_ = _GRYTemplate.call(.dot("_array", "find"), ["_closure3"])

	_ = _array.last(where: _closure3)
	_ = _GRYTemplate.call(.dot("_array", "findLast"), ["_closure3"])

	_ = _array.last
	_ = _GRYTemplate.call(.dot("_array", "lastOrNull"), [])

	_ = _array.prefix(while: _closure3)
	_ = _GRYTemplate.call(.dot("_array", "takeWhile"), ["_closure3"])

	_ = _array.removeFirst()
	_ = _GRYTemplate.call(.dot("_array", "removeAt"), ["0"])

	_ = _array.remove(at: _int)
	_ = _GRYTemplate.call(.dot("_array", "removeAt"), ["_int"])

	_ = _array.removeAll()
	_ = "_array.clear()"

	_ = _array.dropFirst()
	_ = _GRYTemplate.call(.dot("_array", "drop"), ["1"])

	_ = _array.dropLast()
	_ = _GRYTemplate.call(.dot("_array", "dropLast"), ["1"])


	_ = _array.map(_closure2)
	_ = _GRYTemplate.call(.dot("_array", "map"), ["_closure2"])

	_ = _array.flatMap(_closure6)
	_ = _GRYTemplate.call(.dot("_array", "flatMap"), ["_closure6"])

	_ = _array.compactMap(_closure2)
	_ = _GRYTemplate.call(.dot(.call(.dot("_array", "map"), ["_closure2"]), "filterNotNull"), [])

	_ = _array.filter(_closure3)
	_ = _GRYTemplate.call(.dot("_array", "filter"), ["_closure3"])

	_ = _array.reduce(_any, _closure)
	_ = _GRYTemplate.call(.dot("_array", "fold"), ["_any", "_closure"])

	_ = zip(_array1, _array2)
	_ = _GRYTemplate.call(.dot("_array1", "zip"), ["_array2"])

	_ = _array.firstIndex(where: _closure3)
	_ = _GRYTemplate.call(.dot("_array", "indexOfFirst"), ["_closure3"])

	_ = _array.contains(where: _closure3)
	_ = "(" + _GRYTemplate.call(.dot("_array", "find"), ["_closure3"]) + " != null)"

	_ = _comparableArray.sorted()
	_ = _GRYTemplate.call(.dot("_comparableArray", "sorted"), [])

	_ = _comparableArray.contains(_comparable)
	_ = _GRYTemplate.call(.dot("_comparableArray", "contains"), ["_comparable"])

	_ = _comparableArray.firstIndex(of: _comparable)
	_ = _GRYTemplate.call(.dot("_comparableArray", "indexOf"), ["_comparable"])

	// Dictionary
	_ = _dictionary.count
	_ = _GRYTemplate.dot("_dictionary", "size")

	_ = _dictionary.isEmpty
	_ = _GRYTemplate.call(.dot("_dictionary", "isEmpty"), [])

	_ = _dictionary.map(_closure2)
	_ = _GRYTemplate.call(.dot("_dictionary", "map"), ["_closure2"])

	// Int
	_ = Int.max
	_ = _GRYTemplate.dot("Int", "MAX_VALUE")

	_ = Int.min
	_ = _GRYTemplate.dot("Int", "MIN_VALUE")

	_ = min(_int1, _int2)
	_ = _GRYTemplate.call(.dot("Math", "min"), ["_int1", "_int2"])

	_ = _int1..._int2
	_ = "_int1.._int2"

	_ = _int1..<_int2
	_ = "_int1 until _int2"

	// Double
	_ = _double1..._double2
	_ = _GRYTemplate.call(.dot("(_double1)", "rangeTo"), ["_double2"])

	// Optional
	_ = _optional.map(_closure4)
	_ = _GRYTemplate.call(.dot("_optional?", "let"), ["_closure4"])

	// User-defined templates
	var _a = A()

	f(of: _int)
	"g(a = _int)"

	_a.string.first
	_GRYTemplate.dot(.dot("_a", "string"), "firstOrNull()")
}

// MARK: - Tests

// gryphon ignore
typealias PrintContents = Any
// gryphon insert: typealias PrintContents = Any?

func printTest(_ contents: PrintContents, _ testName: String) {
	let firstColumnSize = 40

	let contentsString = "\(contents)"
	print(contentsString, terminator: "")
	if contentsString.count < firstColumnSize {
		for _ in contentsString.count..<firstColumnSize {
			print(" ", terminator: "")
		}
	}
	print("(\(testName))")
}

// Print
print("Hello, world!")
print(42)

let message = "A message in a variable."
print(message)

let number = 13
print(number)

print("Here's a bool literal: \(true).\nAnd here's a number: \(17).")
print("The stored message is: \(message)\nAnd the stored number is: \(number).")

print(0, terminator: "")
print(" (Print)")

// Darwin
printTest(sqrt(9), "Sqrt")

// Numerics
let int: Int = 1
let float: Float = 0.1
let float1: Float = 0.5
let float2: Float = 0.9
let double: Double = 0.1
let double1: Double = 0.5
let double2: Double = 0.9

printTest(Double(int), "Int to Double")
printTest(Float(int), "Int to Float")
printTest(Double(float), "Float to Double")
printTest(Int(float), "Float (0.1) to Int")
printTest(Int(float1), "Float (0.5) to Int")
printTest(Int(float2), "Float (0.9) to Int")
printTest(Float(double), "Double to Float")
printTest(Int(double), "Double (0.1) to Int")
printTest(Int(double1), "Double (0.5) to Int")
printTest(Int(double2), "Double (0.9) to Int")

// String
let string = "abcde"
let bIndex = /* gryphon value: 1 */ string.index(string.startIndex, offsetBy: 1)
let cIndex = /* gryphon value: 2 */ string.index(string.startIndex, offsetBy: 2)
let dIndex = /* gryphon value: 3 */ string.index(string.startIndex, offsetBy: 3)
var variableIndex = cIndex
let substring = /* gryphon value: "abcd" */ "abcde".dropLast()
let range = /* gryphon value: IntRange(0, string.length) */ string.startIndex..<string.endIndex
var variableString = "abcde"
let character: Character = "i"

printTest(String(0), "String(_anyType)")

printTest("bla".description, "String description")

printTest("".isEmpty, "String isEmpty")
printTest("a".isEmpty, "String isEmpty")

printTest("".count, "String count")
printTest("a".count, "String count")

printTest("abc".first!, "String first")
printTest("".first, "String first")

printTest("abc".last!, "String last")
printTest("".last, "String last")

printTest(Double("0"), "String double")
printTest(Double("1"), "String double")

printTest(Float("0"), "String float")
printTest(Float("1"), "String float")

printTest(UInt64("0"), "String uint64")
printTest(UInt64("1"), "String uint64")

printTest(Int64("0"), "String int64")
printTest(Int64("1"), "String int64")

printTest(Int("0"), "String int")
printTest(Int("1"), "String int")

printTest("abcde".dropLast(), "String dropLast()")

printTest("abcde".dropLast(2), "String dorpLast(int)")

printTest("abcde".dropFirst(), "String dropFirst")

printTest("abcde".dropFirst(2), "String dropFirst(int)")

for index in string.indices {
	printTest(string[index], "String indices")
}

printTest("abcde".prefix(4), "String prefix")

printTest("abcde".prefix(upTo: cIndex), "String prefix(upTo:)")

printTest("abcde"[cIndex...], "String index...")

printTest("abcde"[..<cIndex], "String ..<index")

printTest("abcde"[...cIndex], "String ...index")

printTest("abcde"[bIndex..<dIndex], "String index..<index")

printTest("abcde"[bIndex...dIndex], "String index...index")

printTest(String(substring), "String String(substring)")

printTest(string.prefix(upTo: string.endIndex), "String endIndex")

printTest(string[string.startIndex], "String startIndex")

string.formIndex(before: &variableIndex)
printTest(string[variableIndex], "String formIndex(brefore:)")

printTest(string[string.index(after: cIndex)], "String index after")

printTest(string[string.index(before: cIndex)], "String index before")

printTest(string[string.index(cIndex, offsetBy: 2)], "String index offset by")

printTest(substring[substring.index(bIndex, offsetBy: 1)], "String substring index offset by")

printTest("aaBaBAa".replacingOccurrences(of: "a", with: "A"), "String replacing occurrences")

printTest(string.prefix(while: { $0 != "c" }), "String prefix while")

printTest(string.hasPrefix("abc"), "String hasPrefix")
printTest(string.hasPrefix("d"), "String hasPrefix")

printTest(string.hasSuffix("cde"), "String hasSuffix")
printTest(string.hasSuffix("a"), "String hasSuffix")

printTest(range.lowerBound == string.startIndex, "String range lowerBound")
printTest(range.lowerBound == string.endIndex, "String range lowerBound")

printTest(range.upperBound == string.startIndex, "String range upperBound")
printTest(range.upperBound == string.endIndex, "String range upperBound")

let newRange =
	Range<String.Index>(uncheckedBounds:
		(lower: string.startIndex,
		 upper: string.endIndex))
printTest(newRange.lowerBound == string.startIndex, "String range uncheckedBounds")
printTest(newRange.lowerBound == string.endIndex, "String range uncheckedBounds")
printTest(newRange.upperBound == string.startIndex, "String range uncheckedBounds")
printTest(newRange.upperBound == string.endIndex, "String range uncheckedBounds")

variableString.append("fgh")
printTest(variableString, "String append")

variableString.append(character)
printTest(variableString, "String append character")

printTest(string.capitalized, "String capitalized")

printTest(string.uppercased(), "String uppercased")

// Character
printTest(character.uppercased(), "Character uppercased")

// Array
// gryphon ignore
var array = [1, 2, 3]
let array2 = [2, 1]
// gryphon ignore
var array3 = [1]
let array4 = [2, 1]
// gryphon ignore
var arrayOfOptionals: [Int?] = [1]
let emptyArray: [Int] = []
let stringArray = ["1", "2", "3"]
// gryphon insertInMain: val array: MutableList<Int> = mutableListOf(1, 2, 3)
// gryphon insertInMain: val array3: MutableList<Int> = mutableListOf(1)
// gryphon insertInMain: val arrayOfOptionals: MutableList<Int?> = mutableListOf(1)

printTest(array, "Array append")
array.append(4)
printTest(array, "Array append")

array.insert(0, at: 0)
printTest(array, "Array insert")
array.insert(5, at: 5)
printTest(array, "Array insert")
array.insert(10, at: 3)
printTest(array, "Array insert")

arrayOfOptionals.append(nil)
printTest(arrayOfOptionals, "Array append nil")

array3.append(contentsOf: array2)
printTest(array3, "Array append(contentsOf:) constant")

array3.append(contentsOf: array4)
printTest(array3, "Array append(contentsOf:) variable")

printTest(emptyArray.isEmpty, "Array isEmpty")
printTest(array.isEmpty, "Array isEmpty")

printTest(stringArray.joined(separator: " => "), "Array joined separator")

printTest(stringArray.joined(), "Array joined")

printTest(array.count, "Array count")
printTest(stringArray.count, "Array count")

for index in array.indices {
	printTest(array[index], "Array indices")
}

printTest(array[array.startIndex], "Array startIndex")

printTest(array.endIndex == array.count, "Array endIndex")

printTest(array.index(after: 2), "Array index after")

printTest(array.index(before: 2), "Array index before")

printTest(array.first, "Array first")
printTest(emptyArray.first, "Array first")

printTest(array.first(where: { $0 > 3 }), "Array first where")

printTest(array.last(where: { $0 > 3 }), "Array last where")

printTest(array.last, "Array last")

array.removeFirst()
printTest(array, "Array remove first")

printTest(array.dropFirst(), "Array drop first")

printTest(array.dropLast(), "Array drop last")

printTest(array.map { $0 + 1 }, "Array map")

printTest(array.flatMap { [$0 + 1, $0 + 2] }, "Array flat map")

printTest(array.compactMap { $0 == 10 ? $0 : nil }, "Array compact map")

printTest(array.filter { $0 < 10 }, "Array filter")

printTest(array.reduce(1) { acc, el in acc * el }, "Array reduce")

for (element1, element2) in zip(array, array2) {
	printTest(element1, "Array zip")
	printTest(element2, "Array zip")
}

printTest(array.firstIndex(where: { $0 > 2 }), "Array firstIndex")

printTest(array.contains(where: { $0 > 2 }), "Array contains where")
printTest(array.contains(where: { $0 > 2000 }), "Array contains where")

printTest(array.sorted(), "Array sorted")

printTest(array.contains(10), "Array contains")
printTest(array.contains(10000), "Array contains")

printTest(array.firstIndex(of: 10), "Array firstIndex of")

array.removeAll()
printTest(array, "Array remove all")

// Dictionaries
let dictionary = [1: 1, 2: 2]
let emptyDictionary: [Int: Int] = [:]

printTest(dictionary.count, "Dictionary count")

printTest(dictionary.isEmpty, "Dictionary isEmpty")
printTest(emptyDictionary.isEmpty, "Dictionary isEmpty")

let mappedDictionary = dictionary.map { $0.value + $0.key }
printTest(mappedDictionary[0], "Dictionary map")
printTest(mappedDictionary[1], "Dictionary map")

// Int
printTest(Int.max, "Int max")

printTest(Int.min, "Int min")

printTest(min(0, 1), "Int min(a, b)")
printTest(min(15, -30), "Int min(a, b)")

printTest(0...3, "Int ...")

printTest(-1..<3, "Int ..<")

// Double
printTest(1.0...3.0, "Double ...")

//
// Recursive matches
printTest(Int.min..<0, "Recursive matches")

//////////////////////////////////////////////////////////
// Auxiliary declarations for the following tests
class A {
	let string: String = ""
}

class B {
	var description: String = ""
}

class C: CustomStringConvertible {
	var description: String = ""
}

// gryphon ignore
func f(of a: Int) {
	printTest(a, "User template")
}

// gryphon insert: fun g(a: Int) {
// gryphon insert: 	printTest(a, "User template")
// gryphon insert: }

//////////////////////////////////////////////////////////
// User defined templates
f(of: 10)

// Adding `?` in dot chains declared by templates
let maybeA: A? = nil
if let a = maybeA, let b = a.string.first {
}

// Adding `@map` labels in closures called by functions in templates
print([1, 2, 3].map { (a: Int) -> Int in
	if a > 1 {
		return 1
	}
	else {
		return 2
	}
})

// Adding labels for nested closures
print([1, 2, 3].map { (a: Int) -> [Int] in
	if a > 1 {
		return [1, 2, 3].filter { (b: Int) -> Bool in
			if b > 1 {
				return true
			}
			else {
				return false
			}
		}
	}
	else {
		return [2]
	}
})

//////////////////////////////////////////////////////////
// Inheritance checking

// B doesn't conform to CustomStringConvertible, so this is `B().description`
let description1 = B().description

// C conforms to CustomStringConvertible, so this is `C().toString()`
let description2 = C().description

// Local variables don't get translated
let description: String = ""

// Nested classes get translated
class D {
	class E: CustomStringConvertible {
		var description: String = ""
	}
}
