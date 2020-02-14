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

// gryphon output: Test cases/Bootstrap Outputs/misc.swiftAST
// gryphon output: Test cases/Bootstrap Outputs/misc.gryphonASTRaw
// gryphon output: Test cases/Bootstrap Outputs/misc.gryphonAST
// gryphon output: Test cases/Bootstrap Outputs/misc.kt

// Typealias
typealias A = Int

// Typealias with inner types
class B {
	class C {

	}
}

typealias BC = B.C

// Typealias with generics
class List<T> { } // gryphon ignore

typealias ListInt = List<Int>

//
var a: A = 0
var bc: BC

// `a ?: return`
func f(a: Int?) {
	if a == nil {
		return
	}
	print(a)
}

f(a: 10)
print("==")
f(a: nil)
print("==")
