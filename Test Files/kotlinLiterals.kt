import java.util.*

fun myFunction(): String {
	return "Calling myFunction()" // \n \t \
}

interface A {
	val x: Int
}

class B: A {
	override var x: Int = 1
	var y: Int = 2
}

fun main(args: Array<String>) {
	val languageName: String = "kotlin"

	println("Hello from ${languageName}!")

	val magicNumber: Int = 40 + 5-3

	println(magicNumber)

	println("This will be ignored by swift, but not by kotlin.")

	myFunction()

	val squareRoot: Double = Math.sqrt(9.0)

	println(squareRoot)
	println(B().x)
	println(B().y)
}
