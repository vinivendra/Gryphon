import java.util.*

fun myFunction(): String {
	return "Calling myFunction()" // \n \t \
}

internal fun f(a: Int = 0, b: Int = 1) {
	println(a + b)
}

interface A {
	val x: Int
	val y: Int
}

class B: A {
	override var x: Int = 1
	override var y: Int = 3
	var z: Int = 0
}

fun main(args: Array<String>) {
	val languageName: String = "kotlin"

	println("Hello from ${languageName}!")

	val magicNumber: Int = 40 + 5-3

	println(magicNumber)

	f(a = 0, b = 1)

	println("This will be ignored by swift, but not by kotlin.")

	myFunction()

	val squareRoot: Double = Math.sqrt(9.0)

	println(squareRoot)
	println(B().x)
	println(B().y)
}
