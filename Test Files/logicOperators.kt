fun main(args: Array<String>) {
	val t: Boolean = true
	val f: Boolean = false
	var x: Boolean = t || f
	var y: Boolean = t && f
	println("${(x)}")
	println("${(y)}")
	x = f || f
	y = f && f
	println("${(x)}")
	println("${(y)}")
	println("${(t || t)}")
	println("${(t && t)}")
	println("${(true || false)}")
	println("${(true && false)}")
	x = true || false
	println("${(x)}")
	var z: Boolean = !x
	println("${(z)}")
	z = !y
	println("${(z)}")
	if (x) {
		println("true")
	}
	if (!x) {
		println("false")
	}
	if (t && (!f) || f) {
		println("true")
	}
}
