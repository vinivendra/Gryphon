internal fun trueFunction(): Boolean {
	return true
}
internal fun testGuards() {
	val x: Int = 0
	if (x != 0) {
		println("--")
		return
	}
	if (x == 1) {
		println("--")
		return
	}
	println("Guard")
}
internal fun bla(): Int? {
	return 0
}

fun main(args: Array<String>) {
	if (true) {
		println("Simple if's")
	}
	if (false) {
		println("--")
	}
	if (trueFunction()) {
		println("If with a function")
	}
	if (true) {
		println("Simple, with empty else if and else")
	}
	else {
	}
	if (true) {
		println("Simple, with empty else if and else #2")
	}
	else if (true) {
	}
	else {
	}
	if (true) {
		println("Simple, with empty else if and else #3")
	}
	else if (true) {
	}
	else if (true) {
	}
	else {
	}
	if (trueFunction()) {
		println("Else if and else with contents")
	}
	else if (trueFunction()) {
		println("--")
	}
	else {
		println("--")
	}
	if (trueFunction()) {
		println("Else if and else with contents #2")
	}
	else if (trueFunction()) {
		println("--")
	}
	else if (trueFunction()) {
		println("--")
	}
	else {
		println("--")
	}
	if (false) {
		println("--")
	}
	else if (true) {
		println("Else if and else with contents that get executed")
	}
	else {
		println("--")
	}
	if (false) {
		println("--")
	}
	else if (false) {
		println("--")
	}
	else {
		println("Else if and else with contents that get executed #2")
	}
	testGuards()
	val x: Int? = 0
	val y: Int? = 0
	val z: Int? = null
	val a: Int? = x
	if (a != null) {
		println("${a}")
		println("If let")
	}
	val b: Int? = x
	if (b != null) {
		println("${b}")
		println("If let #2")
	}
	else if (x == 0) {
		println("--")
	}
	else {
		println("--")
	}
	val c: Int? = z
	if (c != null) {
		println("--")
	}
	else {
		println("${z}")
		println("If let #3")
	}
	var d: Int? = x
	val e: Int? = y
	val f: Int? = bla()
	if (d != null && e != null && f != null && x == 0) {
		println("${d}, ${e}, ${f}, ${x!!}")
		println("If let #4")
	}
	else if (x == 1) {
		println("--")
	}
	else {
		println("--")
	}
}
