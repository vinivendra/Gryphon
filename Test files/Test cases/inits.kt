//
// Copyright 2018 Vinicius Jorge Vendramini
//
// Licensed under the Hippocratic License, Version 2.1;
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
// https://firstdonoharm.dev/version/2/1/license
//
// To the full extent allowed by law, this software comes "AS IS,"
// WITHOUT ANY WARRANTY, EXPRESS OR IMPLIED, and licensor and any other
// contributor shall not be liable to anyone for any damages or other
// liability arising from, out of, or in connection with the sotfware
// or this license, under any kind of legal claim.
// See the License for the specific language governing permissions and
// limitations under the License.
//
internal open class A {
	open var x: Int
	open var y: Int
	open var z: Int = 30

	constructor() {
		x = 0
		y = 1
	}

	constructor(uniform: Int) {
		x = uniform
		y = uniform
	}

	constructor(a: Int, b: Int) {
		x = a
		y = b
	}

	constructor(f: String) {
		x = 2
		y = 3
	}

	constructor(g: Int, h: Int, i: Int) {
		x = g
		y = h
		z = i
	}

	constructor(a: Boolean) {
		x = 10
		y = 10
	}
}

fun main(args: Array<String>) {
	var a: A = A()

	println("${a.x} ${a.y} ${a.z}")

	a = A(uniform = 10)

	println("${a.x} ${a.y} ${a.z}")

	a = A(a = 11, b = 12)

	println("${a.x} ${a.y} ${a.z}")

	a = A(f = "Hello!")

	println("${a.x} ${a.y} ${a.z}")

	a = A(g = 14, h = 15, i = 16)

	println("${a.x} ${a.y} ${a.z}")

	a = A(a = true)

	println("${a.x} ${a.y} ${a.z}")
}
