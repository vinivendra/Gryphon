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

// gryphon output: Test cases/Bootstrap Outputs/enums.swiftAST
// gryphon output: Test cases/Bootstrap Outputs/enums.gryphonASTRaw
// gryphon output: Test cases/Bootstrap Outputs/enums.gryphonAST
// gryphon output: Test cases/Bootstrap Outputs/enums.kt

enum CalculatorError: Error {
	case invalidCharacter
	case multipleCharacters
	case nilInput
}

enum OtherError: Error {
	case oneInt(int: Int)
	case twoInts(int: Int, int2: Int)
	case intAndString(int: Int, string: String)
}

enum NoInheritances: String, Equatable, Codable {
	case fooBar = "foo-bar"
	case barBaz
}

enum WithMembers {
	case fooBar
	case baz

	func a() { }
	func b() { }
}

func throwingFunc() throws {
	throw CalculatorError.invalidCharacter
}

func otherThrowingFunc() throws {
	try throwingFunc()
}

// Test enum capitalization
public enum MyEnum {
	case fooBar
	case baz
}

let a = MyEnum.fooBar // gryphon ignore
let b = MyEnum.baz // gryphon ignore
// gryphon insert: val a = MyEnum.FOO_BAR
// gryphon insert: val b = MyEnum.BAZ

if a == MyEnum.fooBar {
	print("MyEnum.FOO_BAR")
}
if b == MyEnum.baz {
	print("MyEnum.BAZ")
}
