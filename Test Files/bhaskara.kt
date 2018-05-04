internal fun bhaskara(a: Double, b: Double, c: Double): Double {
	val delta: Double = b * b - 4.0 * a * c
	val deltaRoot: Double = Math.sqrt(delta)
	val root1: Double = (-b + deltaRoot) / (2.0 * a)
	return root1
}

fun main(args: Array<String>) {
	println(bhaskara(a = 1.0, b = 0.0, c = -9.0))
}
