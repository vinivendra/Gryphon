open class A {
	var x: Int
	var y: Int
	var z: Int = 30

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
}
