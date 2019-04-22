data class LabeledType(
	val label: String,
	val type: String
)

class DeclarationReferenceExpression {
	var identifier: String
	var type: String
	var isStandardLibrary: Boolean
	var isImplicit: Boolean
	var range: SourceFileRange? = null

	constructor(
		identifier: String,
		type: String,
		isStandardLibrary: Boolean,
		isImplicit: Boolean,
		range: SourceFileRange?)
	{
		this.identifier = identifier
		this.type = type
		this.isStandardLibrary = isStandardLibrary
		this.isImplicit = isImplicit
		this.range = range
	}
}

public sealed class TupleShuffleIndex {
	class Variadic(val count: Int): TupleShuffleIndex()
	class Absent: TupleShuffleIndex()
	class Present: TupleShuffleIndex()

	override fun toString(): String {
		return when (this) {
			is TupleShuffleIndex.Variadic -> {
				val count: Int = this.count
				"variadics: ${count}"
			}
			is TupleShuffleIndex.Absent -> "absent"
			is TupleShuffleIndex.Present -> "present"
		}
	}
}
