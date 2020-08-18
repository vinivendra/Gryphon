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

// gryphon output: Test cases/Bootstrap Outputs/classes.swiftAST
// gryphon output: Test cases/Bootstrap Outputs/classes.gryphonASTRaw
// gryphon output: Test cases/Bootstrap Outputs/classes.gryphonAST
// gryphon output: Test cases/Bootstrap Outputs/classes.kt

class Box {
	var a: Int = 5

	var b: String {
		get {
			return "get b"
		}
		set {
			print("set b")
		}
	}

	var c: Int?

	func returnFive() -> Int {
		return a
	}

	func returnInt(a: Int) -> Int {
		return a
	}
}

let box1 = Box()

print(box1.a)
print(box1.returnFive())
print(box1.returnInt(a: 10))
print(box1.b)
box1.b = "whatever"
print(box1.c)

// Removes inner types: it should be `B()` and not `A.B()`
class A {
	class B {
	}

	let b = B()
}

// Test static methods
class C {
	var x = 0

	static func a() -> C {
		return C()
	}

	func b() -> C {
		return C()
	}

	static func c() -> C? {
		return C()
	}

	static func d() -> C? {
		return nil
	}

	func e() -> Int {
		print("Hello, world!")
		return 1
	}

	static func f() -> Int {
		return 1
	}
}

struct D {
	let x: Int

	// gryphon ignore
	init(x: Int) {
		self.x = x
	}

	init?(string: String?) {
		guard let string = string else {
			return nil
		}

		switch string {
		case "A": self = D(x: 0)
		case "B": self = D(x: 0)
		case "C": self = D(x: 0)
		case "D": self = D(x: 0)
		case "E": self = D(x: 0)
		default: return nil
		}
	}
}

// Test open/final
// gryphon annotation: open
class E {
	var a = 0
}

// gryphon annotation: final
class F {
	var a = 0
}

print(C.a().x)
print(C().b().x)

var a = C.c()
if let ac = a {
	print(ac.x)
}

a = C.d()
if let ad = a {
	print(ad.x)
}

print(C().e())
print(C.f())

print(D(x: 10))
print(D(string: "not supported"))
print(D(string: "A")!)

// Test subscripts
class MyClass {
	var x = 0

	subscript(i: Int) -> Int {
		get {
			return x + i
		}
		set {
			self.x = newValue + 1
		}
	}
}

let myClass = MyClass()

print(myClass[1])
print(myClass[2])
print(myClass[3])

myClass[1] = 10

print(myClass[1])
print(myClass[2])
print(myClass[3])


class SingleExpressionMembers {
	var one: Int {
		10
	}

	var two: Int {
		get {
			20
		}
	}

	var dddddddddddddddddddddddddeeeeeeeeeee: Int {
		aaaaaaaaaaaaa(bbbbbbbbbbbbbbbb: 0, ccccccccccccc : 1, ddddddddddddddddddddddddd: 2, eeeeeeeeeee: 3)
	}

	private func aaaaaaaaaaaaa(bbbbbbbbbbbbbbbb: Int, ccccccccccccc: Int, ddddddddddddddddddddddddd: Int, eeeeeeeeeee: Int) -> Int {
		bbbbbbbbbbbbbbbb * ccccccccccccc * ddddddddddddddddddddddddd * eeeeeeeeeee
	}
}

let singleExpressionMembers = SingleExpressionMembers()
print(singleExpressionMembers.one)
print(singleExpressionMembers.two)
print(singleExpressionMembers.dddddddddddddddddddddddddeeeeeeeeeee)
