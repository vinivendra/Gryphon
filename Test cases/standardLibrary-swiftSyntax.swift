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

// gryphon insert: import kotlin.system.*

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

// MARK: - Define the templates
private func gryphonTemplates() {
	// User-defined templates
	let _int: Int = 0
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
let substring: Substring = /* gryphon value: "abcd" */ "abcde".dropLast()
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
// gryphon insert: 	printTest(contents = a, testName = "User template")
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

//////////////////////////////////////////////////////////
// Check autoclosure matches
if false {
	fatalError("Never reached")
}
