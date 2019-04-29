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

internal fun SwiftTranslator.cleanUpType(typeName: String): String {
	if (typeName.startsWith("@lvalue ")) {
		return typeName.suffix(startIndex = "@lvalue ".length)
	}
	else if (typeName.startsWith("(") && typeName.endsWith(")") && !typeName.contains("->") && !typeName.contains(",")) {
		return typeName.drop(1).dropLast(1)
	}
	else {
		return typeName
	}
}

internal fun SwiftTranslator.ASTIsExpression(ast: SwiftAST): Boolean {
	return ast.name.endsWith("Expression") || ast.name == "Inject Into Optional"
}
