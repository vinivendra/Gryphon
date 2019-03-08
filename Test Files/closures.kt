internal fun useClosure(closure: (String) -> Unit) {
	closure("Calling from function!")
}

internal fun defaultClosure(closure: (String) -> Unit = { println(it) }) {
	closure("Calling from default closure!")
}

fun main(args: Array<String>) {
	val printClosure: (String) -> Unit = { println(it) }

	printClosure("Hello, world!")

	val plusClosure: (Int, Int) -> Int = { a, b -> a + b }

	println(plusClosure(2, 3))

	useClosure(printClosure)
	defaultClosure()

	val multiLineClosure: (Int) -> Unit = { a ->
			if (a == 10) {
				println("It's ten!")
			}
			else {
				println("It's not ten.")
			}
		}

	multiLineClosure(10)
	multiLineClosure(20)
}
