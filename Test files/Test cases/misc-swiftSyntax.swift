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

// While and continue
var i = 1
while i <= 10 {
	if i == 5 {
		i += 1
		continue
	}
	print(i)
	i += 1
}

// While with multiple conditions
while true, false { }

// Typealias
typealias A = Int

// Typealias with inner types
class B {
	class C {

	}
}

typealias BC = B.C

// Typealias with generics
// gryphon ignore
class List<T> { }

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

// Test Array<Whatever>
let arrayOfInts: Array<Int> = [1, 2, 3]

// Test Array<Whatever>.Index
let array = [1, 2, 3]
let arrayIndex = array.firstIndex(of: 1)

// Test Array<Whatever>.ArrayLiteralElement
let bla: Array<Int>.ArrayLiteralElement = 1

// Test Array literals
// (SourceKit says some literals are `() -> Array`, not `Array`)
// gryphon ignore
public class MutableList<Element>: ExpressibleByArrayLiteral {
	public required init(arrayLiteral elements: Element...) { }
}

let array2: MutableList<Int> = []
let array3: MutableList<Int> = array2 ?? []

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

// No `toString` for classes without `CustomStringConvertible`
class H {
	var description: String = "abc"
}

// No mistaking the `K` in `I.K` with the `K` in `J.K`
class I {
	class K: CustomStringConvertible {
		var description = ""
	}
}

class J {
	class K {
		var description = ""
	}
}

let ik = I.K().description
let jk = J.K().description

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

// #if's
#if GRYPHON
func gryphon1() { }
#else
func notGryphon1() { }
#endif

#if !GRYPHON
func notGryphon2() { }
#else
func gryphon2() { }
#endif

#if GRYPHON
#else
#endif

#if !GRYPHON
#else
#endif

// Defer
func g() {
	defer {
		print("Second")
	}
	print("First")
}

g()

// Equatable
struct G: Equatable {
	let x = 0

	static func ==(lhs: G, rhs: G) -> Bool {
		// User code
		return lhs.x > 0
	}
}

// Test tuples (declaration and member reference)
let x = (0, 0)
print("\(x.0), \(x.1)")

let y: (a: Int, b: Int) = (a: 0, b: 0)
print("\(y.a), \(y.b)")

let z: ((Int, Int), Int) = ((0, 0), 0)
print(z.0.0)

let dictionary = [1: 10, 2: 20]
let mappedDictionary = dictionary.map { $0.0 + $0.1 }
