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
internal fun foo5(bar: Int, baz: Int) {
}
internal fun foo6(bar: Int, baz: Int) {
}

fun main(args: Array<String>) {
	foo()
	foo1(bar = 0)
	foo2(0)
	foo3(bar = 0, baz = 0)
	foo4(0, baz = 0)
	foo6(0, 0)
	println("Hello!")
	println(1)
}
