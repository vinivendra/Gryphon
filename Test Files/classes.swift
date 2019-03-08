/*
* Copyright 2018 Vinícius Jorge Vendramini
*
* Licensed under the Apache License, Version 2.0 (the "License");
* you may not use this file except in compliance with the License.
* You may obtain a copy of the License at
*
* http://www.apache.org/licenses/LICENSE-2.0
*
* Unless required by applicable law or agreed to in writing, software
* distributed under the License is distributed on an "AS IS" BASIS,
* WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
* See the License for the specific language governing permissions and
* limitations under the License.
*/

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
