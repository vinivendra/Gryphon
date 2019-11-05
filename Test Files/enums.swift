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

// gryphon output: Test Files/Bootstrap Outputs/enums.swiftAST
// gryphon output: Test Files/Bootstrap Outputs/enums.gryphonASTRaw
// gryphon output: Test Files/Bootstrap Outputs/enums.gryphonAST
// gryphon output: Test Files/Bootstrap Outputs/enums.kt

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
