class A {
	companion object {
		internal fun a(): A {
			return A()
		}
		internal fun c(): A? {
			return A()
		}
		internal fun d(): A? {
			return null
		}
		internal fun f(): Int {
			return 1
		}
	}
	var x: Int = 0
	internal fun b(): A {
		return A()
	}
	internal fun e(): Int {
		println("Hello, world!")
		return 1
	}
}

fun main(args: Array<String>) {
	println(A.a().x)
	println(A().b().x)
	var a: A? = A.c()
	val ac: A? = a
	if (ac != null) {
		println(ac.x)
	}
	a = A.d()
	val ad: A? = a
	if (ad != null) {
		println(ad.x)
	}
	println(A().e())
	println(A.f())
}
