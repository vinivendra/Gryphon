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
internal fun foo(int: Int, double: Double, float: Float) {
	println(int)
	println(double)
	println(float)
}

fun main(args: Array<String>) {
	val int1: Int = 0
	val int2: Int = 3
	val int3: Int = int1 + int2
	val double1: Double = 0.0
	val double2: Double = 3.0
	val double3: Double = double1 + double2

	println(int1)
	println(int2)
	println(int3)
	println(double1)
	println(double2)
	println(double3)
	foo(int = 5, double = 5.0, float = 5.0f)

	var a: UByte = 255u
	var b: UShort = 65535u
	var c: UInt = 4294967295u
	var d: ULong = 18446744073709551615u
	var e: Byte = 127
	var f: Short = 32767
	var g: Int = 2147483647
	var h: Long = 9223372036854775807

	e = -128
	f = -32768
	g = -2147483648
	h = -9223372036854775807

	var i: Float = 0.0f
	var j: Float = 0.0f
	var k: Double = 0.0
	var l: Double = 0.0
	var m: Double = 12.1875

	m = 123.456
	m = 1000000.0000001

	var n: Int = 1000000
}
