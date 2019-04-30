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

internal fun SwiftTranslator.getRange(ast: SwiftAST): SourceFileRange? {
	val rangeString: String? = ast["range"]

	rangeString ?: return null

	val firstSwiftExtensionEndIndex: Int? = rangeString.occurrences(searchedSubstring = ".swift:").firstOrNull()?.endInclusive

	firstSwiftExtensionEndIndex ?: return null

	var numberStartIndex: Int = firstSwiftExtensionEndIndex
	var numberEndIndex: Int = numberStartIndex

	while (rangeString[numberEndIndex].isNumber) {
		numberEndIndex = numberEndIndex + 1
	}

	val lineStartString: String = rangeString.substring(numberStartIndex, numberEndIndex)
	val lineStart: Int? = lineStartString.toIntOrNull()

	lineStart ?: return null

	numberStartIndex = numberEndIndex + 1
	numberEndIndex = numberStartIndex

	while (rangeString[numberEndIndex].isNumber) {
		numberEndIndex = numberEndIndex + 1
	}

	val columnStartString: String = rangeString.substring(numberStartIndex, numberEndIndex)
	val columnStart: Int? = columnStartString.toIntOrNull()

	columnStart ?: return null

	numberStartIndex = numberEndIndex + " - line:".length
	numberEndIndex = numberStartIndex

	while (rangeString[numberEndIndex].isNumber) {
		numberEndIndex = numberEndIndex + 1
	}

	val lineEndString: String = rangeString.substring(numberStartIndex, numberEndIndex)
	val lineEnd: Int? = lineEndString.toIntOrNull()

	lineEnd ?: return null

	numberStartIndex = numberEndIndex + 1
	numberEndIndex = numberStartIndex

	while (numberEndIndex < rangeString.length) {
		numberEndIndex = numberEndIndex + 1
	}

	val columnEndString: String = rangeString.substring(numberStartIndex, numberEndIndex)
	val columnEnd: Int? = columnEndString.toIntOrNull()

	columnEnd ?: return null

	return SourceFileRange(
		lineStart = lineStart,
		lineEnd = lineEnd,
		columnStart = columnStart,
		columnEnd = columnEnd)
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
