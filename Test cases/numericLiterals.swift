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

// gryphon output: Test cases/Bootstrap Outputs/numericLiterals.swiftAST
// gryphon output: Test cases/Bootstrap Outputs/numericLiterals.gryphonASTRaw
// gryphon output: Test cases/Bootstrap Outputs/numericLiterals.gryphonAST
// gryphon output: Test cases/Bootstrap Outputs/numericLiterals.kt

func foo(int: Int, double: Double, float: Float) {
	print(int)
	print(double)
	print(float)
}

let int1 = 0
let int2 = 3
let int3 = int1 + int2

let double1: Double = 0
let double2: Double = 3
let double3 = double1 + double2

print(int1)
print(int2)
print(int3)
print(double1)
print(double2)
print(double3)

foo(int: 5, double: 5, float: 5)

// Translate types and limits
var a: UInt8 = 255
var b: UInt16 = 65535
var c: UInt32 = 4294967295
var d: UInt64 = 18446744073709551615

var e: Int8 = 127
var f: Int16 = 32767
var g: Int32 = 2147483647
var h: Int64 = 9223372036854775807
e = -128
f = -32768
g = -2147483648
h = -9223372036854775807

var i: Float = 0
var j: Float32 = 0

var k: Float64 = 0
var l: Double = 0

// Number formats
var m: Double = 1.21875e1
m = 000123.456
m = 1_000_000.000_000_1

var n: Int = 1_000_000
