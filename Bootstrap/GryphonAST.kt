public sealed class Expression {
	class LiteralCodeExpression(val string: String): Expression()
	class LiteralDeclarationExpression(val string: String): Expression()
	class TemplateExpression(val pattern: String, val matches: MutableMap<String, Expression>): Expression()
	class ParenthesesExpression(val expression: Expression): Expression()
	class ForceValueExpression(val expression: Expression): Expression()
	class OptionalExpression(val expression: Expression): Expression()
	class DeclarationReferenceExpression(val data: DeclarationReferenceData): Expression()
	class TypeExpression(val type: String): Expression()
	class SubscriptExpression(val subscriptedExpression: Expression, val indexExpression: Expression, val type: String): Expression()
	class ArrayExpression(val elements: MutableList<Expression>, val type: String): Expression()
	class DictionaryExpression(val keys: MutableList<Expression>, val values: MutableList<Expression>, val type: String): Expression()
	class ReturnExpression(val expression: Expression?): Expression()
	class DotExpression(val leftExpression: Expression, val rightExpression: Expression): Expression()
	class BinaryOperatorExpression(val leftExpression: Expression, val rightExpression: Expression, val operatorSymbol: String, val type: String): Expression()
	class PrefixUnaryExpression(val expression: Expression, val operatorSymbol: String, val type: String): Expression()
	class PostfixUnaryExpression(val expression: Expression, val operatorSymbol: String, val type: String): Expression()
	class IfExpression(val condition: Expression, val trueExpression: Expression, val falseExpression: Expression): Expression()
	class CallExpression(val data: CallExpressionData): Expression()
	class LiteralIntExpression(val value: Long): Expression()
	class LiteralUIntExpression(val value: ULong): Expression()
	class LiteralDoubleExpression(val value: Double): Expression()
	class LiteralFloatExpression(val value: Float): Expression()
	class LiteralBoolExpression(val value: Boolean): Expression()
	class LiteralStringExpression(val value: String): Expression()
	class LiteralCharacterExpression(val value: String): Expression()
	class NilLiteralExpression: Expression()
	class InterpolatedStringLiteralExpression(val expressions: MutableList<Expression>): Expression()
	class TupleExpression(val pairs: MutableList<LabeledExpression>): Expression()
	class TupleShuffleExpression(val labels: MutableList<String>, val indices: MutableList<TupleShuffleIndex>, val expressions: MutableList<Expression>): Expression()
	class Error: Expression()
}

data class LabeledExpression(
	val label: String?,
	val expression: Expression
)

data class LabeledType(
	val label: String,
	val type: String
)

class DeclarationReferenceData {
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

class CallExpressionData {
	var function: Expression
	var parameters: Expression
	var type: String
	var range: SourceFileRange? = null

	constructor(
		function: Expression,
		parameters: Expression,
		type: String,
		range: SourceFileRange?)
	{
		this.function = function
		this.parameters = parameters
		this.type = type
		this.range = range
	}
}

class EnumElement {
	var name: String
	var associatedValues: MutableList<LabeledType>
	var rawValue: Expression? = null
	var annotations: String? = null

	constructor(
		name: String,
		associatedValues: MutableList<LabeledType>,
		rawValue: Expression?,
		annotations: String?)
	{
		this.name = name
		this.associatedValues = associatedValues
		this.rawValue = rawValue
		this.annotations = annotations
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
