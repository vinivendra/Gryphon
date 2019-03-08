val String.isString: Boolean
	get() {
		return true
	}
val String.world: String
	get() {
		return "World!"
	}

internal fun String.appendWorld(): String {
	return this + ", world!"
}

internal fun String.functionWithVariable() {
	var string: String = ", world!!"
	println("Hello${string}")
}

fun main(args: Array<String>) {
	println("${"Hello!".isString}")
	println("${"Hello!".world}")
	println("${"Hello".appendWorld()}")

	"bla".functionWithVariable()
}
