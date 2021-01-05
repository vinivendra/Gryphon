//
// Copyright 2018 Vinicius Jorge Vendramini
//
// Licensed under the Hippocratic License, Version 2.1;
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
// https://firstdonoharm.dev/version/2/1/license.md
//
// To the full extent allowed by law, this software comes "AS IS,"
// WITHOUT ANY WARRANTY, EXPRESS OR IMPLIED, and licensor and any other
// contributor shall not be liable to anyone for any damages or other
// liability arising from, out of, or in connection with the sotfware
// or this license, under any kind of legal claim.
// See the License for the specific language governing permissions and
// limitations under the License.
//

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

// Number formats (float literals)
var m: Double = 1.21875e1
var n: Float = 1.21875e1
m = 000123.456
n = 000123.456
m = 1_000_000.000_000_1
n = 1_000_000.000_000_1

// Number formats (integer literals)
var o: Int = 1_000_000
var p: UInt = 1_000_000
m = 1_000_000
n = 1_000_000

var q: Int = 0x101
q = 0b101
var r: UInt = 0x101
r = 0b101

// Literal floats as autoclosures
public func foo1(_ bar: Double?) -> Double {
	return bar ?? 0.0
}

public func foo2(_ bar: Float?) -> Float {
	return bar ?? 0.0
}
