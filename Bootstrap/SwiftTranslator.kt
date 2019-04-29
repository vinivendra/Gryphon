class SwiftTranslator {
	data class PatternBindingDeclaration(
		val identifier: String,
		val typeName: String,
		val expression: Expression?
	)

	var danglingPatternBindings: MutableList<SwiftTranslator.PatternBindingDeclaration?> = mutableListOf()
	val errorDanglingPatternDeclaration: PatternBindingDeclaration = PatternBindingDeclaration(
		identifier = "<<Error>>",
		typeName = "<<Error>>",
		expression = Expression.Error())
	var sourceFile: SourceFile? = null

	constructor() {
	}
}
