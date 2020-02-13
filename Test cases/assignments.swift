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

// output: Test cases/Bootstrap Outputs/assignments.swiftAST
// output: Test cases/Bootstrap Outputs/assignments.gryphonASTRaw
// output: Test cases/Bootstrap Outputs/assignments.gryphonAST
// output: Test cases/Bootstrap Outputs/assignments.kt

var x: Int = 0
var y = x
var z = 10
z = x

print("\(x)")
print("\(y)")
print("\(z)")

//
let a: Int? = nil

print("\(a)")

//
let i: Int
i = 0

let r, g, b: Double
r = 10
g = 10
b = 10

let red = 1, green = 2, blue = 3

let v = 0, w: Double
let v2: Double, w2 = 0
