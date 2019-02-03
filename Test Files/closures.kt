internal fun useClosure(closure: (String) -> Unit) {
	closure("Calling from function!")
}

fun main(args: Array<String>) {
	val printClosure: (String) -> Unit = { println(it) }
	printClosure("Hello, world!")
	val plusClosure: (Int, Int) -> Int = { a: Int, b: Int -> a + b }
	println(plusClosure(2, 3))
	useClosure(printClosure)
}
