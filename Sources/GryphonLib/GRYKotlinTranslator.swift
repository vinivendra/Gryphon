/*
* Copyright 2018 Vinícius Jorge Vendramini
*
* Licensed under the Apache License, Version 2.0 (the "License");
* you may not use this file except in compliance with the License.
* You may obtain a copy of the License at
*
* http://www.apache.org/licenses/LICENSE-2.0
*
* Unless required by applicable law or agreed to in writing, software
* distributed under the License is distributed on an "AS IS" BASIS,
* WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
* See the License for the specific language governing permissions and
* limitations under the License.
*/

/// Unwraps a given value and returns it. If the value is nil, throws the given error.
///
/// - Note: Inspired by
/// 	https://lists.swift.org/pipermail/swift-evolution/Week-of-Mon-20160404/014272.html
///
/// - Parameters:
/// 	- value: The value to be unwrapped.
/// 	- error: The error to be thrown if the value is nil. If no error is given,
/// 		throws `GRYKotlinTranslator.TranslationError.unknown`.
/// - Returns: The unwrapped value, if present.
private func unwrapOrThrow<T>(
	_ value: T?,
	error: @autoclosure () -> Error = GRYKotlinTranslator.TranslationError.unknown)
	throws -> T
{
	if value == nil {
		throw error()
	}
	else {
		return value!
	}
}

public class GRYKotlinTranslator {

	/// Records the amount of translations that have been successfully translated;
	/// that can be refactored into translatable code; or that can't be translated.
	public class Diagnostics: CustomStringConvertible {
		/// The number of successfully translated subtrees
		private(set) var translatedSubtrees = 0
		/// The number of subtrees that can be refactored into translatable subtrees
		private(set) var refactorableSubtrees = 0
		/// The number of subtrees that can't be translated
		private(set) var unknownSubtrees = 0

		fileprivate func logSuccessfulTranslation(_ translation: String, forAST ast: GRYAst) {
			translatedSubtrees += 1
			let firstLineOfTranslation = translation.prefix(while: { $0 != "\n" })
			ast.translationStatus = .translated
			print("Translated: \(firstLineOfTranslation)")
		}

		fileprivate func logError(_ error: Error, forAST ast: GRYAst) {
			guard let translationError = error as? TranslationError else {
				// Methods in this class should only throw `TranslationError`s.
				// If the thrown error isn't a `TranslationError`, something unexpected happened.
				fatalError("Unkown error!")
			}

			switch translationError {
			case .refactorable:
				refactorableSubtrees += 1
				ast.translationStatus = .refactorable
			case .unknown:
				unknownSubtrees += 1
				ast.translationStatus = .unknown
			}
		}

		public var description: String {
			return """
			Kotlin translation diagnostics:
			\(translatedSubtrees) translated subtrees
			\(refactorableSubtrees) refactorable subtrees
			\(unknownSubtrees) unknown subtrees
			"""
		}
	}

	/// Records the amount of translations that have been successfully translated;
	/// that can be refactored into translatable code; or that can't be translated.
	var diagnostics: Diagnostics?

	private let checkmark = "✅ "

	fileprivate enum TranslationError: Error {
		case refactorable
		case unknown
	}

	/// Used for the translation of Swift types into Kotlin types.
	static let typeMappings = ["Bool": "Boolean", "Error": "Exception"]

	private func translateType(_ type: String) -> String {
		if type.hasPrefix("[") {
			let innerType = String(type.dropLast().dropFirst())
			let translatedInnerType = translateType(innerType)
			return "MutableList<\(translatedInnerType)>"
		}
		else if type.hasPrefix("ArrayReference<") {
			let innerType = String(type.dropLast().dropFirst("ArrayReference<".count))
			let translatedInnerType = translateType(innerType)
			return "MutableList<\(translatedInnerType)>"
		}
		else {
			return GRYKotlinTranslator.typeMappings[type] ?? type
		}
	}

	/**
	This variable is used to store enum definitions in order to allow the translator
	to translate them as sealed classes (see the `translate(dotSyntaxCallExpression)` method).
	*/
	private static var enums = [String]()

	/**
	This variable is used to allow calls to the `GRYIgnoreNext` function to ignore
	the next swift statement. When a call to that function is detected, this variable is set
	to true. Then, when the next statement comes along, the translator will see that this
	variable is set to true, ignore that statement, and then reset it to false to continue
	translation.
	*/
	private var shouldIgnoreNext = false

	/**
	Swift variables declared with a value, such as `var x = 0`, are represented in a weird way in
	the AST: first comes a `Pattern Binding Declaration` containing the variable's name, its type,
	and its initial value; then comes the actual `Variable Declaration`, but in a different branch
	of the AST and with no information on the previously mentioned initial value.
	
	Since both of them have essential information, we need both at the same time to translate a
	variable declaration. However, since they are in unpredictably different branches, it's hard to
	find the Variable Declaration when we first read the Pattern Binding Declaration.
	
	The solution then is to temporarily save the Pattern Binding Declaration's information on this
	variable. Then, once we find the Variable Declaration, we check to see if the stored value is
	appropriate and then use all the information available to complete the translation process. This
	variable is then reset to nil.
	
	- SeeAlso: translate(variableDeclaration:, withIndentation:)
	*/
	var danglingPatternBinding: (identifier: String, type: String, translatedExpression: String)?

	// MARK: - Interface

	/**
	Translates the swift statements in the `ast` into kotlin code.
	
	The swift AST may contain either top-level statements (such as in a "main" file), declarations
	(i.e. function or class declarations), or both. Any declarations will be translated at the
	beggining of the file, and any top-level statements will be wrapped in a `main` function and
	added to the end of the file.
	
	If no top-level statements are found, the main function is ommited.
	
	This function should be given the AST of a single source file, and should provide a translation
	of that source file's contents.
	
	- Parameter ast: The AST, obtained from swift, containing a "Source File" node at the root.
	- Returns: A kotlin translation of the contents of the AST.
	*/
	public func translateAST(_ ast: GRYAst) -> String {
		// First, translate declarations that shouldn't be inside the main function
		let declarationNames = [
			"Class Declaration",
			"Extension Declaration",
			"Function Declaration",
			"Enum Declaration",
		]
		let isDeclaration = { (ast: GRYAst) -> Bool in declarationNames.contains(ast.name) }

		let declarations = ast.subTrees.filter(isDeclaration)

		var result = translate(subTrees: declarations, withIndentation: "")

		// Then, translate the remaining statements (if there are any) and wrap them in the main
		// function
		let indentation = increaseIndentation("")
		let statements = ast.subTrees.filter({ !isDeclaration($0) })
		let statementsString = translate(subTrees: statements, withIndentation: indentation)
		guard !statementsString.isEmpty else {
			return result
		}

		// Add newline between declarations and the main function, if needed
		if !result.isEmpty {
			result += "\n"
		}

		result += "fun main(args: Array<String>) {\n\(statementsString)}\n"

		return result
	}

	// MARK: - Implementation

	// TODO: Make sure these methods only throw when they themselves can't be translated.
	private func translate(subTree: GRYAst, withIndentation indentation: String) -> String {
		do {
			let result: String

			switch subTree.name {
			case "Import Declaration":
				result = ""
			case "Class Declaration":
				result = try translate(
					classDeclaration: subTree,
					withIndentation: indentation)
			case "Constructor Declaration":
				result = try translate(
					constructorDeclaration: subTree,
					withIndentation: indentation)
			case "Destructor Declaration":
				result = try translate(
					destructorDeclaration: subTree,
					withIndentation: indentation)
			case "Enum Declaration":
				result = try translate(
					enumDeclaration: subTree,
					withIndentation: indentation)
			case "Extension Declaration":
				result = translate(
					subTrees: subTree.subTrees,
					withIndentation: indentation)
			case "For Each Statement":
				result = try translate(
					forEachStatement: subTree,
					withIndentation: indentation)
			case "Function Declaration":
				result = try translate(
					functionDeclaration: subTree,
					withIndentation: indentation)
			case "Protocol":
				result = try translate(
					protocolDeclaration: subTree,
					withIndentation: indentation)
			case "Top Level Code Declaration":
				return try translate(
					topLevelCode: subTree,
					withIndentation: indentation)
			case "Throw Statement":
				result = try translate(
					throwStatement: subTree,
					withIndentation: indentation)
			case "Variable Declaration":
				result = try translate(
					variableDeclaration: subTree,
					withIndentation: indentation)
			case "Assign Expression":
				result = try translate(
					assignExpression: subTree,
					withIndentation: indentation)
			case "Guard Statement":
				result = try translate(
					ifStatement: subTree,
					asGuard: true,
					withIndentation: indentation)
			case "If Statement":
				result = try translate(
					ifStatement: subTree,
					withIndentation: indentation)
			case "Pattern Binding Declaration":
				try process(patternBindingDeclaration: subTree)
				result = ""
			case "Return Statement":
				result = try translate(
					returnStatement: subTree,
					withIndentation: indentation)
			case "Call Expression":
				let translation = try translate(callExpression: subTree)

				if !translation.isEmpty {
					result = indentation + translation + "\n"
				}
				else {
					result = ""
				}
			default:
				if subTree.name.hasSuffix("Expression") {
					result = try indentation + translate(expression: subTree) + "\n"
				}
				else {
					throw TranslationError.unknown
				}
			}

			if !result.isEmpty {
				diagnostics?.logSuccessfulTranslation(
					"[\(subTree.name)] \(result)",
					forAST: subTree)

				if !result.hasPrefix(checkmark) {
					return checkmark + result
				}
				else {
					return checkmark + "/*\(subTree.name)*/\n" + result
				}
			}
			else {
				return result
			}
		}
		catch let error {
			diagnostics?.logError(error, forAST: subTree)
			return code(for: error, inASTNamed: subTree.name)
		}
	}

	private func translate(subTrees: [GRYAst], withIndentation indentation: String) -> String {
		var result = ""

		for subTree in subTrees {
			if shouldIgnoreNext {
				shouldIgnoreNext = false
				continue
			}

			result += translate(subTree: subTree, withIndentation: indentation)
		}

		return result
	}

	private func process(patternBindingDeclaration: GRYAst) throws {
		precondition(patternBindingDeclaration.name == "Pattern Binding Declaration")

		// Some patternBindingDeclarations are empty, and that's ok. See the classes.swift test
		// case.
		guard let expression = patternBindingDeclaration.subTrees.last,
			ASTIsExpression(expression) else { return }

		let binding: GRYAst

		if let unwrappedBinding = patternBindingDeclaration
			.subTree(named: "Pattern Typed")?
			.subTree(named: "Pattern Named")
		{
			binding = unwrappedBinding
		}
		else if let unwrappedBinding = patternBindingDeclaration.subTree(named: "Pattern Named") {
			binding = unwrappedBinding
		}
		else {
			throw TranslationError.unknown
		}

		let identifier = try unwrapOrThrow(binding.standaloneAttributes.first)
		let rawType = try unwrapOrThrow(binding.keyValueAttributes["type"])
		let type = translateType(rawType)

		danglingPatternBinding = try
			(identifier: identifier,
			 type: type,
			 translatedExpression: translate(expression: expression))
	}

	private func translate(topLevelCode: GRYAst, withIndentation indentation: String)
		throws -> String
	{
		precondition(topLevelCode.name == "Top Level Code Declaration")

		let braceStatement = try unwrapOrThrow(topLevelCode.subTree(named: "Brace Statement"))
		return translate(subTrees: braceStatement.subTrees, withIndentation: indentation)
	}

	private func translate(enumDeclaration: GRYAst, withIndentation indentation: String)
		throws -> String
	{
		precondition(enumDeclaration.name == "Enum Declaration")

		let enumName = try unwrapOrThrow(enumDeclaration.standaloneAttributes.first)

		GRYKotlinTranslator.enums.append(enumName)

		let inheritanceList = try unwrapOrThrow(enumDeclaration.keyValueAttributes["inherits"])
		let access = try unwrapOrThrow(enumDeclaration.keyValueAttributes["access"])

		let rawInheritanceArray = inheritanceList.split(withStringSeparator: ", ")

		if rawInheritanceArray.contains("GRYIgnore") {
			return ""
		}

		var inheritanceArray = rawInheritanceArray.map { translateType($0) }

		// The inheritanceArray isn't empty because the inheritanceList isn't empty.
		inheritanceArray[0] = inheritanceArray[0] + "()"

		let inheritanceString = inheritanceArray.joined(separator: ", ")

		var result = "\(indentation)\(access) sealed class \(enumName): \(inheritanceString) {\n"

		let increasedIndentation = increaseIndentation(indentation)

		let enumElementDeclarations =
			enumDeclaration.subTrees.filter { $0.name == "Enum Element Declaration" }
		for enumElementDeclaration in enumElementDeclarations {
			let elementName = try unwrapOrThrow(enumElementDeclaration.standaloneAttributes.first)

			let capitalizedElementName = elementName.capitalizedAsCamelCase

			result += "\(increasedIndentation)class \(capitalizedElementName): \(enumName)()\n"
		}

		result += "\(indentation)}\n"

		return result
	}

	private func translate(protocolDeclaration: GRYAst, withIndentation indentation: String)
		throws -> String
	{
		precondition(protocolDeclaration.name == "Protocol")

		let protocolName = try unwrapOrThrow(protocolDeclaration.standaloneAttributes.first)

		if protocolName == "GRYIgnore" {
			return ""
		}
		else {
			// Add actual protocol translation here
			return code(for: TranslationError.unknown, inASTNamed: protocolDeclaration.name)
		}
	}

	private func translate(classDeclaration: GRYAst, withIndentation indentation: String)
		throws -> String
	{
		precondition(classDeclaration.name == "Class Declaration")

		let className = try unwrapOrThrow(classDeclaration.standaloneAttributes.first)

		let inheritanceString: String
		if let inheritanceList = classDeclaration.keyValueAttributes["inherits"] {
			let rawInheritanceArray = inheritanceList.split(withStringSeparator: ", ")

			if rawInheritanceArray.contains("GRYIgnore") {
				return ""
			}

			let inheritanceArray = rawInheritanceArray.map { translateType($0) }
			inheritanceString = ": \(inheritanceArray.joined(separator: ", "))"
		}
		else {
			inheritanceString = ""
		}

		let increasedIndentation = increaseIndentation(indentation)
		let classContents = translate(
			subTrees: classDeclaration.subTrees,
			withIndentation: increasedIndentation)

		return "class \(className)\(inheritanceString) {\n\(classContents)}\n"
	}

	private func translate(constructorDeclaration: GRYAst, withIndentation indentation: String)
		throws -> String
	{
		precondition(constructorDeclaration.name == "Constructor Declaration")

		guard !constructorDeclaration.standaloneAttributes.contains("implicit") else {
			return ""
		}

		throw TranslationError.unknown
	}

	private func translate(destructorDeclaration: GRYAst, withIndentation indentation: String)
		throws -> String
	{
		precondition(destructorDeclaration.name == "Destructor Declaration")

		guard !destructorDeclaration.standaloneAttributes.contains("implicit") else {
			return ""
		}

		throw TranslationError.unknown
	}

	private func translate(functionDeclaration: GRYAst, withIndentation indentation: String)
		throws -> String
	{
		precondition(functionDeclaration.name == "Function Declaration")

		// Getters and setters will appear again in the Variable Declaration AST and get translated
		let isGetterOrSetter =
			(functionDeclaration["getter_for"] != nil) || (functionDeclaration["setter_for"] != nil)
		let isImplicit = functionDeclaration.standaloneAttributes.contains("implicit")
		guard !isImplicit && !isGetterOrSetter else {
			return ""
		}

		let functionName = try unwrapOrThrow(functionDeclaration.standaloneAttributes.first)

		guard !functionName.hasPrefix("GRYInsert(") &&
			!functionName.hasPrefix("GRYAlternative(") &&
			!functionName.hasPrefix("GRYIgnoreNext(") else { return "" }

		guard !functionName.hasPrefix("GRYDeclarations(") else {
			let braceStatement = try unwrapOrThrow(
				functionDeclaration.subTree(named: "Brace Statement"))
			return translate(subTrees: braceStatement.subTrees, withIndentation: indentation)
		}

		guard functionDeclaration.standaloneAttributes.count <= 1 else {
			throw TranslationError.unknown
		}

		var indentation = indentation
		var result = ""

		result += indentation

		if let access = functionDeclaration["access"] {
			result += access + " "
		}

		result += "fun "

		let functionNamePrefix = functionName.prefix { $0 != "(" }

		result += functionNamePrefix + "("

		var parameterStrings = [String]()

		let parameterList: GRYAst?
		if let list = functionDeclaration.subTree(named: "Parameter List"),
			let name = list.subTree(at: 0, named: "Parameter")?.standaloneAttributes.first,
			name != "self"
		{
			parameterList = list
		}
		else if let unwrapped = functionDeclaration.subTree(at: 1, named: "Parameter List") {
			parameterList = unwrapped
		}
		else {
			parameterList = nil
		}

		if let parameterList = parameterList {
			for parameter in parameterList.subTrees {
				let name = try unwrapOrThrow(parameter.standaloneAttributes.first)
				guard name != "self" else { continue }

				let rawType = try unwrapOrThrow(parameter["interface type"])

				let type = translateType(rawType)
				parameterStrings.append(name + ": " + type)
			}
		}

		result += parameterStrings.joined(separator: ", ")

		result += ")"

		// TODO: Doesn't allow to return function types
		let rawType = try unwrapOrThrow(
			(functionDeclaration["interface type"]?.split(withStringSeparator: " -> ").last))

		let returnType = translateType(rawType)
		if returnType != "()" {
			result += ": " + returnType
		}

		result += " {\n"

		indentation = increaseIndentation(indentation)

		let braceStatement = try unwrapOrThrow(
			functionDeclaration.subTree(named: "Brace Statement"))

		result += translate(subTrees: braceStatement.subTrees, withIndentation: indentation)

		indentation = decreaseIndentation(indentation)

		result += indentation + "}\n"

		return result
	}

	private func translate(forEachStatement: GRYAst, withIndentation indentation: String)
		throws -> String
	{
		precondition(forEachStatement.name == "For Each Statement")

		guard let braceStatement = forEachStatement.subTrees.last,
			braceStatement.name == "Brace Statement",
			let variableName = forEachStatement
				.subTree(named: "Pattern Named")?
				.standaloneAttributes.first,
			let collectionExpression = forEachStatement.subTree(at: 2) else
		{
			throw TranslationError.unknown
		}

		let collectionString = try translate(expression: collectionExpression)

		let forEachHeader = "\(indentation)for (\(variableName) in \(collectionString))"

		let increasedIndentation = increaseIndentation(indentation)
		let statements = translate(
			subTrees: braceStatement.subTrees,
			withIndentation: increasedIndentation)

		let result = """
		\(forEachHeader) {
		\(statements)\
		\(indentation)}

		"""

		return result
	}

	private func translate(
		ifStatement: GRYAst,
		asElseIf isElseIf: Bool = false,
		asGuard isGuard: Bool = false,
		withIndentation indentation: String) throws -> String
	{
		precondition(ifStatement.name == "If Statement" || ifStatement.name == "Guard Statement")

		let (letDeclarationsString, conditionString) = try translateDeclarationsAndConditions(
			forIfStatement: ifStatement,
			withIndentation: indentation)

		let increasedIndentation = increaseIndentation(indentation)

		var elseIfString = ""
		var elseString = ""
		let braceStatement: GRYAst

		if ifStatement.subTrees.count > 2,
			let unwrappedBraceStatement = ifStatement.subTrees.secondToLast,
			unwrappedBraceStatement.name == "Brace Statement",
			let elseIfAST = ifStatement.subTrees.last,
			elseIfAST.name == "If Statement"
		{
			braceStatement = unwrappedBraceStatement

			elseIfString =
				try translate(ifStatement: elseIfAST, asElseIf: true, withIndentation: indentation)
		}
		else if ifStatement.subTrees.count > 2,
			let unwrappedBraceStatement = ifStatement.subTrees.secondToLast,
			unwrappedBraceStatement.name == "Brace Statement",
			let elseAST = ifStatement.subTrees.last,
			elseAST.name == "Brace Statement"
		{
			braceStatement = unwrappedBraceStatement

			let statementsString =
				translate(subTrees: elseAST.subTrees, withIndentation: increasedIndentation)
			elseString = "\(indentation)else {\n\(statementsString)\(indentation)}\n"
		}
		else if let unwrappedBraceStatement = ifStatement.subTrees.last,
			unwrappedBraceStatement.name == "Brace Statement"
		{
			braceStatement = unwrappedBraceStatement
		}
		else {
			throw TranslationError.unknown
		}

		let statements = braceStatement.subTrees
		let statementsString =
			translate(subTrees: statements, withIndentation: increasedIndentation)

		let keyword = isElseIf ? "else if" : "if"
		let parenthesizedCondition = isGuard ? "(!(\(conditionString)))" : "(\(conditionString))"

		let ifString = """
		\(letDeclarationsString)\(indentation)\(keyword) \(parenthesizedCondition) {
		\(statementsString)\
		\(indentation)}

		"""

		return ifString + elseIfString + elseString
	}

	private func translateDeclarationsAndConditions(
		forIfStatement ifStatement: GRYAst,
		withIndentation indentation: String)
		throws -> (letDeclarationsString: String, conditionString: String)
	{
		precondition(ifStatement.name == "If Statement" || ifStatement.name == "Guard Statement")

		var conditionStrings = [String]()
		var letDeclarations = [String]()

		let conditions = ifStatement.subTrees.filter {
			$0.name != "If Statement" && $0.name != "Brace Statement"
		}

		for condition in conditions {
			// If it's an if-let
			if condition.name == "Pattern",
				let optionalSomeElement = condition.subTree(named: "Optional Some Element")
			{

				let patternNamed: GRYAst
				let varOrValKeyword: String
				if let patternLet = optionalSomeElement.subTree(named: "Pattern Let"),
					let unwrapped = patternLet.subTree(named: "Pattern Named")
				{
					patternNamed = unwrapped
					varOrValKeyword = "val"
				}
				else if let unwrapped = optionalSomeElement
					.subTree(named: "Pattern Variable")?
					.subTree(named: "Pattern Named")
				{
					patternNamed = unwrapped
					varOrValKeyword = "var"
				}
				else {
					throw TranslationError.unknown
				}

				let typeString: String
				if let rawType = optionalSomeElement["type"] {
					let type = translateType(rawType)
					typeString = ": \(type)"
				}
				else {
					typeString = ""
				}

				let name = try unwrapOrThrow(patternNamed.standaloneAttributes.first)

				let lastCondition = try unwrapOrThrow(condition.subTrees.last)
				let expressionString = try translate(expression: lastCondition)

				letDeclarations.append(
					"\(indentation)\(varOrValKeyword) \(name)\(typeString) = \(expressionString)\n")
				conditionStrings.append("\(name) != null")
			}
			else {
				try conditionStrings.append(translate(expression: condition))
			}
		}
		let letDeclarationsString = letDeclarations.joined()
		let conditionString = conditionStrings.joined(separator: " && ")

		return (letDeclarationsString, conditionString)
	}

	private func translate(
		throwStatement: GRYAst,
		withIndentation indentation: String) throws -> String
	{
		precondition(throwStatement.name == "Throw Statement")

		guard let expression = throwStatement.subTrees.last else {
			throw TranslationError.unknown
		}
		let expressionString = try translate(expression: expression)
		return "\(indentation)throw \(expressionString)\n"
	}

	private func translate(
		returnStatement: GRYAst,
		withIndentation indentation: String) throws -> String
	{
		precondition(returnStatement.name == "Return Statement")

		if let expression = returnStatement.subTrees.last {
			let expressionString = try translate(expression: expression)
			return "\(indentation)return \(expressionString)\n"
		}
		else {
			return "\(indentation)return\n"
		}
	}

	/**
	Translates a swift variable declaration into kotlin code.
	
	This function checks the value stored in `danglingPatternBinding`. If a value is present and
	it's consistent with this variable declaration (same identifier and type), we use the expression
	inside it as the initial value for the variable (and the `danglingPatternBinding` is reset to
	`nil`). Otherwise, the variable is declared without an initial value.
	*/
	private func translate(
		variableDeclaration: GRYAst,
		withIndentation indentation: String)
		throws -> String
	{
		precondition(variableDeclaration.name == "Variable Declaration")

		var result = indentation

		let identifier = try unwrapOrThrow(variableDeclaration.standaloneAttributes.first)

		let rawType = try unwrapOrThrow(variableDeclaration["interface type"])

		let type = translateType(rawType)

		let hasGetter = variableDeclaration.subTrees.contains(where:
		{ (subTree: GRYAst) -> Bool in
			return subTree.name == "Function Declaration" &&
				!subTree.standaloneAttributes.contains("implicit") &&
				subTree.keyValueAttributes["getter_for"] != nil
		})
		let hasSetter = variableDeclaration.subTrees.contains(where:
		{ (subTree: GRYAst) -> Bool in
			return subTree.name == "Function Declaration" &&
				!subTree.standaloneAttributes.contains("implicit") &&
				subTree.keyValueAttributes["setter_for"] != nil
		})

		let keyword: String
		if hasGetter && hasSetter {
			keyword = "var"
		}
		else if hasGetter && !hasSetter {
			keyword = "val"
		}
		else {
			if variableDeclaration.standaloneAttributes.contains("let") {
				keyword = "val"
			}
			else {
				keyword = "var"
			}
		}

		let extensionPrefix: String
		if let extensionType = variableDeclaration["extends_type"] {
			extensionPrefix = "\(extensionType)."
		}
		else {
			extensionPrefix = ""
		}

		result += "\(keyword) \(extensionPrefix)\(identifier): \(type)"

		if let patternBindingExpression = danglingPatternBinding,
			patternBindingExpression.identifier == identifier,
			patternBindingExpression.type == type
		{
			result += " = " + patternBindingExpression.translatedExpression
			danglingPatternBinding = nil
		}

		result += "\n"

		result += try translateGetterAndSetter(
			forVariableDeclaration: variableDeclaration,
			withIndentation: indentation)

		return result
	}

	private func translateGetterAndSetter(
		forVariableDeclaration variableDeclaration: GRYAst,
		withIndentation indentation: String) throws -> String
	{
		var result = ""

		let getSetIndentation = increaseIndentation(indentation)
		for subtree in variableDeclaration.subTrees
			where !subtree.standaloneAttributes.contains("implicit")
		{
			assert(subtree.name == "Function Declaration")

			var subResult = ""

			let keyword: String

			if subtree["getter_for"] != nil {
				keyword = "get()"
			}
			else {
				keyword = "set(newValue)"
			}

			subResult += "\(getSetIndentation)\(keyword) {\n"

			let contentsIndentation = increaseIndentation(getSetIndentation)

			let statements = try unwrapOrThrow(subtree.subTree(named: "Brace Statement")?.subTrees)

			let contentsString =
				translate(subTrees: statements, withIndentation: contentsIndentation)
			subResult += contentsString

			subResult += "\(getSetIndentation)}\n"

			diagnostics?.logSuccessfulTranslation(
				"[Getter/Setter] \(subResult)",
				forAST: subtree)
			result += checkmark + subResult
		}

		return result
	}

	private func translate(assignExpression: GRYAst, withIndentation indentation: String)
		throws -> String
	{
		precondition(assignExpression.name == "Assign Expression")

		let leftExpression = try unwrapOrThrow(assignExpression.subTree(at: 0))
		let rightExpression = try unwrapOrThrow(assignExpression.subTree(at: 1))
		let leftString = try translate(expression: leftExpression)
		let rightString = try translate(expression: rightExpression)

		let result = "\(indentation)\(leftString) = \(rightString)\n"

		return result
	}

	private func translate(expression: GRYAst) throws -> String {
		switch expression.name {
		case "Array Expression":
			return try translate(arrayExpression: expression)
		case "Binary Expression":
			return try translate(binaryExpression: expression)
		case "Call Expression":
			return try translate(callExpression: expression)
		case "Declaration Reference Expression":
			return try translate(declarationReferenceExpression: expression)
		case "Dot Syntax Call Expression":
			return try translate(dotSyntaxCallExpression: expression)
		case "String Literal Expression":
			return try translate(stringLiteralExpression: expression)
		case "Interpolated String Literal Expression":
			return try translate(interpolatedStringLiteralExpression: expression)
		case "Erasure Expression":
			let lastExpression = try unwrapOrThrow(expression.subTrees.last)
			return try translate(expression: lastExpression)
		case "Prefix Unary Expression":
			return try translate(prefixUnaryExpression: expression)
		case "Type Expression":
			return try translate(typeExpression: expression)
		case "Member Reference Expression":
			return try translate(memberReferenceExpression: expression)
		case "Subscript Expression":
			return try translate(subscriptExpression: expression)
		case "Parentheses Expression":
			let firstExpression = try unwrapOrThrow(expression.subTree(at: 0))
			return try "(" + translate(expression: firstExpression) + ")"
		case "Force Value Expression":
			let firstExpression = try unwrapOrThrow(expression.subTree(at: 0))
			return try translate(expression: firstExpression) + "!!"
		case "Autoclosure Expression",
			 "Inject Into Optional",
			 "Inout Expression",
			 "Load Expression":
			let lastExpression = try unwrapOrThrow(expression.subTrees.last)
			return try translate(expression: lastExpression)
		default:
			throw TranslationError.unknown
		}
	}

	private func translate(typeExpression: GRYAst) throws -> String {
		precondition(typeExpression.name == "Type Expression")
		let rawType = try unwrapOrThrow(typeExpression.keyValueAttributes["typerepr"])
		return translateType(rawType)
	}

	private func translate(subscriptExpression: GRYAst) throws -> String {
		precondition(subscriptExpression.name == "Subscript Expression")

		if let parenthesesExpression = subscriptExpression.subTree(
			at: 1,
			named: "Parentheses Expression"),
			let subscriptContents = parenthesesExpression.subTree(at: 0),
			let subscriptedExpression = subscriptExpression.subTree(at: 0)
		{
			let subscriptedString = try translate(expression: subscriptedExpression)
			let subscriptContentsString = try translate(expression: subscriptContents)
			return "\(subscriptedString)[\(subscriptContentsString)]"
		}
		else {
			throw TranslationError.unknown
		}
	}

	private func translate(arrayExpression: GRYAst) throws -> String {
		precondition(arrayExpression.name == "Array Expression")

		let expressionsArray = try arrayExpression.subTrees.map { try translate(expression: $0) }
		let expressionsString = expressionsArray.joined(separator: ", ")

		return "mutableListOf(\(expressionsString))"
	}

	private func translate(dotSyntaxCallExpression: GRYAst) throws -> String {
		precondition(dotSyntaxCallExpression.name == "Dot Syntax Call Expression")

		let rightHandExpression = try unwrapOrThrow(dotSyntaxCallExpression.subTree(at: 0))
		let rightHandSide = try translate(expression: rightHandExpression)

		let leftHandTree = try unwrapOrThrow(dotSyntaxCallExpression.subTree(at: 1))
		if leftHandTree.name == "Type Expression" {

			let leftHandSide = try translate(typeExpression: leftHandTree)

			// Enums become sealed classes, which need parentheses at the end
			if GRYKotlinTranslator.enums.contains(leftHandSide) {
				let capitalizedEnumCase = rightHandSide.capitalizedAsCamelCase
				return "\(leftHandSide).\(capitalizedEnumCase)()"
			}
			else {
				return "\(leftHandSide).\(rightHandSide)"
			}
		}
		else {
			let leftHandSide = try translate(typeExpression: leftHandTree)

			return "\(leftHandSide).\(rightHandSide)"
		}
	}

	private func translate(binaryExpression: GRYAst) throws -> String {
		precondition(binaryExpression.name == "Binary Expression")

		let operatorIdentifier: String

		if let declaration = binaryExpression
				.subTree(named: "Dot Syntax Call Expression")?
				.subTree(named: "Declaration Reference Expression")?["decl"],
			let tupleExpression = binaryExpression.subTree(named: "Tuple Expression"),
			let leftHandExpression = tupleExpression.subTree(at: 0),
			let rightHandExpression = tupleExpression.subTree(at: 1)
		{
			operatorIdentifier = getIdentifierFromDeclaration(declaration)

			let leftHandSide = try translate(expression: leftHandExpression)
			let rightHandSide = try translate(expression: rightHandExpression)

			return "\(leftHandSide) \(operatorIdentifier) \(rightHandSide)"
		}
		else {
			throw TranslationError.unknown
		}
	}

	private func translate(prefixUnaryExpression: GRYAst) throws -> String {
		precondition(prefixUnaryExpression.name == "Prefix Unary Expression")

		if let declaration = prefixUnaryExpression
				.subTree(named: "Dot Syntax Call Expression")?
				.subTree(named: "Declaration Reference Expression")?["decl"],
			let expression = prefixUnaryExpression.subTree(at: 1)
		{
			let operatorIdentifier = getIdentifierFromDeclaration(declaration)
			let expressionString = try translate(expression: expression)
			return "\(operatorIdentifier)\(expressionString)"
		}
		else {
			throw TranslationError.unknown
		}
	}

	/**
	Translates a swift call expression into kotlin code.
	
	A call expression is a function call, but it can be explicit (as usual) or implicit
	(i.e. integer literals). Currently, the only implicit calls supported are integer, boolean and
	nil literals.
	
	As a special case, functions called GRYInsert, GRYAlternative and GRYIgnoreNext are used to
	directly manipulate the resulting kotlin code, and are treated separately below.
	
	As another special case, a call to the `print` function gets renamed to `println` for
	compatibility with kotlin. In the future, this will be done by a more complex system, but for
	now it allows integration tests to exist.
	
	- Note: If conditions include an "empty" call expression wrapping its real expression. This
	function handles the unwrapping then delegates the translation.
	*/
	private func translate(callExpression: GRYAst) throws -> String {
		precondition(callExpression.name == "Call Expression")

		// If the call expression corresponds to an integer literal
		if let argumentLabels = callExpression["arg_labels"],
			argumentLabels == "_builtinIntegerLiteral:"
		{
			return try translate(asNumericLiteral: callExpression)
		}
			// If the call expression corresponds to an boolean literal
		else if let argumentLabels = callExpression["arg_labels"],
			argumentLabels == "_builtinBooleanLiteral:"
		{
			return try translate(asBooleanLiteral: callExpression)
		}
			// If the call expression corresponds to `nil`
		else if let argumentLabels = callExpression["arg_labels"],
			argumentLabels == "nilLiteral:"
		{
			return "null"
		}
		else {
			let functionName: String

			if callExpression.standaloneAttributes.contains("implicit"),
				callExpression["arg_labels"] == "",
				callExpression["type"] == "Int1",
				let containedExpression = callExpression
					.subTree(named: "Dot Syntax Call Expression")?
					.subTrees.last
			{
				// If it's an empty expression used in an "if" condition
				return try translate(expression: containedExpression)
			}
			if let declarationReferenceExpression = callExpression
				.subTree(named: "Declaration Reference Expression")
			{
				functionName =
					try translate(declarationReferenceExpression: declarationReferenceExpression)
			}
			else if let dotSyntaxCallExpression = callExpression
					.subTree(named: "Dot Syntax Call Expression"),
				let methodName = dotSyntaxCallExpression
					.subTree(at: 0, named: "Declaration Reference Expression"),
				let methodOwner = dotSyntaxCallExpression.subTree(at: 1)
			{
				let methodNameString = try translate(declarationReferenceExpression: methodName)
				let methodOwnerString = try translate(expression: methodOwner)
				functionName = "\(methodOwnerString).\(methodNameString)"
			}
			else if let typeExpression = callExpression
				.subTree(named: "Constructor Reference Call Expression")?
				.subTree(named: "Type Expression")
			{
				functionName = try translate(typeExpression: typeExpression)
			}
			else if let declaration = callExpression["decl"] {
				functionName = getIdentifierFromDeclaration(declaration)
			}
			else {
				throw TranslationError.unknown
			}

			// If we're here, then the call expression corresponds to an explicit function call
			let functionNamePrefix = functionName.prefix(while: { $0 != "(" })

			guard functionNamePrefix != "GRYInsert" &&
				functionNamePrefix != "GRYAlternative" else
			{
				return try translate(
					asKotlinLiteral: callExpression,
					withFunctionNamePrefix: functionNamePrefix)
			}

			// A call to `GRYIgnoreNext()` can be used to ignore the next swift statement.
			guard functionNamePrefix != "GRYIgnoreNext" else {
				shouldIgnoreNext = true
				return ""
			}

			return try translate(
				asExplicitFunctionCall: callExpression,
				withFunctionNamePrefix: functionNamePrefix)
		}
	}

	/// Translates typical call expressions. The functionNamePrefix is passed as an argument here
	/// only because it has already been calculated by translate(callExpression:).
	private func translate(
		asExplicitFunctionCall callExpression: GRYAst,
		withFunctionNamePrefix functionNamePrefix: Substring) throws -> String
	{
		let functionNamePrefix = (functionNamePrefix == "print") ?
			"println" : String(functionNamePrefix)

		let parameters: String
		if let parenthesesExpression = callExpression.subTree(named: "Parentheses Expression") {
			parameters = try translate(expression: parenthesesExpression)
		}
		else if let tupleExpression = callExpression.subTree(named: "Tuple Expression") {
			parameters = try translate(tupleExpression: tupleExpression)
		}
		else if let tupleShuffleExpression = callExpression
			.subTree(named: "Tuple Shuffle Expression")
		{
			if let tupleExpression = tupleShuffleExpression.subTree(named: "Tuple Expression") {
				parameters = try translate(tupleExpression: tupleExpression)
			}
			else if let parenthesesExpression = tupleShuffleExpression
				.subTree(named: "Parentheses Expression")
			{
				parameters = try translate(expression: parenthesesExpression)
			}
			else {
				throw TranslationError.unknown
			}
		}
		else {
			throw TranslationError.unknown
		}

		return "\(functionNamePrefix)\(parameters)"
	}

	/// Translates boolean literals, which in swift are modeled as calls to specific builtin
	/// functions.
	private func translate(asBooleanLiteral callExpression: GRYAst) throws -> String {
		precondition(callExpression.name == "Call Expression")

		if let tupleExpression = callExpression.subTree(named: "Tuple Expression"),
			let booleanLiteralExpression = tupleExpression
				.subTree(named: "Boolean Literal Expression"),
			let value = booleanLiteralExpression["value"]
		{
			return value
		}
		else {
			throw TranslationError.unknown
		}
	}

	/// Translates numeric literals, which in swift are modeled as calls to specific builtin
	/// functions.
	private func translate(asNumericLiteral callExpression: GRYAst) throws -> String {
		precondition(callExpression.name == "Call Expression")

		if let tupleExpression = callExpression.subTree(named: "Tuple Expression"),
			let integerLiteralExpression = tupleExpression
				.subTree(named: "Integer Literal Expression"),
			let value = integerLiteralExpression["value"],

			let constructorReferenceCallExpression = callExpression
				.subTree(named: "Constructor Reference Call Expression"),
			let typeExpression = constructorReferenceCallExpression
				.subTree(named: "Type Expression"),
			let type = typeExpression["typerepr"]
		{
			if type == "Double" {
				return value + ".0"
			}
			else {
				return value
			}
		}
		else {
			throw TranslationError.unknown
		}
	}

	/**
	Translates functions that provide kotlin literals. There are two functions that
	can be declared in swift, `GRYInsert(_: String)` and
	`GRYAlternative<T>(swift: T, kotlin: String) -> T`, that allow a user to add
	literal kotlin code to the translation.
	
	The first one can be used to insert arbitrary kotlin statements in the middle
	of translated code, as in `GRYInsert("println(\"Hello, kotlin!\")")`.
	
	The second one can be used to provide a manual translation of a swift value, as in
	`let three = GRYAlternative(swift: sqrt(9), kotlin: "Math.sqrt(9.0)")`.
	*/
	private func translate(
		asKotlinLiteral callExpression: GRYAst,
		withFunctionNamePrefix functionNamePrefix: Substring) throws -> String
	{
		precondition(callExpression.name == "Call Expression")

		let parameterExpression: GRYAst

		if functionNamePrefix == "GRYAlternative",
			let unwrappedExpression = callExpression.subTree(named: "Tuple Expression")
		{
			parameterExpression = unwrappedExpression
		}
		else if functionNamePrefix == "GRYInsert",
			let unwrappedExpression = callExpression.subTree(named: "Parentheses Expression")
		{
			parameterExpression = unwrappedExpression
		}
		else {
			throw TranslationError.unknown
		}

		let stringExpression = try unwrapOrThrow(parameterExpression.subTrees.last)
		let string = try translate(stringLiteralExpression: stringExpression)

		let unquotedString = String(string.dropLast().dropFirst())
		let unescapedString = removeBackslashEscapes(unquotedString)
		return unescapedString
	}

	private func translate(declarationReferenceExpression: GRYAst) throws -> String {
		precondition(declarationReferenceExpression.name == "Declaration Reference Expression")

		if let codeDeclaration = declarationReferenceExpression.standaloneAttributes.first,
			codeDeclaration.hasPrefix("code.")
		{
			return getIdentifierFromDeclaration(codeDeclaration)
		}
		else if let declaration = declarationReferenceExpression["decl"] {
			return getIdentifierFromDeclaration(declaration)
		}
		else {
			throw TranslationError.unknown
		}
	}

	private func translate(memberReferenceExpression: GRYAst) throws -> String {
		precondition(memberReferenceExpression.name == "Member Reference Expression")

		if let declaration = memberReferenceExpression["decl"],
			let memberOwner = memberReferenceExpression.subTree(at: 0)
		{
			let memberOwnerString = try translate(expression: memberOwner)
			let member = getIdentifierFromDeclaration(declaration)
			return "\(memberOwnerString).\(member)"
		}
		else {
			throw TranslationError.unknown
		}
	}

	/**
	Recovers an identifier formatted as a swift AST declaration.
	
	Declaration references are represented in the swift AST Dump in a rather complex format, so a
	few operations are used to extract only the relevant identifier.
	
	For instance: a declaration reference expression referring to the variable `x`, inside the `foo`
	function, in the /Users/Me/Documents/myFile.swift file, will be something like
	`myFile.(file).foo().x@/Users/Me/Documents/MyFile.swift:2:6`, but a declaration reference for
	the print function doesn't have the '@' or anything after it.
	
	Note that this function's job (in the example above) is to extract only the actual `x`
	identifier.
	*/
	private func getIdentifierFromDeclaration(_ declaration: String) -> String {
		var index = declaration.startIndex
		var lastPeriodIndex = declaration.startIndex
		while index != declaration.endIndex {
			let character = declaration[index]

			if character == "." {
				lastPeriodIndex = index
			}
			if character == "@" {
				break
			}

			index = declaration.index(after: index)
		}

		let identifierStartIndex = declaration.index(after: lastPeriodIndex)

		let identifier = declaration[identifierStartIndex..<index]

		if identifier == "self" {
			return "this"
		}
		else {
			return String(identifier)
		}
	}

	private func translate(tupleExpression: GRYAst) throws -> String {
		precondition(tupleExpression.name == "Tuple Expression")

		// Only empty tuples don't have a list of names
		guard let names = tupleExpression["names"] else {
			return "()"
		}

		let namesArray = names.split(separator: ",")

		var result = [String]()

		for (name, expression) in zip(namesArray, tupleExpression.subTrees) {
			let expressionString = try translate(expression: expression)

			// Empty names (like the underscore in "foo(_:)") are represented by ''
			if name == "_" {
				result.append("\(expressionString)")
			}
			else {
				result.append("\(name) = \(expressionString)")
			}
		}

		return "(" + result.joined(separator: ", ") + ")"
	}

	private func translate(stringLiteralExpression: GRYAst) throws -> String {
		let value = try unwrapOrThrow(stringLiteralExpression["value"])
		return "\"\(value)\""
	}

	private func translate(interpolatedStringLiteralExpression: GRYAst) throws -> String {
		precondition(
			interpolatedStringLiteralExpression.name == "Interpolated String Literal Expression")

		var result = "\""

		for expression in interpolatedStringLiteralExpression.subTrees {
			if expression.name == "String Literal Expression" {
				let quotedString = try translate(stringLiteralExpression: expression)

				let unquotedString = quotedString.dropLast().dropFirst()

				// Empty strings, as a special case, are represented by the swift ast dump
				// as two double quotes with nothing between them, instead of an actual empty string
				guard unquotedString != "\"\"" else { continue }

				result += unquotedString
			}
			else {
				let expressionString = try translate(expression: expression)
				result += "${\(expressionString)}"
			}
		}

		result += "\""
		return result
	}

	private func removeBackslashEscapes(_ string: String) -> String {
		var result = ""

		var isEscaping = false
		for character in string {
			switch character {
			case "\\":
				if isEscaping {
					result.append(character)
					isEscaping = false
				}
				else {
					isEscaping = true
				}
			default:
				result.append(character)
				isEscaping = false
			}
		}

		return result
	}

	private func ASTIsExpression(_ ast: GRYAst) -> Bool {
		return ast.name.hasSuffix("Expression") || ast.name == "Inject Into Optional"
	}

	func increaseIndentation(_ indentation: String) -> String {
		return indentation + "\t"
	}

	func decreaseIndentation(_ indentation: String) -> String {
		return String(indentation.dropLast())
	}

	func code(for error: Error, inASTNamed astName: String) -> String {
		guard let translationError = error as? TranslationError else {
			// Methods in this class should only throw `TranslationError`s.
			// If the thrown error isn't a `TranslationError`, something unexpected happened.
			fatalError("Unkown error!")
		}

		switch translationError {
		case .refactorable:
			return "<⚠️ Refactorable: \(astName)>"
		case .unknown:
			return "<🚨 Unknown: \(astName)>"
		}
	}
}

extension String {
	var capitalizedAsCamelCase: String {
		let firstCharacter = self.first!
		let capitalizedFirstCharacter = String(firstCharacter).uppercased()
		return String(capitalizedFirstCharacter + self.dropFirst())
	}
}
