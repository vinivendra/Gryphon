fun <T> MutableList<T>.copy(): MutableList<T> {
	return this.toMutableList()
}
fun <T, R> T?.map(transform: (T) -> R): R? {
	if (this != null) {
		return transform(this)
	}
	else {
		return null
	}
}
