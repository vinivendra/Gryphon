fun main(args: Array<String>) {
	val x: String = "Hello, world!"
	val y: String = "The string above is ${x}"
	val z: Int = 0
	val w: String = "Here's another interpolated string: ${x}, ${y} and ${z}"
	val escapedString: String = "A string with \"escaped double quotes\" \\ and escaped backslashes \n\t and some escaped characters too."
	val singleInterpolation: String = "${x}"
	val interpolationWithDoubleQuotes: String = "\"\"${x}"
}
