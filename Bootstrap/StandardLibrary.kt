fun <T> MutableList<T>.copy(): MutableList<T> {
	return this.toMutableList()
}

fun String.suffix(startIndex: Int): String {
	return this.substring(startIndex, this.length)
}

fun <T> MutableList<T>.removeLast() {
	this.removeAt(this.size - 1)
}
