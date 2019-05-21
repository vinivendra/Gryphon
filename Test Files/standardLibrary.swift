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

import Foundation

// Print
print(0)
print(0, terminator: "")
print(0)

// Darwin
print(sqrt(9))

// String
print("".isEmpty)
print("a".isEmpty)

print("".count)
print("a".count)

print(Double("0"))
print(Double("1"))

print("abcde".dropLast())

print("abcde".prefix(4))

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

// Dictionary
let dictionary = [10: 1, 20: 2, 30: 3]
let reduceResult = dictionary.reduce(0) { acc, keyValue in acc + keyValue.value }
print(reduceResult)

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
