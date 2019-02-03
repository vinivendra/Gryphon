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

class A {
	var x: Int
	var y: Int
	var z: Int = 30

	init() {
		x = 0
		y = 1
	}

	init(uniform: Int) {
		x = uniform
		y = uniform
	}

	init(a: Int, b: Int) {
		x = a
		y = b
	}

	init(f: String) {
		x = 2
		y = 3
	}

	init(g: Int, h: Int, i: Int) {
		x = g
		y = h
		z = i
	}
}

var a = A()
print("\(a.x) \(a.y) \(a.z)")
a = A(uniform: 10)
print("\(a.x) \(a.y) \(a.z)")
a = A(a: 11, b: 12)
print("\(a.x) \(a.y) \(a.z)")
a = A(f: "Hello!")
print("\(a.x) \(a.y) \(a.z)")
a = A(g: 14, h: 15, i: 16)
print("\(a.x) \(a.y) \(a.z)")
