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

// gryphon output: Test cases/Bootstrap Outputs/misc.swiftAST
// gryphon output: Test cases/Bootstrap Outputs/misc.gryphonASTRaw
// gryphon output: Test cases/Bootstrap Outputs/misc.gryphonAST
// gryphon output: Test cases/Bootstrap Outputs/misc.kt

// While
var i = 1
while i <= 10 {
	print(i)
	i += 1
}

// Typealias
typealias A = Int

// Typealias with inner types
class B {
	class C {

	}
}

typealias BC = B.C

// Typealias with generics
class List<T> { } // gryphon ignore

typealias ListInt = List<Int>

//
var a: A = 0
var bc: BC

// `a ?: return`
func f(a: Int?) {
	if a == nil {
		return
	}
	print(a)
}

f(a: 10)
print("==")
f(a: nil)
print("==")

// Dictionary entries
let dict = [1: 2]

for entry in dict {
	print(entry.key)
	print(entry.value)
}

// Protocol extensions
protocol D {
	var d: Int { get }
}

extension D {
	func f() {
		print(self.d)
	}
}

//// Regression tests

// Test upcasts to optional types
class Base { }
class Subclass: Base {
	// gryphon insert: constructor(): super() { }
}

let maybeSubclass: Subclass? = nil
let maybeBases: [Base?] = [maybeSubclass]

// Test Range<Int>.Element
let range = 0..<1
for i in range {
	let x = i
}

// Test Array<Whatever>.Index
let array = [1, 2, 3]
let arrayIndex = array.firstIndex(of: 1)

// Test Array<Whatever>.ArrayLiteralElement
let bla: Array<Int>.ArrayLiteralElement = 1

// Test types with parentheses
var foo: (() -> ())? = nil

// Description as toString() for properties with getters
class E: CustomStringConvertible {
	var description: String {
		return "abc"
	}
}

// Description as toString() for properties without getters
class F: CustomStringConvertible {
	var description: String = "abc"
}

// Anonymous pattern binding
let _ = "abc"

// Do-catch statements

// - Empty
do {
	"abc"
}
catch {
	// Do nothing
}

// - With variable
do {
	"abc"
}
catch let myError {
	// Do nothing
}

// With `try` and `throw`
func throwingFunction() throws { }

struct MyError: Error {
	let errorMessage: String
}

do {
	try throwingFunction()
}
catch {
	throw MyError(errorMessage: "")
}

