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

// gryphon output: Test Files/Bootstrap Outputs/staticMembers.swiftAST
// gryphon output: Test Files/Bootstrap Outputs/staticMembers.gryphonASTRaw
// gryphon output: Test Files/Bootstrap Outputs/staticMembers.gryphonAST
// gryphon output: Test Files/Bootstrap Outputs/staticMembers.kt

class A {
	var x = 0

	static func a() -> A {
		return A()
	}

	func b() -> A {
		return A()
	}

	static func c() -> A? {
		return A()
	}

	static func d() -> A? {
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

struct B {
	let x: Int

	init(x: Int) { // kotlin: ignore
		self.x = x
	}

	init?(string: String?) {
		guard let string = string else {
			return nil
		}

		switch string {
		case "A": self = B(x: 0)
		case "B": self = B(x: 0)
		case "C": self = B(x: 0)
		case "D": self = B(x: 0)
		case "E": self = B(x: 0)
		default: return nil
		}
	}
}

print(A.a().x)
print(A().b().x)

var a = A.c()
if let ac = a {
	print(ac.x)
}

a = A.d()
if let ad = a {
	print(ad.x)
}

print(A().e())
print(A.f())

print(B(x: 10))
print(B(string: "not supported"))
print(B(string: "A")!)
