//
// Copyright 2018 Vinicius Jorge Vendramini
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

// gryphon output: Test cases/Bootstrap Outputs/warnings.swiftAST
// gryphon output: Test cases/Bootstrap Outputs/warnings.gryphonASTRaw
// gryphon output: Test cases/Bootstrap Outputs/warnings.gryphonAST
// gryphon output: Test cases/Bootstrap Outputs/warnings.kt

// Test warnings for mutable value types
struct UnsupportedStruct {
	let immutableVariable = 0
	var mutableVariable = 0

	func pureFunction() { }
	mutating func mutatingFunction() { }

	var computedVarIsOK: Int {
		return 0
	}
}

enum UnsupportedEnum {
	case a(int: Int)

	mutating func mutatingFunction() { }

	var computedVarIsOK: Int {
		return 0
	}
}

// Test warnings for native declarations
let nativeArray: [Int] = []
let nativeDictionary: [Int: Int] = [:]

// Test warnings for nested fileprivate members
class MyClass {
	fileprivate var filePrivateVariable: Int = 0
}

// Test warnings for pure function
func f() -> Bool? { return true }
func g() -> Bool? { return true } // gryphon pure

if let a1 = f(), let a2 = g() { }
if let a4 = g(), let a3 = f() { }
if true, let a5 = g() { }
if true, let a6 = f() { }

// Test warnings for double optionals
let maybeInt: Int?? = 0
let whatever = maybeInt

// Test warnings for multiple super calls
class A {
	var x = 0

	init(x: Int) {
		self.x = x
	}
}

class B: A {
	init(y: Int) {
		if y == 10 {
			super.init(x: y)
		}
		else {
			super.init(x: 0)
		}
	}
}

// Test muting warnings
let noWarnings: [Int] = [] // gryphon mute
