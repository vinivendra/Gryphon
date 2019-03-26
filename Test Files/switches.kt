internal fun printNumberName(x: Int) {
	when (x) {
		0 -> println("Zero")
		1 -> println("One")
		2 -> println("Two")
		3 -> println("Three")
		in 4..5 -> println("Four or five")
		in 6 until 10 -> println("Less than ten")
		else -> println("Dunno!")
	}
}

internal fun getNumberName(x: Int): String {
	return when (x) {
		0 -> "Zero"
		1 -> "One"
		2 -> "Two"
		3 -> "Three"
		else -> "Dunno!"
	}
}

internal enum class MyEnum {
	A,
	B,
	C,
	D,
	E;
}

fun main(args: Array<String>) {
	printNumberName(0)
	printNumberName(1)
	printNumberName(2)
	printNumberName(3)
	printNumberName(4)
	printNumberName(7)
	printNumberName(10)

	println(getNumberName(0))
	println(getNumberName(1))
	println(getNumberName(2))
	println(getNumberName(3))
	println(getNumberName(4))

	var y: Int = 0

	var x: Int = when (y) {
		0 -> 10
		else -> 20
	}

	println(x)

	x = when (y) {
		0 -> 100
		else -> 200
	}

	println(x)

	val myEnum: MyEnum = MyEnum.A

	when (myEnum) {
		MyEnum.A -> println("It's a!")
		else -> println("It's not a.")
	}
}
