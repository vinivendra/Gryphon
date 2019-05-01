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

internal fun SwiftTranslator.process(openExistentialExpression: SwiftAST): SwiftAST {
	if (openExistentialExpression.name != "Open Existential Expression") {
		unexpectedExpressionStructureError(
			"Trying to translate ${openExistentialExpression.name} as " + "'Open Existential Expression'",
			ast = openExistentialExpression,
			translator = this)
		return SwiftAST("Error", mutableListOf(), mutableMapOf(), mutableListOf())
	}

	val replacementSubtree: SwiftAST? = openExistentialExpression.subtree(index = 1)
	val resultSubtree: SwiftAST? = openExistentialExpression.subtrees.lastOrNull()

	if (!(replacementSubtree != null && resultSubtree != null)) {
		unexpectedExpressionStructureError(
			"Expected the AST to contain 3 subtrees: an Opaque Value Expression, an " + "expression to replace the opaque value, and an expression containing " + "opaque values to be replaced.",
			ast = openExistentialExpression,
			translator = this)
		return SwiftAST("Error", mutableListOf(), mutableMapOf(), mutableListOf())
	}

	return astReplacingOpaqueValues(ast = resultSubtree, replacementAST = replacementSubtree)
}

internal fun SwiftTranslator.astReplacingOpaqueValues(
	ast: SwiftAST,
	replacementAST: SwiftAST)
	: SwiftAST
{
	if (ast.name == "Opaque Value Expression") {
		return replacementAST
	}

	val newSubtrees: MutableList<SwiftAST> = mutableListOf()

	for (subtree in ast.subtrees) {
		newSubtrees.add(astReplacingOpaqueValues(ast = subtree, replacementAST = replacementAST))
	}

	return SwiftAST(ast.name, ast.standaloneAttributes, ast.keyValueAttributes, newSubtrees)
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

internal fun SwiftTranslator.createUnexpectedASTStructureError(
	errorMessage: String,
	ast: SwiftAST,
	translator: SwiftTranslator)
	: SwiftTranslatorError
{
	return SwiftTranslatorError(errorMessage = errorMessage, ast = ast, translator = translator)
}

internal fun SwiftTranslator.handleUnexpectedASTStructureError(error: Exception): Statement {
	Compiler.handleError(error)
	return Statement.Error()
}

internal fun SwiftTranslator.unexpectedASTStructureError(
	errorMessage: String,
	ast: SwiftAST,
	translator: SwiftTranslator)
	: Statement
{
	val error: SwiftTranslatorError = createUnexpectedASTStructureError(errorMessage, ast = ast, translator = translator)
	return handleUnexpectedASTStructureError(error)
}

internal fun SwiftTranslator.unexpectedExpressionStructureError(
	errorMessage: String,
	ast: SwiftAST,
	translator: SwiftTranslator)
	: Expression
{
	val error: SwiftTranslatorError = SwiftTranslatorError(errorMessage = errorMessage, ast = ast, translator = translator)
	Compiler.handleError(error)
	return Expression.Error()
}

data class SwiftTranslatorError(
	val errorMessage: String,
	val ast: SwiftAST,
	val translator: SwiftTranslator
): Exception() {
	override fun toString(): String {
		var nodeDescription: String = ""

		ast.prettyPrint { nodeDescription += it }

		val details: String = "When translating the following AST node:\n${nodeDescription}"

		return Compiler.createErrorOrWarningMessage(
			message = errorMessage,
			details = details,
			sourceFile = translator.sourceFile,
			sourceFileRange = translator.getRangeRecursively(ast = ast))
	}
}
