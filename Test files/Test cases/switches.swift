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
	case b
}

let mySealedClass = MySealedClass.a(int: 0)
switch mySealedClass {
case let .a(int: int):
	print(int)
case .b:
	print("b")
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

// break
let z: Int = 0
switch z {
case 0:
	break
	print(0)
case 1:
	print(1)
	break
default:
	print(2)
}
