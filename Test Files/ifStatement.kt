internal fun trueFunction(): Boolean {
	return true
}

fun main(args: Array<String>) {
	if (true) {
		println("Hi!")
	}
	if (false) {
		println("Bye!")
	}
	if (trueFunction()) {
		println("Hi again!")
	}
	if (trueFunction()) {
		println("Hello!")
	}
	else if (trueFunction()) {
		println("Oops, almost!")
	}
	else if (trueFunction()) {
		println("Not quite...")
	}
	else {
		println("Bye!")
	}
}
