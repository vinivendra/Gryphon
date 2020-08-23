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

// gryphon output: Test cases/Bootstrap Outputs/generics.swiftAST
// gryphon output: Test cases/Bootstrap Outputs/generics.gryphonASTRaw
// gryphon output: Test cases/Bootstrap Outputs/generics.gryphonAST
// gryphon output: Test cases/Bootstrap Outputs/generics.kt

struct Box<T> {
	let x: T
}

//// Instancing generic classes
let box = Box(x: 0)

//// Declaring generic functions
func f1<T>(box: Box<T>) {
	print(box.x)
}

// With generic return types
func f2<T>(box: Box<T>) -> T {
	return box.x
}

// In extensions
// gryphon generics: T
extension Box {
	func f3() { }

	func f4<U>(box: Box<U>) {
		print(self.x)
		print(box.x)
	}

	var a: Int {
		return 0
	}
}

//// Calling generic functions
f1(box: Box(x: 1))
print(f2(box: Box(x: 2)))
Box(x: 3).f4(box: Box(x: 4))

//// Test generics with implicit constraints
// This is implicitly "Key where Key: Hashable"
func f<Key>() -> [Key: String] {
	return [:]
}
