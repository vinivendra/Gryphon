typealias A = Int

class B {
	class C {
	}
}

typealias BC = B.C
typealias ListInt = List<Int>

internal fun f(a: Int?) {
	a ?: return
	println(a)
}

fun main(args: Array<String>) {
	var a: A = 0
	var bc: BC

	f(a = 10)

	println("==")

	f(a = null)

	println("==")
}
