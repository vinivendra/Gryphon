internal fun foo(int: Int, double: Double) {
	println(int)
	println(double)
}

fun main(args: Array<String>) {
	val int1: Int = 0
	val int2: Int = 3
	val int3: Int = int1 + int2
	val double1: Double = 0.0
	val double2: Double = 3.0
	val double3: Double = double1 + double2
	println(int1)
	println(int2)
	println(int3)
	println(double1)
	println(double2)
	println(double3)
	foo(int = 5, double = 5.0)
}
