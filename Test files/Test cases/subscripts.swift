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

// Normal subscripts
class A {
	var x = 0

	subscript(i: Int) -> Int {
		get {
			return x + i
		}
		set {
			self.x = newValue + 1
		}
	}
}

let a = A()
a[1] = 10
print(a[1])

// Implicit getters
class B {
	subscript(i: Int) -> Int {
		return i
	}
}

let b = B()
print(b[1])

print(0) // For compatiblity with the swiftSyntax test

// Multiple indices
class D {
	subscript(a: Int, b: Int) -> Int {
		get {
			return a + b
		}
		set {
			print("\(a) \(b) \(newValue)")
		}
	}
}

let d = D()
print(d[0, 1])
d[0, 1] = 2

// For compatiblity with the swiftSyntax test
print(1)
print("0 1 2")

// Optional subscripts
let a1: A? = A()
print(a1?[1])

let b1: B? = B()
print(b1?[1])

print(0) // For compatiblity with the swiftSyntax test

let d1: D? = D()
print(d1?[0, 1])

print(1) // For compatiblity with the swiftSyntax test
