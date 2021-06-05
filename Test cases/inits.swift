//
// Copyright 2018 Vinicius Jorge Vendramini
//
// Licensed under the Hippocratic License, Version 2.1;
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
// https://firstdonoharm.dev/version/2/1/license
//
// To the full extent allowed by law, this software comes "AS IS,"
// WITHOUT ANY WARRANTY, EXPRESS OR IMPLIED, and licensor and any other
// contributor shall not be liable to anyone for any damages or other
// liability arising from, out of, or in connection with the sotfware
// or this license, under any kind of legal claim.
// See the License for the specific language governing permissions and
// limitations under the License.
//

// gryphon output: Test cases/Bootstrap Outputs/inits.swiftAST
// gryphon output: Test cases/Bootstrap Outputs/inits.gryphonASTRaw
// gryphon output: Test cases/Bootstrap Outputs/inits.gryphonAST
// gryphon output: Test cases/Bootstrap Outputs/inits.kt

class A {
	var x: Int
	var y: Int
	var z: Int = 30

	init() {
		x = 0
		y = 1
	}

	init(uniform: Int) {
		x = uniform
		y = uniform
	}

	init(a: Int, b: Int) {
		x = a
		y = b
	}

	init(f: String) {
		x = 2
		y = 3
	}

	init(g: Int, h: Int, i: Int) {
		x = g
		y = h
		z = i
	}

	init(with a: Bool) {
		x = 10
		y = 10
	}
}

var a = A()
print("\(a.x) \(a.y) \(a.z)")
a = A(uniform: 10)
print("\(a.x) \(a.y) \(a.z)")
a = A(a: 11, b: 12)
print("\(a.x) \(a.y) \(a.z)")
a = A(f: "Hello!")
print("\(a.x) \(a.y) \(a.z)")
a = A(g: 14, h: 15, i: 16)
print("\(a.x) \(a.y) \(a.z)")
a = A(with: true)
print("\(a.x) \(a.y) \(a.z)")
