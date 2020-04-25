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

// gryphon output: Test cases/Bootstrap Outputs/switches.swiftAST
// gryphon output: Test cases/Bootstrap Outputs/switches.gryphonASTRaw
// gryphon output: Test cases/Bootstrap Outputs/switches.gryphonAST
// gryphon output: Test cases/Bootstrap Outputs/switches.kt

func printNumberName(_ x: Int) {
	switch x {
	case 0:
		print("Zero")
	case 1:
		print("One")
	case 2:
		print("Two")
	case 3:
		print("Three")
	case 4...5:
		print("Four or five")
	case 6..<10:
		print("Less than ten")
	default:
		print("Dunno!")
	}
}

printNumberName(0)
printNumberName(1)
printNumberName(2)
printNumberName(3)
printNumberName(4)
printNumberName(7)
printNumberName(10)

// Return switch
func getNumberName(_ x: Int) -> String {
	switch x {
	case 0:
		return "Zero"
	case 1:
		return "One"
	case 2:
		return "Two"
	case 3:
		return "Three"
	default:
		return "Dunno!"
	}
}

print(getNumberName(0))
print(getNumberName(1))
print(getNumberName(2))
print(getNumberName(3))
print(getNumberName(4))


// Variable declaration switch
var y = 0
var x: Int
switch y {
case 0:
	x = 10
default:
	x = 20
}

print(x)

// Assignment switch
switch y {
case 0:
	x = 100
default:
	x = 200
}

print(x)

// Switch on an enum class
enum MyEnum {
	case a, b, c, d, e
}

let myEnum = MyEnum.a
switch myEnum {
case .a:
	print("It's a!")
default:
	print("It's not a.")
}

// Switch on a sealed class

enum MySealedClass {
	case a(int: Int)
}

let mySealedClass = MySealedClass.a(int: 0)
switch mySealedClass {
case let .a(int: int):
	print(int)
}

// Regression test: switch expressions as the last statement in a block
func f() {
	let number = 0

	let name: String
	switch number {
	case 0:
		name = "Zero"
	default:
		name = "More"
	}
}
