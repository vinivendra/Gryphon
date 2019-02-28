data class UnsupportedStruct(
	val immutableVariable: Int = 0,
	var mutableVariable: Int = 0)
{
	internal fun pureFunction() {
	}
	internal fun mutatingFunction() {
	}
}
internal sealed class UnsupportedEnum {
	class A(val int: Int): UnsupportedEnum()
	internal fun mutatingFunction() {
	}
	val computedVarIsOK: Int
		get() {
			return 0
		}
}
