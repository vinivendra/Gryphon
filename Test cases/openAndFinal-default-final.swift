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

// gryphon output: Test cases/Bootstrap Outputs/openAndFinal-default-final.swiftAST
// gryphon output: Test cases/Bootstrap Outputs/openAndFinal-default-final.gryphonASTRaw
// gryphon output: Test cases/Bootstrap Outputs/openAndFinal-default-final.gryphonAST
// gryphon output: Test cases/Bootstrap Outputs/openAndFinal-default-final.kt

// Test variables and methods
class A {
	// Open by default, final if compiled with -default-final
	var a1 = 0
	func b1() { }

	// Overriding with annotations
	var a2 = 0 // gryphon annotation: open
	func b2() { } // gryphon annotation: open

	var a3 = 0 // gryphon annotation: final
	func b3() { } // gryphon annotation: final

	// Swift annotations
	open var a4 = 0
	open func b4() { }

	final var a5 = 0
	final func b5() { }

	// Private declarations can't be open
	private var a6 = 0
	private func b6() { }

	// Static declarations can't be open
	static var a7 = 0
	static func b7() { }

	// Let declarations can't be open
	let a8 = 0
}

// Test classes

// Open by default, final if compiled with -default-final
class A1 { }

// Overriding with annotations
class A2 { } // gryphon annotation: open
class A3 { } // gryphon annotation: final

// Private declarations can't be open
private class A4 { }

// Test value types
struct B {
	// Declarations for value types are static by default
	let a1 = 0
	func b1() { }

	// Override with annotations
	let a2 = 0 // gryphon annotation: open
	func b2() { } // gryphon annotation: open

	// Test static declarations
	static var a3 = 0
	static func b3() { }
}

enum C {
	// Declarations for value types are static by default
	func b1() { }

	// Override with annotations
	func b2() { } // gryphon annotation: open

	// Test static declarations
	static var a3 = 0
	static func b3() { }
}

// Test top-level declarations
func b1() { }

// Test local variables
var a1 = 0
