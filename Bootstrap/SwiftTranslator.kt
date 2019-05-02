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

internal fun SwiftTranslator.translateSubscriptExpression(
	subscriptExpression: SwiftAST)
	: Expression
{
	if (subscriptExpression.name != "Subscript Expression") {
		return unexpectedExpressionStructureError(
			"Trying to translate ${subscriptExpression.name} as 'Subscript Expression'",
			ast = subscriptExpression,
			translator = this)
	}

	val rawType: String? = subscriptExpression["type"]
	val subscriptContents: SwiftAST? = subscriptExpression.subtree(index = 1, name = "Parentheses Expression") ?: subscriptExpression.subtree(index = 1, name = "Tuple Expression")
	val subscriptedExpression: SwiftAST? = subscriptExpression.subtree(index = 0)

	if (rawType != null && subscriptContents != null && subscriptedExpression != null) {
		val typeName: String = cleanUpType(rawType)
		val subscriptContentsTranslation: Expression = Expression.NilLiteralExpression()
		val subscriptedExpressionTranslation: Expression = Expression.NilLiteralExpression()

		return Expression.SubscriptExpression(
			subscriptedExpression = subscriptedExpressionTranslation,
			indexExpression = subscriptContentsTranslation,
			typeName = typeName)
	}
	else {
		return unexpectedExpressionStructureError(
			"Unrecognized structure",
			ast = subscriptExpression,
			translator = this)
	}
}

internal fun SwiftTranslator.translateArrayExpression(arrayExpression: SwiftAST): Expression {
	if (arrayExpression.name != "Array Expression") {
		return unexpectedExpressionStructureError(
			"Trying to translate ${arrayExpression.name} as 'Array Expression'",
			ast = arrayExpression,
			translator = this)
	}

	val expressionsToTranslate: MutableList<SwiftAST> = arrayExpression.subtrees.dropLast(1) as MutableList<SwiftAST>
	val expressionsArray: MutableList<Expression> = mutableListOf<Expression>()
	val rawType: String? = arrayExpression["type"]

	rawType ?: return unexpectedExpressionStructureError("Failed to get type", ast = arrayExpression, translator = this)

	val typeName: String = cleanUpType(rawType)

	return Expression.ArrayExpression(elements = expressionsArray, typeName = typeName)
}

internal fun SwiftTranslator.translateDictionaryExpression(
	dictionaryExpression: SwiftAST)
	: Expression
{
	if (dictionaryExpression.name != "Dictionary Expression") {
		return unexpectedExpressionStructureError(
			"Trying to translate ${dictionaryExpression.name} as 'Dictionary Expression'",
			ast = dictionaryExpression,
			translator = this)
	}

	val keys: MutableList<Expression> = mutableListOf()
	val values: MutableList<Expression> = mutableListOf()

	for (tupleExpression in dictionaryExpression.subtrees) {
		if (tupleExpression.name != "Tuple Expression") {
			continue
		}

		val keyAST: SwiftAST? = tupleExpression.subtree(index = 0)
		val valueAST: SwiftAST? = tupleExpression.subtree(index = 1)

		if (!(keyAST != null && valueAST != null)) {
			return unexpectedExpressionStructureError(
				"Unable to get either key or value for one of the tuple expressions",
				ast = dictionaryExpression,
				translator = this)
		}

		val keyTranslation: Expression = Expression.NilLiteralExpression()
		val valueTranslation: Expression = Expression.NilLiteralExpression()

		keys.add(keyTranslation)
		values.add(valueTranslation)
	}

	val typeName: String? = dictionaryExpression["type"]

	typeName ?: return unexpectedExpressionStructureError(
		"Unable to get type",
		ast = dictionaryExpression,
		translator = this)

	return Expression.DictionaryExpression(keys = keys, values = values, typeName = typeName)
}

internal fun SwiftTranslator.translateAsNumericLiteral(callExpression: SwiftAST): Expression {
	if (callExpression.name != "Call Expression") {
		return unexpectedExpressionStructureError(
			"Trying to translate ${callExpression.name} as 'Call Expression'",
			ast = callExpression,
			translator = this)
	}

	val tupleExpression: SwiftAST? = callExpression.subtree(name = "Tuple Expression")
	val literalExpression: SwiftAST? = tupleExpression?.subtree(name = "Integer Literal Expression") ?: tupleExpression?.subtree(name = "Float Literal Expression")
	val value: String? = literalExpression?.get("value")
	val constructorReferenceCallExpression: SwiftAST? = callExpression.subtree(name = "Constructor Reference Call Expression")
	val typeExpression: SwiftAST? = constructorReferenceCallExpression?.subtree(name = "Type Expression")
	val rawType: String? = typeExpression?.get("typerepr")

	if (value != null && literalExpression != null && rawType != null) {
		if (value.startsWith("0b") || value.startsWith("0o") || value.startsWith("0x")) {
			return unexpectedExpressionStructureError(
				"No support yet for alternative integer formats",
				ast = callExpression,
				translator = this)
		}

		val signedValue: String

		if (literalExpression.standaloneAttributes.contains("negative")) {
			signedValue = "-" + value
		}
		else {
			signedValue = value
		}

		val typeName: String = cleanUpType(rawType)

		if (typeName == "Double" || typeName == "Float64") {
			return Expression.LiteralDoubleExpression(value = signedValue.toDouble()!!)
		}
		else if (typeName == "Float" || typeName == "Float32") {
			return Expression.LiteralFloatExpression(value = signedValue.toFloat()!!)
		}
		else if (typeName == "Float80") {
			return unexpectedExpressionStructureError(
				"No support for 80-bit Floats",
				ast = callExpression,
				translator = this)
		}
		else if (typeName.startsWith("U")) {
			return Expression.LiteralUIntExpression(value = signedValue.toULong()!!)
		}
		else {
			if (signedValue == "-9223372036854775808") {
				return unexpectedExpressionStructureError(
					"Kotlin's Long (equivalent to Int64) only goes down to " + "-9223372036854775807",
					ast = callExpression,
					translator = this)
			}
			else {
				return Expression.LiteralIntExpression(value = signedValue.toLong()!!)
			}
		}
	}
	else {
		return unexpectedExpressionStructureError(
			"Unrecognized structure for numeric literal",
			ast = callExpression,
			translator = this)
	}
}

internal fun SwiftTranslator.translateAsBooleanLiteral(callExpression: SwiftAST): Expression {
	if (callExpression.name != "Call Expression") {
		return unexpectedExpressionStructureError(
			"Trying to translate ${callExpression.name} as 'Call Expression'",
			ast = callExpression,
			translator = this)
	}
	val value: String? = callExpression.subtree(name = "Tuple Expression")?.subtree(name = "Boolean Literal Expression")?.get("value")
	if (value != null) {
		return Expression.LiteralBoolExpression(value = value == "true")
	}
	else {
		return unexpectedExpressionStructureError(
			"Unrecognized structure for boolean literal",
			ast = callExpression,
			translator = this)
	}
}

internal fun SwiftTranslator.translateStringLiteralExpression(
	stringLiteralExpression: SwiftAST)
	: Expression
{
	if (stringLiteralExpression.name != "String Literal Expression") {
		return unexpectedExpressionStructureError(
			"Trying to translate ${stringLiteralExpression.name} as " + "'String Literal Expression'",
			ast = stringLiteralExpression,
			translator = this)
	}
	val value: String? = stringLiteralExpression["value"]
	if (value != null) {
		if (stringLiteralExpression["type"] == "Character") {
			if (value == "'") {
				return Expression.LiteralCharacterExpression(value = "\\'")
			}
			else {
				return Expression.LiteralCharacterExpression(value = value)
			}
		}
		else {
			return Expression.LiteralStringExpression(value = value)
		}
	}
	else {
		return unexpectedExpressionStructureError(
			"Unrecognized structure",
			ast = stringLiteralExpression,
			translator = this)
	}
}

internal fun SwiftTranslator.translateDeclarationReferenceExpression(
	declarationReferenceExpression: SwiftAST)
	: Expression
{
	if (declarationReferenceExpression.name != "Declaration Reference Expression") {
		return unexpectedExpressionStructureError(
			"Trying to translate ${declarationReferenceExpression.name} as " + "'Declaration Reference Expression'",
			ast = declarationReferenceExpression,
			translator = this)
	}

	val rawType: String? = declarationReferenceExpression["type"]

	rawType ?: return unexpectedExpressionStructureError(
		"Failed to recognize type",
		ast = declarationReferenceExpression,
		translator = this)

	val typeName: String = cleanUpType(rawType)
	val isImplicit: Boolean = declarationReferenceExpression.standaloneAttributes.contains("implicit")
	val range: SourceFileRange? = getRange(ast = declarationReferenceExpression)
	val discriminator: String? = declarationReferenceExpression["discriminator"]
	val codeDeclaration: String? = declarationReferenceExpression.standaloneAttributes.firstOrNull()
	val declaration: String? = declarationReferenceExpression["decl"]

	if (discriminator != null) {
		val declarationInformation: SwiftTranslator.DeclarationInformation = getInformationFromDeclaration(discriminator)
		return Expression.DeclarationReferenceExpression(
			data = DeclarationReferenceData(
					identifier = declarationInformation.identifier,
					typeName = typeName,
					isStandardLibrary = declarationInformation.isStandardLibrary,
					isImplicit = isImplicit,
					range = range))
	}
	else if (codeDeclaration != null && codeDeclaration.startsWith("code.")) {
		val declarationInformation: SwiftTranslator.DeclarationInformation = getInformationFromDeclaration(codeDeclaration)
		return Expression.DeclarationReferenceExpression(
			data = DeclarationReferenceData(
					identifier = declarationInformation.identifier,
					typeName = typeName,
					isStandardLibrary = declarationInformation.isStandardLibrary,
					isImplicit = isImplicit,
					range = range))
	}
	else if (declaration != null) {
		val declarationInformation: SwiftTranslator.DeclarationInformation = getInformationFromDeclaration(declaration)
		return Expression.DeclarationReferenceExpression(
			data = DeclarationReferenceData(
					identifier = declarationInformation.identifier,
					typeName = typeName,
					isStandardLibrary = declarationInformation.isStandardLibrary,
					isImplicit = isImplicit,
					range = range))
	}
	else {
		return unexpectedExpressionStructureError(
			"Unrecognized structure",
			ast = declarationReferenceExpression,
			translator = this)
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

internal fun SwiftTranslator.processPatternBindingDeclaration(
	patternBindingDeclaration: SwiftAST)
{
	if (patternBindingDeclaration.name != "Pattern Binding Declaration") {
		unexpectedExpressionStructureError(
			"Trying to translate ${patternBindingDeclaration.name} as " + "'Pattern Binding Declaration'",
			ast = patternBindingDeclaration,
			translator = this)
		danglingPatternBindings = mutableListOf(errorDanglingPatternDeclaration)
		return
	}

	val result: MutableList<SwiftTranslator.PatternBindingDeclaration?> = mutableListOf()
	val subtrees: MutableList<SwiftAST> = patternBindingDeclaration.subtrees

	while (!subtrees.isEmpty()) {
		var pattern: SwiftAST = subtrees.removeAt(0)
		val newPattern: SwiftAST? = pattern.subtree(name = "Pattern Named")

		if (newPattern != null && pattern.name == "Pattern Typed") {
			pattern = newPattern
		}

		val expression: SwiftAST? = subtrees.firstOrNull()

		if (expression != null && astIsExpression(expression)) {
			subtrees.removeAt(0)

			val translatedExpression: Expression = Expression.NilLiteralExpression()
			val identifier: String? = pattern.standaloneAttributes.firstOrNull()
			val rawType: String? = pattern["type"]

			if (!(identifier != null && rawType != null)) {
				unexpectedExpressionStructureError(
					"Type not recognized",
					ast = patternBindingDeclaration,
					translator = this)
				result.add(errorDanglingPatternDeclaration)
				continue
			}

			val typeName: String = cleanUpType(rawType)

			result.add(SwiftTranslator.PatternBindingDeclaration(
				identifier = identifier,
				typeName = typeName,
				expression = translatedExpression))
		}
		else {
			result.add(null)
		}
	}

	danglingPatternBindings = result
}

internal fun SwiftTranslator.processOpenExistentialExpression(
	openExistentialExpression: SwiftAST)
	: SwiftAST
{
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

internal fun SwiftTranslator.astIsExpression(ast: SwiftAST): Boolean {
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
