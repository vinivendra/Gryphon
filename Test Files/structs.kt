data class UnsupportedStruct(
	val immutableVariable: Int = 0,
	var mutableVariable: Int = 0)
{
	internal fun pureFunction() {
	}
	internal fun mutatingFunction() {
	}
}
data class SupportedStruct(
	val x: Int = 0,
	val y: Int = 1)
{
}
data class OtherSupportedStruct(
	val x: Int,
	val y: Int)
{
}

fun main(args: Array<String>) {
	val a: SupportedStruct = SupportedStruct()
	val b: OtherSupportedStruct = OtherSupportedStruct(x = 10, y = 20)
	println(a.x)
	println(a.y)
	println(b.x)
	println(b.y)
}
