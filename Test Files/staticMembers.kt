open class A {
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

data class B(
	val x: Int
) {
	companion object {
		operator fun invoke(string: String?): B? {
			string ?: return null
			return when (string) {
				"A" -> B(x = 0)
				"B" -> B(x = 0)
				"C" -> B(x = 0)
				"D" -> B(x = 0)
				"E" -> B(x = 0)
				else -> null
			}
		}
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
	println(B(x = 10))
	println(B(string = "not supported"))
	println(B(string = "A")!!)
}
