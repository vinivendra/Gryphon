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

// String Literal
struct UnsupportedStruct {
	let immutableVariable = 0
	var mutableVariable = 0

	func pureFunction() { }
	mutating func mutatingFunction() { }
}

struct SupportedStruct {
	let x = 0
	let y = 1
}

struct OtherSupportedStruct {
	let x: Int
	let y: Int
}

let a = SupportedStruct()
let b = OtherSupportedStruct(x: 10, y: 20)

print(a.x)
print(a.y)
print(b.x)
print(b.y)
