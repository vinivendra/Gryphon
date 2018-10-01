val String.isString: Boolean
	get() {
		return true
	}
val String.world: String
	get() {
		return "World!"
	}

fun main(args: Array<String>) {
	println("${"Hello!".isString}")
	println("${"Hello!".world}")
}
