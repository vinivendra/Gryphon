//
// Copyright 2018 Vinícius Jorge Vendramini
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
// http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.
//

// gryphon output: Test Files/Bootstrap Outputs/standardLibrary.swiftAST
// gryphon output: Test Files/Bootstrap Outputs/standardLibrary.gryphonASTRaw
// gryphon output: Test Files/Bootstrap Outputs/standardLibrary.gryphonAST
// gryphon output: Test Files/Bootstrap Outputs/standardLibrary.kt

import Foundation

typealias PrintContents = Any // kotlin: ignore
// declaration: typealias PrintContents = Any?

func printTest(_ contents: PrintContents, _ testName: String) {
	let contentsString = "\(contents)"
	print(contentsString, terminator: "")
	for _ in contentsString.count..<20 {
		print(" ", terminator: "")
	}
	print("(\(testName))")
}

let string = "abcde"
let bIndex = string.index(string.startIndex, offsetBy: 1) // value: 1
let cIndex = string.index(string.startIndex, offsetBy: 2) // value: 2
let dIndex = string.index(string.startIndex, offsetBy: 3) // value: 3
var variableIndex = cIndex
let substring = "abcde".dropLast() // value: "abcd"
let range = string.startIndex..<string.endIndex // value: IntRange(0, string.length)
var variableString = "abcde"
let character: Character = "i"

// Print
print(0, terminator: "")
print("                   (Print)")

// Darwin
printTest(sqrt(9), "Sqrt")

// String
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

// Array
var array = [1, 2, 3]

print(array)
array.append(4)
print(array)

let emptyArray: [Int] = []
print(emptyArray.isEmpty)
print(array.isEmpty)

let stringArray = ["1", "2", "3"]
print(stringArray.joined(separator: " => "))

print(array.count)
print(stringArray.count)

print(array.last)

print(array.dropLast())

// Int
print(Int.max)

print(Int.min)

print(min(0, 1))
print(min(15, -30))

print(0...3)
print(-1..<3)

// Double
print(1.0...3.0)

//
// Recursive matches
print(Int.min..<0)

//
// User-defined templates
func f(of a: Int) { // kotlin: ignore
	print(a)
}

// declaration: fun f(a: Int) {
// declaration: 	println(a)
// declaration: }

f(of: 10)

func gryphonTemplates() {
	var _int = 0

	f(of: _int)
	"f(a = _int)"
}
