fun main(args: Array<String>) {
	val dictionaryA: MutableMap<String, Int> = mutableMapOf("a" to 1, "b" to 2, "c" to 3)
	val dictionaryB: MutableMap<Int, Int> = mutableMapOf()

	println(dictionaryA["a"])
	println(dictionaryA["b"])
	println(dictionaryA["c"])
	println(dictionaryA["d"])
	println(dictionaryB[0])

	val dictionary1: MutableMap<String, Int> = mutableMapOf("a" to 1, "b" to 2, "c" to 3)
	val dictionary2: MutableMap<String, Int> = dictionary1

	dictionary1["a"] = 10

	println(dictionary1["a"])
	println(dictionary1["b"])
	println(dictionary1["c"])
	println(dictionary1["d"])
	println(dictionary2["a"])
	println(dictionary2["b"])
	println(dictionary2["c"])
	println(dictionary2["d"])

	val dictionary3: MutableMap<String, Int> = mutableMapOf()

	println(dictionary3["a"])
	println(dictionary3["d"])
}
