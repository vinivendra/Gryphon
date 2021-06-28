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

enum EmptyEnum {
}

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

// gryphon ignore
let a = MyEnum.fooBar
// gryphon ignore
let b = MyEnum.baz
// gryphon insertInMain: val a = MyEnum.FOO_BAR
// gryphon insertInMain: val b = MyEnum.BAZ

if a == MyEnum.fooBar {
	print("MyEnum.FOO_BAR")
}
if b == MyEnum.baz {
	print("MyEnum.BAZ")
}

// Capitalization for nested enums
public class K {
	public enum A {
		case b(int: Int)

		func foo() -> Int {
			switch self {
			case let .b(int: int):
				return 0
			}
		}
	}
}

let c = K.A.b(int: 0)

// Test default rawValues
enum E1: Int {
	case a
	case b
}

enum E2: String {
	case a
	case aB
}

print(E1.b.rawValue)
print(E2.aB.rawValue)

// Test manual rawValues
enum E3: Int {
	case a = 10
	case b = 100
	case c
}

enum E4: String {
	case a = "aaA"
	case aB = "B_A"
	case c
}

print(E3.a.rawValue)
print(E3.c.rawValue)
print(E4.a.rawValue)
print(E4.c.rawValue)
