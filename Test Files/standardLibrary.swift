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
print(0)
print(0, terminator: "")
print(0)

// Darwin
print(sqrt(9))

// String
print(String(0))

print("bla".description)

print("".isEmpty)
print("a".isEmpty)

print("".count)
print("a".count)

print("abc".first!)
print("".first)

print("abc".last!)
print("".last)

print(Double("0"))
print(Double("1"))

print(Float("0"))
print(Float("1"))

print(UInt64("0"))
print(UInt64("1"))

print(Int64("0"))
print(Int64("1"))

print(Int("0"))
print(Int("1"))

print("abcde".dropLast())

print("abcde".dropLast(2))

print("abcde".dropFirst())

print("abcde".dropFirst(2))

for index in string.indices {
	print(string[index])
}

print("abcde".prefix(4))

print("abcde".prefix(upTo: cIndex))

print("abcde"[cIndex...])

print("abcde"[..<cIndex])

print("abcde"[...cIndex])

print("abcde"[bIndex..<dIndex])

print("abcde"[bIndex...dIndex])

print(String(substring))

print(string.prefix(upTo: string.endIndex))

print(string[string.startIndex])

string.formIndex(before: &variableIndex)
print(string[variableIndex])

print(string[string.index(after: cIndex)])

print(string[string.index(before: cIndex)])

print(string[string.index(cIndex, offsetBy: 2)])

print(substring[substring.index(bIndex, offsetBy: 1)])

print("aaBaBAa".replacingOccurrences(of: "a", with: "A"))

print(string.prefix(while: { $0 != "c" }))

print(string.hasPrefix("abc"))
print(string.hasPrefix("d"))

print(string.hasSuffix("cde"))
print(string.hasSuffix("a"))

print(range.lowerBound == string.startIndex)
print(range.lowerBound == string.endIndex)

print(range.upperBound == string.startIndex)
print(range.upperBound == string.endIndex)

let newRange =
	Range<String.Index>(uncheckedBounds:
		(lower: string.startIndex,
		 upper: string.endIndex))
print(newRange.lowerBound == string.startIndex)
print(newRange.lowerBound == string.endIndex)
print(newRange.upperBound == string.startIndex)
print(newRange.upperBound == string.endIndex)

variableString.append("fgh")
print(variableString)

variableString.append(character)
print(variableString)

print(string.capitalized)

print(string.uppercased())

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
