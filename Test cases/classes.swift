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

	init(x: Int) { // gryphon ignore
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
