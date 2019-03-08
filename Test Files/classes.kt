class Box {
	var a: Int = 5
	var b: String
		get() {
			return "get b"
		}
		set(newValue) {
			println("set b")
		}
	var c: Int? = null

	internal fun returnFive(): Int {
		return a
	}

	internal fun returnInt(a: Int): Int {
		return a
	}
}

class A {
	class B {
	}

	val b: B = B()
}

fun main(args: Array<String>) {
	val box1: Box = Box()

	println(box1.a)
	println(box1.returnFive())
	println(box1.returnInt(a = 10))
	println(box1.b)

	box1.b = "whatever"

	println(box1.c)
}
