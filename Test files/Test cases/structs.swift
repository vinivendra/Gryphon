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

// gryphon output: Test files/Test cases/Bootstrap Outputs/structs.swiftAST
// gryphon output: Test files/Test cases/Bootstrap Outputs/structs.gryphonASTRaw
// gryphon output: Test files/Test cases/Bootstrap Outputs/structs.gryphonAST
// gryphon output: Test files/Test cases/Bootstrap Outputs/structs.kt

struct SupportedStruct {
	let x = 0
	let y = 1
}

struct OtherSupportedStruct {
	let x: Int
	let y: Int
}

struct NoInheritance: Equatable, Codable {
	let x: Int
	let y: Int
}

struct SingleExpressionMembers {
	let oneParameter: Int = 0

	var one: Int {
		10
	}

	var two: Int {
		get {
			20
		}
	}
}

let a = SupportedStruct()
let b = OtherSupportedStruct(x: 10, y: 20)
let c = SingleExpressionMembers()

print(a.x)
print(a.y)
print(b.x)
print(b.y)
print(c.oneParameter)
print(c.one)
print(c.two)
