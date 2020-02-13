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

// output: Test cases/Bootstrap Outputs/logicOperators.swiftAST
// output: Test cases/Bootstrap Outputs/logicOperators.gryphonASTRaw
// output: Test cases/Bootstrap Outputs/logicOperators.gryphonAST
// output: Test cases/Bootstrap Outputs/logicOperators.kt

let t = true
let f = false

//
var x = t || f
var y = t && f
print("\(x)")
print("\(y)")

//
x = f || f
y = f && f
print("\(x)")
print("\(y)")

//
print("\(t || t)")
print("\(t && t)")

//
print("\(true || false)")
print("\(true && false)")

//
x = true || false
print("\(x)")

//
var z = !x
print("\(z)")

z = !y
print("\(z)")

//
if x {
	print("true") // Will get printed
}

if !x {
	print("false") // Won't get printed
}

if t && (!f) || f {
	print("true") // Will get printed
}
