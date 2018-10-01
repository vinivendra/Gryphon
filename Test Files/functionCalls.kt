internal fun foo() {
}
internal fun foo1(bar: Int) {
}
internal fun foo2(bar: Int) {
}
internal fun foo3(bar: Int, baz: Int) {
}
internal fun foo4(bar: Int, baz: Int) {
}
internal fun foo6(bar: Int, baz: Int) {
}
internal fun bla(): Int {
	return 0
}
internal fun bla1(bar: Int): Int {
	return 1
}
internal fun bla2(bar: Int): Int {
	return 2
}
internal fun bla3(bar: Int, baz: Int): Int {
	return 3
}
internal fun bla4(bar: Int, baz: Int): Int {
	return 4
}
internal fun bla6(bar: Int, baz: Int): Int {
	return 6
}

fun main(args: Array<String>) {
	foo()
	foo1(bar = 0)
	foo2(0)
	foo3(bar = 0, baz = 0)
	foo4(0, baz = 0)
	foo6(0, 0)
	println("${bla()}")
	println("${bla1(bar = 0)}")
	println("${bla2(0)}")
	println("${bla3(bar = 0, baz = 0)}")
	println("${bla4(0, baz = 0)}")
	println("${bla6(0, 0)}")
}
