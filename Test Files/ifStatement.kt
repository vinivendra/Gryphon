internal fun trueFunction(): Boolean {
	return true
}

fun main(args: Array<String>) {
	if (true) {
		println("Hi!")
	}
	if (trueFunction()) {
		println("Hi again!")
	}
	if (false) {
		println("Bye!")
	}
}
