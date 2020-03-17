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

// gryphon output: Test cases/Bootstrap Outputs/generics.swiftAST
// gryphon output: Test cases/Bootstrap Outputs/generics.gryphonASTRaw
// gryphon output: Test cases/Bootstrap Outputs/generics.gryphonAST
// gryphon output: Test cases/Bootstrap Outputs/generics.kt

struct Box<T> { // gryphon ignore
	let x: T
}

// gryphon insert: internal data class Box<T>(
// gryphon insert: 	val x: T
// gryphon insert: ) {
// gryphon insert: }

//// Instancing generic classes
let box = Box(x: 0)

//// Declaring generic functions
func f1<T>(box: Box<T>) {
	print(box.x)
}

// With generic return types
func f2<T>(box: Box<T>) -> T {
	return box.x
}

// In extensions
extension Box {
	func f3<U>(box: Box<U>) {
		print(self.x)
		print(box.x)
	}
}

//// Calling generic functions
f1(box: Box(x: 1))
print(f2(box: Box(x: 2)))
Box(x: 3).f3(box: Box(x: 4))
