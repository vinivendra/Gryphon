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
			return 0
		}
	}
	internal fun b(): A {
		return A()
	}
	internal fun e() {
		println("Hello, world!")
	}
}
