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
}
