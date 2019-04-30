class SwiftTranslator {
	data class PatternBindingDeclaration(
		val identifier: String,
		val typeName: String,
		val expression: Expression?
	)

	data class DeclarationInformation(
		val identifier: String,
		val isStandardLibrary: Boolean
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

internal fun SwiftTranslator.insertedCode(range: IntRange): MutableList<SourceFile.Comment> {
	val result: MutableList<SourceFile.Comment> = mutableListOf()
	for (lineNumber in range) {
		val insertComment: SourceFile.Comment? = sourceFile?.getCommentFromLine(lineNumber)
		if (insertComment != null) {
			result.add(insertComment)
		}
	}
	return result
}

internal fun SwiftTranslator.getRangeRecursively(ast: SwiftAST): SourceFileRange? {
	val range: SourceFileRange? = getRange(ast = ast)

	if (range != null) {
		return range
	}

	for (subtree in ast.subtrees) {
		val range: SourceFileRange? = getRange(ast = subtree)
		if (range != null) {
			return range
		}
	}

	return null
}

internal fun SwiftTranslator.getComment(ast: SwiftAST, key: String): String? {
	val comment: SourceFile.Comment? = getComment(ast = ast)
	if (comment != null && comment.key == key) {
		return comment.value
	}
	return null
}

internal fun SwiftTranslator.getComment(ast: SwiftAST): SourceFile.Comment? {
	val lineNumber: Int? = getRange(ast = ast)?.lineStart
	if (lineNumber != null) {
		return sourceFile?.getCommentFromLine(lineNumber)
	}
	else {
		return null
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

internal fun SwiftTranslator.getInformationFromDeclaration(
	declaration: String)
	: SwiftTranslator.DeclarationInformation
{
	val isStandardLibrary: Boolean = declaration.startsWith("Swift")
	var index: Int = 0
	var lastPeriodIndex: Int = 0

	while (index != declaration.length) {
		val character: Char = declaration[index]

		if (character == '.') {
			lastPeriodIndex = index
		}

		if (character == '@') {
			break
		}

		index = index + 1
	}

	var beforeLastPeriodIndex: Int = lastPeriodIndex - 1

	while (declaration[beforeLastPeriodIndex] == '.') {
		lastPeriodIndex = beforeLastPeriodIndex
		beforeLastPeriodIndex = lastPeriodIndex - 1
	}

	val identifierStartIndex: Int = lastPeriodIndex + 1
	val identifier: String = declaration.substring(identifierStartIndex, index)

	return SwiftTranslator.DeclarationInformation(
		identifier = identifier,
		isStandardLibrary = isStandardLibrary)
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
