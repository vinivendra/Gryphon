fun main(args: Array<String>) {
	val dictionary1: MutableMap<String, Int> = mutableMapOf("a" to 1, "b" to 2, "c" to 3)
	val dictionary2: MutableMap<Int, Int> = mutableMapOf()

	println(dictionary1["a"])
	println(dictionary1["b"])
	println(dictionary1["c"])
	println(dictionary1["d"])
	println(dictionary2[0])
}
