fun main(args: Array<String>) {
	val array1: MutableList<Int> = mutableListOf(1, 2, 3)
	val array2: MutableList<Int> = array1

	array1[0] = 10

	println(array1)
	println(array2)
	println(array2[0])

	for (i in array1) {
		println(i)
	}

	for (j in array2) {
		println(j)
	}

	for (i in array1) {
		for (j in array2) {
			println("${i}, ${j}")
		}
	}
}
