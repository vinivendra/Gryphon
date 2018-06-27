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
	public class Diagnostics: CustomStringConvertible {
        private(set) var translatedSubtrees = GRYHistogram<String>()
		private(set) var refactorableSubtrees = GRYHistogram<String>()
        private(set) var unknownSubtrees = GRYHistogram<String>()

		fileprivate func logSuccessfulTranslation(_ subtreeName: String) {
			translatedSubtrees.increaseOccurence(of: subtreeName)
		}

        fileprivate func logRefactorableTranslation(_ subtreeName: String) {
            refactorableSubtrees.increaseOccurence(of: subtreeName)
        }

        fileprivate func logUnknownTranslation(_ subtreeName: String) {
            unknownSubtrees.increaseOccurence(of: subtreeName)
        }

		fileprivate func logResult(_ translationResult: TranslationResult, subtreeName: String) {
			if case .translation(_) = translationResult {
				logSuccessfulTranslation(subtreeName)
			}
			else {
				logUnknownTranslation(subtreeName)
			}
		}

		public var description: String {
			return """
			-----
			# Kotlin translation diagnostics:

			## Translated subtrees

			\(translatedSubtrees)
			## Refactorable subtrees

			\(refactorableSubtrees)
			## Unknown subtrees

			\(unknownSubtrees)
			"""
		}
	}

	/// Records the amount of translations that have been successfully translated;
	/// that can be refactored into translatable code; or that can't be translated.
	var diagnostics: Diagnostics?

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
	public func translateAST(_ ast: GRYAst) -> String? {
		// First, translate declarations that shouldn't be inside the main function
		let declarationNames = [
			"Class Declaration",
			"Extension Declaration",
			"Function Declaration",
			"Enum Declaration",
		]
		let isDeclaration = { (ast: GRYAst) -> Bool in declarationNames.contains(ast.name) }

		let declarations = ast.subtrees.filter(isDeclaration)
		let declarationsTranslation = translate(subtrees: declarations, withIndentation: "")

		// Then, translate the remaining statements (if there are any) and wrap them in the main
		// function
		let indentation = increaseIndentation("")
		let statements = ast.subtrees.filter({ !isDeclaration($0) })
		let statementsTranslation = translate(subtrees: statements, withIndentation: indentation)

		guard case .translation(let statementsString) = statementsTranslation,
			case .translation(var declarationsString) = declarationsTranslation else
		{
			return nil
		}

		if statementsString.isEmpty {
			return declarationsString
		}

		// Add newline between declarations and the main function, if needed
		if !declarationsString.isEmpty {
			declarationsString += "\n"
		}

		declarationsString += "fun main(args: Array<String>) {\n\(statementsString)}\n"

		return declarationsString
	}

	// MARK: - Implementation

	// TODO: Make sure these methods only throw when they themselves can't be translated.
	private func translate(subtree: GRYAst, withIndentation indentation: String)
		-> TranslationResult
	{
		let result: TranslationResult

		switch subtree.name {
		case "Import Declaration":
			result = .translation("")
		case "Class Declaration":
			result = translate(
				classDeclaration: subtree,
				withIndentation: indentation)
		case "Constructor Declaration":
			result = translate(
				constructorDeclaration: subtree,
				withIndentation: indentation)
		case "Destructor Declaration":
			result = translate(
				destructorDeclaration: subtree,
				withIndentation: indentation)
		case "Enum Declaration":
			result = translate(
				enumDeclaration: subtree,
				withIndentation: indentation)
		case "Extension Declaration":
			result = translate(
				subtrees: subtree.subtrees,
				withIndentation: indentation)
		case "For Each Statement":
			result = translate(
				forEachStatement: subtree,
				withIndentation: indentation)
		case "Function Declaration":
			result = translate(
				functionDeclaration: subtree,
				withIndentation: indentation)
		case "Protocol":
			result = translate(
				protocolDeclaration: subtree,
				withIndentation: indentation)
		case "Top Level Code Declaration":
			return translate(
				topLevelCode: subtree,
				withIndentation: indentation)
		case "Throw Statement":
			result = translate(
				throwStatement: subtree,
				withIndentation: indentation)
		case "Variable Declaration":
			result = translate(
				variableDeclaration: subtree,
				withIndentation: indentation)
		case "Assign Expression":
			result = translate(
				assignExpression: subtree,
				withIndentation: indentation)
		case "Guard Statement":
			result = translate(
				ifStatement: subtree,
				asGuard: true,
				withIndentation: indentation)
		case "If Statement":
			result = translate(
				ifStatement: subtree,
				withIndentation: indentation)
		case "Pattern Binding Declaration":
			result = process(patternBindingDeclaration: subtree)
		case "Return Statement":
			result = translate(
				returnStatement: subtree,
				withIndentation: indentation)
		case "Call Expression":
			if case .translation(let string) = translate(callExpression: subtree) {
				if !string.isEmpty {
					result = .translation(indentation + string + "\n")
				}
				else {
					// GRYIgnoreNext() results in an empty translation
					result = .translation("")
				}
			}
			else {
				result = .failed
			}
		default:
			if subtree.name.hasSuffix("Expression") {
				if case .translation(let string) = translate(expression: subtree) {
					result = .translation(indentation + string + "\n")
				}
				else {
					result = .failed
				}
			}
			else {
				result = .failed
			}
		}

		return result
	}

	private func translate(subtrees: [GRYAst], withIndentation indentation: String)
		-> TranslationResult
	{
		var result = TranslationResult.translation("")

		for subtree in subtrees {
			if shouldIgnoreNext {
				shouldIgnoreNext = false
				continue
			}

			result += translate(subtree: subtree, withIndentation: indentation)
		}

		return result
	}

	private func process(patternBindingDeclaration: GRYAst) -> TranslationResult {
		precondition(patternBindingDeclaration.name == "Pattern Binding Declaration")

		// Some patternBindingDeclarations are empty, and that's ok. See the classes.swift test
		// case.
		guard let expression = patternBindingDeclaration.subtrees.last,
			ASTIsExpression(expression) else { return .translation("") }

		let binding: GRYAst

		if let unwrappedBinding = patternBindingDeclaration
			.subtree(named: "Pattern Typed")?
			.subtree(named: "Pattern Named")
		{
			binding = unwrappedBinding
		}
		else if let unwrappedBinding = patternBindingDeclaration.subtree(named: "Pattern Named") {
			binding = unwrappedBinding
		}
		else {
			return .failed
		}

		guard let identifier = binding.standaloneAttributes.first,
			let rawType = binding.keyValueAttributes["type"] else
		{
			return .failed
		}

		let type = translateType(rawType)

		danglingPatternBinding =
			(identifier: identifier,
			 type: type,
			 translatedExpression: translate(expression: expression).stringValue!)

		return .translation("")
	}

	private func translate(topLevelCode: GRYAst, withIndentation indentation: String)
		-> TranslationResult
	{
		precondition(topLevelCode.name == "Top Level Code Declaration")

		guard let braceStatement = topLevelCode.subtree(named: "Brace Statement") else {
			return .failed
		}

		return translate(subtrees: braceStatement.subtrees, withIndentation: indentation)
	}

	private func translate(enumDeclaration: GRYAst, withIndentation indentation: String)
		-> TranslationResult
	{
		precondition(enumDeclaration.name == "Enum Declaration")

		guard let enumName = enumDeclaration.standaloneAttributes.first else {
			return .failed
		}

		GRYKotlinTranslator.enums.append(enumName)

		var result = TranslationResult.translation("")

		if let inheritanceList = enumDeclaration.keyValueAttributes["inherits"],
			let access = enumDeclaration.keyValueAttributes["access"]
		{
			let rawInheritanceArray = inheritanceList.split(withStringSeparator: ", ")

			if rawInheritanceArray.contains("GRYIgnore") {
				return .translation("")
			}

			var inheritanceArray = rawInheritanceArray.map { translateType($0) }

			// The inheritanceArray isn't empty because the inheritanceList isn't empty.
			inheritanceArray[0] = inheritanceArray[0] + "()"

			let inheritanceString = inheritanceArray.joined(separator: ", ")

			result += "\(indentation)\(access) sealed class \(enumName): \(inheritanceString) {\n"
		}

		let increasedIndentation = increaseIndentation(indentation)

		let enumElementDeclarations =
			enumDeclaration.subtrees.filter { $0.name == "Enum Element Declaration" }
		for enumElementDeclaration in enumElementDeclarations {
			guard let elementName = enumElementDeclaration.standaloneAttributes.first else {
				result = .failed
				continue
			}

			let capitalizedElementName = elementName.capitalizedAsCamelCase

			diagnostics?.logSuccessfulTranslation("[Enum Element Declaration]")
			result += "\(increasedIndentation)class \(capitalizedElementName): \(enumName)()\n"
		}

		result += "\(indentation)}\n"

		return result
	}

	private func translate(protocolDeclaration: GRYAst, withIndentation indentation: String)
		-> TranslationResult
	{
		precondition(protocolDeclaration.name == "Protocol")

		guard let protocolName = protocolDeclaration.standaloneAttributes.first else {
			return .failed
		}

		if protocolName == "GRYIgnore" {
			return .translation("")
		}
		else {
			// Add actual protocol translation here
			return .failed
		}
	}

	private func translate(classDeclaration: GRYAst, withIndentation indentation: String)
		-> TranslationResult
	{
		precondition(classDeclaration.name == "Class Declaration")

		// Get the class name
		let classNameTranslation: TranslationResult
		if let className = classDeclaration.standaloneAttributes.first {
			classNameTranslation = .translation(className)
		}
		else {
			classNameTranslation = .failed
		}

		// Check for inheritance
		let inheritanceString: String
		if let inheritanceList = classDeclaration.keyValueAttributes["inherits"] {
			let rawInheritanceArray = inheritanceList.split(withStringSeparator: ", ")

			// If it inherits from GRYIgnore, we ignore it.
			if rawInheritanceArray.contains("GRYIgnore") {
				return .translation("")
			}

			let inheritanceArray = rawInheritanceArray.map { translateType($0) }
			inheritanceString = ": \(inheritanceArray.joined(separator: ", "))"
		}
		else {
			inheritanceString = ""
		}

		let increasedIndentation = increaseIndentation(indentation)

		// Translate the contents
		let classContents = translate(
			subtrees: classDeclaration.subtrees,
			withIndentation: increasedIndentation)

		return "class " + classNameTranslation + inheritanceString + " {\n" + classContents + "}\n"
	}

	private func translate(constructorDeclaration: GRYAst, withIndentation indentation: String)
		-> TranslationResult
	{
		precondition(constructorDeclaration.name == "Constructor Declaration")

		guard !constructorDeclaration.standaloneAttributes.contains("implicit") else {
			return .translation("")
		}

		return .failed
	}

	private func translate(destructorDeclaration: GRYAst, withIndentation indentation: String)
		-> TranslationResult
	{
		precondition(destructorDeclaration.name == "Destructor Declaration")

		guard !destructorDeclaration.standaloneAttributes.contains("implicit") else {
			return .translation("")
		}

		return .failed
	}

	private func translate(functionDeclaration: GRYAst, withIndentation indentation: String)
		-> TranslationResult
	{
		precondition(functionDeclaration.name == "Function Declaration")

		// Getters and setters will appear again in the Variable Declaration AST and get translated
		let isGetterOrSetter =
			(functionDeclaration["getter_for"] != nil) || (functionDeclaration["setter_for"] != nil)
		let isImplicit = functionDeclaration.standaloneAttributes.contains("implicit")
		guard !isImplicit && !isGetterOrSetter else {
			return .translation("")
		}

		let functionName = functionDeclaration.standaloneAttributes.first ?? ""

		// If this function should be ignored
		guard !functionName.hasPrefix("GRYInsert(") &&
			!functionName.hasPrefix("GRYAlternative(") &&
			!functionName.hasPrefix("GRYIgnoreNext(") else { return .translation("") }

		// If it's GRYDeclarations, we want to add its contents as top-level statements
		guard !functionName.hasPrefix("GRYDeclarations(") else {
			if let braceStatement = functionDeclaration.subtree(named: "Brace Statement") {
				return translate(subtrees: braceStatement.subtrees, withIndentation: indentation)
			}
			else {
				return .failed
			}
		}

		var indentation = indentation
		var result = TranslationResult.translation("")

		result += indentation

		if let access = functionDeclaration["access"] {
			result += access + " "
		}

		result += "fun "

		let functionNamePrefix = functionName.prefix { $0 != "(" }

		result += functionNamePrefix + "("

		// Get the function parameters.
		var parameterStrings = [String?]()
		let parameterList: GRYAst?

		// If it's a method, it includes an extra Parameter List with only `self`
		if let list = functionDeclaration.subtree(named: "Parameter List"),
			let name = list.subtree(at: 0, named: "Parameter")?.standaloneAttributes.first,
			name != "self"
		{
			parameterList = list
		}
		else if let unwrapped = functionDeclaration.subtree(at: 1, named: "Parameter List") {
			parameterList = unwrapped
		}
		else {
			parameterList = nil
		}

		// Translate the parameters
		if let parameterList = parameterList {
			for parameter in parameterList.subtrees {
				if let name = parameter.standaloneAttributes.first,
					let rawType = parameter["interface type"]
				{
					guard name != "self" else { continue }

					let type = translateType(rawType)
					parameterStrings.append(name + ": " + type)
				}
				else {
					parameterStrings.append(nil)
				}
			}
		}

		let parameters: [String]
		if let parameterStrings = parameterStrings as? [String] {
			parameters = parameterStrings
		}
		else {
			parameters = []
			result = .failed
		}

		result += parameters.joined(separator: ", ")

		result += ")"

		// Translate the return type
		// TODO: Doesn't allow to return function types
		if let rawType = functionDeclaration["interface type"]?
			.split(withStringSeparator: " -> ").last
		{
			let returnType = translateType(rawType)
			if returnType != "()" {
				result += ": " + returnType
			}
		}
		else {
			result = .failed
		}

		result += " {\n"

		// Translate the function body
		indentation = increaseIndentation(indentation)
		if let braceStatement = functionDeclaration.subtree(named: "Brace Statement") {
			result += translate(subtrees: braceStatement.subtrees, withIndentation: indentation)
		}
		else {
			result += .failed
		}

		indentation = decreaseIndentation(indentation)
		result += indentation + "}\n"

		return result
	}

	private func translate(forEachStatement: GRYAst, withIndentation indentation: String)
		-> TranslationResult
	{
		precondition(forEachStatement.name == "For Each Statement")

		var result = TranslationResult.translation("")

		guard let braceStatement = forEachStatement.subtrees.last,
			braceStatement.name == "Brace Statement" else {
				return .failed
		}

		if let variableName = forEachStatement
				.subtree(named: "Pattern Named")?
				.standaloneAttributes.first,
			let collectionExpression = forEachStatement.subtree(at: 2),
			let collectionString = translate(expression: collectionExpression).stringValue
		{
			result += .translation("\(indentation)for (\(variableName) in \(collectionString))")
		}
		else {
			result = .failed
		}

		let increasedIndentation = increaseIndentation(indentation)
		let statements = translate(
			subtrees: braceStatement.subtrees,
			withIndentation: increasedIndentation)

		result += " {\n" + statements + indentation + "}\n"

		return result
	}

	private func translate(
		ifStatement: GRYAst,
		asElseIf isElseIf: Bool = false,
		asGuard isGuard: Bool = false,
		withIndentation indentation: String) -> TranslationResult
	{
		precondition(ifStatement.name == "If Statement" || ifStatement.name == "Guard Statement")

		let (letDeclarations, conditions) = translateDeclarationsAndConditions(
			forIfStatement: ifStatement,
			withIndentation: indentation)

		let increasedIndentation = increaseIndentation(indentation)

		var elseIfTranslation = TranslationResult.translation("")
		var elseTranslation = TranslationResult.translation("")
		let braceStatement: GRYAst

		if ifStatement.subtrees.count > 2,
			let unwrappedBraceStatement = ifStatement.subtrees.secondToLast,
			unwrappedBraceStatement.name == "Brace Statement",
			let elseIfAST = ifStatement.subtrees.last,
			elseIfAST.name == "If Statement"
		{
			braceStatement = unwrappedBraceStatement

			elseIfTranslation =
				translate(ifStatement: elseIfAST, asElseIf: true, withIndentation: indentation)
		}
		else if ifStatement.subtrees.count > 2,
			let unwrappedBraceStatement = ifStatement.subtrees.secondToLast,
			unwrappedBraceStatement.name == "Brace Statement",
			let elseAST = ifStatement.subtrees.last,
			elseAST.name == "Brace Statement"
		{
			braceStatement = unwrappedBraceStatement

			let statementsString =
				translate(subtrees: elseAST.subtrees, withIndentation: increasedIndentation)
			elseTranslation =
				.translation("\(indentation)else {\n") + statementsString + "\(indentation)}\n"
		}
		else if let unwrappedBraceStatement = ifStatement.subtrees.last,
			unwrappedBraceStatement.name == "Brace Statement"
		{
			braceStatement = unwrappedBraceStatement
		}
		else {
			return .failed
		}

		let statements = braceStatement.subtrees
		let statementsString =
			translate(subtrees: statements, withIndentation: increasedIndentation)

		let keyword = isElseIf ? "else if" : "if"
		let parenthesizedCondition = isGuard ?
			TranslationResult.translation("(!(") + conditions + "))" :
			TranslationResult.translation("(") + conditions + ")"

		let ifTranslation = letDeclarations
			+ indentation + keyword + " " + parenthesizedCondition + " {\n"
			+ statementsString
			+ indentation + "}\n"

		return ifTranslation + elseIfTranslation + elseTranslation
	}

	/// Failures in translating if-let conditions get counted as failures in conditions
	/// and their corresponding let declaration never gets created
	private func translateDeclarationsAndConditions(
		forIfStatement ifStatement: GRYAst,
		withIndentation indentation: String)
		-> (letDeclarationsString: TranslationResult, conditionString: TranslationResult)
	{
		precondition(ifStatement.name == "If Statement" || ifStatement.name == "Guard Statement")

		var conditionStrings = [String?]()
		var letDeclarations = [String]()

		let conditions = ifStatement.subtrees.filter {
			$0.name != "If Statement" && $0.name != "Brace Statement"
		}

		for condition in conditions {
			// If it's an if-let
			if condition.name == "Pattern",
				let optionalSomeElement = condition.subtree(named: "Optional Some Element")
			{
				let patternNamed: GRYAst
				let varOrValKeyword: String
				if let patternLet = optionalSomeElement.subtree(named: "Pattern Let"),
					let unwrapped = patternLet.subtree(named: "Pattern Named")
				{
					patternNamed = unwrapped
					varOrValKeyword = "val"
				}
				else if let unwrapped = optionalSomeElement
					.subtree(named: "Pattern Variable")?
					.subtree(named: "Pattern Named")
				{
					patternNamed = unwrapped
					varOrValKeyword = "var"
				}
				else {
					diagnostics?.logUnknownTranslation("If-let")
					conditionStrings.append(nil)
					continue
				}

				let typeString: String
				if let rawType = optionalSomeElement["type"] {
					let type = translateType(rawType)
					typeString = ": \(type)"
				}
				else {
					typeString = ""
				}

				guard let name = patternNamed.standaloneAttributes.first,
					let lastCondition = condition.subtrees.last,
					let expressionString = translate(expression: lastCondition).stringValue else
				{
					diagnostics?.logUnknownTranslation("If-let")
					conditionStrings.append(nil)
					continue
				}

				diagnostics?.logSuccessfulTranslation("If-let")
				letDeclarations.append(
					"\(indentation)\(varOrValKeyword) \(name)\(typeString) = \(expressionString)\n")
				conditionStrings.append("\(name) != null")
			}
			else {
				conditionStrings.append(translate(expression: condition).stringValue)
			}
		}

		if let conditionStrings = conditionStrings as? [String] {
			let conditionString = conditionStrings.joined(separator: " && ")
			let letDeclarationsString = letDeclarations.joined()
			return (.translation(letDeclarationsString), .translation(conditionString))
		}
		else {
			return (.failed, .failed)
		}
	}

	private func translate(
		throwStatement: GRYAst,
		withIndentation indentation: String) -> TranslationResult
	{
		precondition(throwStatement.name == "Throw Statement")

		guard let expression = throwStatement.subtrees.last,
			let expressionString = translate(expression: expression).stringValue else
		{
			diagnostics?.logUnknownTranslation(throwStatement.name)
			return .failed
		}

		diagnostics?.logSuccessfulTranslation(throwStatement.name)
		return .translation("\(indentation)throw \(expressionString)\n")
	}

	private func translate(
		returnStatement: GRYAst,
		withIndentation indentation: String) -> TranslationResult
	{
		precondition(returnStatement.name == "Return Statement")

		if let expression = returnStatement.subtrees.last {
			if let expressionString = translate(expression: expression).stringValue {
				diagnostics?.logSuccessfulTranslation(returnStatement.name)
				return .translation("\(indentation)return \(expressionString)\n")
			}
			else {
				diagnostics?.logUnknownTranslation(returnStatement.name)
				return .failed
			}
		}
		else {
			diagnostics?.logSuccessfulTranslation(returnStatement.name)
			return .translation("\(indentation)return\n")
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
		-> TranslationResult
	{
		precondition(variableDeclaration.name == "Variable Declaration")

		var result = TranslationResult.translation(indentation)

		if let identifier = variableDeclaration.standaloneAttributes.first,
			let rawType = variableDeclaration["interface type"]
		{
			let type = translateType(rawType)

			let hasGetter = variableDeclaration.subtrees.contains(where:
			{ (subtree: GRYAst) -> Bool in
				return subtree.name == "Function Declaration" &&
					!subtree.standaloneAttributes.contains("implicit") &&
					subtree.keyValueAttributes["getter_for"] != nil
			})
			let hasSetter = variableDeclaration.subtrees.contains(where:
			{ (subtree: GRYAst) -> Bool in
				return subtree.name == "Function Declaration" &&
					!subtree.standaloneAttributes.contains("implicit") &&
					subtree.keyValueAttributes["setter_for"] != nil
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

			result += translateGetterAndSetter(
				forVariableDeclaration: variableDeclaration,
				withIndentation: indentation)

			diagnostics?.logResult(result, subtreeName: variableDeclaration.name)
			return result
		}
		else {
			diagnostics?.logUnknownTranslation(variableDeclaration.name)
			return .failed
		}
	}

	private func translateGetterAndSetter(
		forVariableDeclaration variableDeclaration: GRYAst,
		withIndentation indentation: String) -> TranslationResult
	{
		var result = TranslationResult.translation("")

		let getSetIndentation = increaseIndentation(indentation)
		for subtree in variableDeclaration.subtrees
			where !subtree.standaloneAttributes.contains("implicit")
		{
			assert(subtree.name == "Function Declaration")

			var subResult = TranslationResult.translation("")

			let keyword: String

			if subtree["getter_for"] != nil {
				keyword = "get()"
			}
			else {
				keyword = "set(newValue)"
			}

			subResult += "\(getSetIndentation)\(keyword) {\n"

			let contentsIndentation = increaseIndentation(getSetIndentation)

			guard let statements = subtree.subtree(named: "Brace Statement")?.subtrees else {
				result = .failed
				continue
			}

			let contentsString =
				translate(subtrees: statements, withIndentation: contentsIndentation)
			subResult += contentsString

			subResult += "\(getSetIndentation)}\n"

			diagnostics?.logResult(subResult, subtreeName: "Getter/Setter")
			result += subResult
		}

		return result
	}

	private func translate(assignExpression: GRYAst, withIndentation indentation: String)
		-> TranslationResult
	{
		precondition(assignExpression.name == "Assign Expression")

		if let leftExpression = assignExpression.subtree(at: 0),
			let rightExpression = assignExpression.subtree(at: 1)
		{
			let leftTranslation = translate(expression: leftExpression)
			let rightTranslation = translate(expression: rightExpression)

			guard let leftString = leftTranslation.stringValue,
				let rightString = rightTranslation.stringValue else
			{
				diagnostics?.logUnknownTranslation(assignExpression.name)
				return .failed
			}

			diagnostics?.logSuccessfulTranslation(assignExpression.name)
			return .translation("\(indentation)\(leftString) = \(rightString)\n")
		}
		else {
			diagnostics?.logUnknownTranslation(assignExpression.name)
			return.failed
		}
	}

	private func translate(expression: GRYAst) -> TranslationResult {
		// Most diagnostics are logged by the child subTrees; others represent wrapper expressions
		// with little value in logging. There are a few expections.

		switch expression.name {
		case "Array Expression":
			return translate(arrayExpression: expression)
		case "Binary Expression":
			return translate(binaryExpression: expression)
		case "Call Expression":
			return translate(callExpression: expression)
		case "Declaration Reference Expression":
			return translate(declarationReferenceExpression: expression)
		case "Dot Syntax Call Expression":
			return translate(dotSyntaxCallExpression: expression)
		case "String Literal Expression":
			return translate(stringLiteralExpression: expression)
		case "Interpolated String Literal Expression":
			return translate(interpolatedStringLiteralExpression: expression)
		case "Erasure Expression":
			if let lastExpression = expression.subtrees.last {
				return translate(expression: lastExpression)
			}
			else {
				return .failed
			}
		case "Prefix Unary Expression":
			return translate(prefixUnaryExpression: expression)
		case "Type Expression":
			return translate(typeExpression: expression)
		case "Member Reference Expression":
			return translate(memberReferenceExpression: expression)
		case "Subscript Expression":
			return translate(subscriptExpression: expression)
		case "Parentheses Expression":
			if let firstExpression = expression.subtree(at: 0),
				let expressionString = translate(expression: firstExpression).stringValue
			{
				diagnostics?.logSuccessfulTranslation(expression.name)
				return .translation("(" + expressionString + ")")
			}
			else {
				diagnostics?.logUnknownTranslation(expression.name)
				return .failed
			}
		case "Force Value Expression":
			if let firstExpression = expression.subtree(at: 0),
				let expressionString = translate(expression: firstExpression).stringValue
			{
				diagnostics?.logSuccessfulTranslation(expression.name)
				return .translation(expressionString  + "!!")
			}
			else {
				diagnostics?.logUnknownTranslation(expression.name)
				return .failed
			}
		case "Autoclosure Expression",
			 "Inject Into Optional",
			 "Inout Expression",
			 "Load Expression":
			if let lastExpression = expression.subtrees.last {
				return translate(expression: lastExpression)
			}
			else {
				return .failed
			}
		default:
			return .failed
		}
	}

	private func translate(typeExpression: GRYAst) -> TranslationResult {
		precondition(typeExpression.name == "Type Expression")

		if let rawType = typeExpression.keyValueAttributes["typerepr"] {
			diagnostics?.logSuccessfulTranslation(typeExpression.name)
			return .translation(translateType(rawType))
		}
		else {
			diagnostics?.logUnknownTranslation(typeExpression.name)
			return .failed
		}
	}

	private func translate(subscriptExpression: GRYAst) -> TranslationResult {
		precondition(subscriptExpression.name == "Subscript Expression")

		if let parenthesesExpression = subscriptExpression.subtree(
			at: 1,
			named: "Parentheses Expression"),
			let subscriptContents = parenthesesExpression.subtree(at: 0),
			let subscriptedExpression = subscriptExpression.subtree(at: 0)
		{
			let subscriptContentsTranslation = translate(expression: subscriptContents)
			let subscriptedExpressionTranslation = translate(expression: subscriptedExpression)

			guard let subscriptContentsString = subscriptContentsTranslation.stringValue,
				let subscriptedExpressionString = subscriptedExpressionTranslation.stringValue else
			{
				diagnostics?.logUnknownTranslation(subscriptExpression.name)
				return .failed
			}

			diagnostics?.logSuccessfulTranslation(subscriptExpression.name)
			return .translation("\(subscriptedExpressionString)[\(subscriptContentsString)]")
		}
		else {
			diagnostics?.logUnknownTranslation(subscriptExpression.name)
			return .failed
		}
	}

	private func translate(arrayExpression: GRYAst) -> TranslationResult {
		precondition(arrayExpression.name == "Array Expression")

		let expressionsArray = arrayExpression.subtrees.map {
			translate(expression: $0).stringValue
		}

		if let expressionsArray = expressionsArray as? [String] {
			let expressionsString = expressionsArray.joined(separator: ", ")

			diagnostics?.logSuccessfulTranslation(arrayExpression.name)
			return .translation("mutableListOf(\(expressionsString))")
		}
		else {
			diagnostics?.logUnknownTranslation(arrayExpression.name)
			return .failed
		}
	}

	private func translate(dotSyntaxCallExpression: GRYAst) -> TranslationResult {
		precondition(dotSyntaxCallExpression.name == "Dot Syntax Call Expression")

		if let leftHandTree = dotSyntaxCallExpression.subtree(at: 1),
			let rightHandExpression = dotSyntaxCallExpression.subtree(at: 0)
		{
			let rightHandTranslation = translate(expression: rightHandExpression)
			let leftHandTranslation = translate(typeExpression: leftHandTree)

			guard let leftHandString = leftHandTranslation.stringValue,
				let rightHandString = rightHandTranslation.stringValue else
			{
				diagnostics?.logUnknownTranslation(dotSyntaxCallExpression.name)
				return .failed
			}

			// Enums become sealed classes, which need parentheses at the end
			if GRYKotlinTranslator.enums.contains(leftHandString) {
				let capitalizedEnumCase = rightHandString.capitalizedAsCamelCase

				diagnostics?.logSuccessfulTranslation(dotSyntaxCallExpression.name)
				return .translation("\(leftHandString).\(capitalizedEnumCase)()")
			}
			else {
				diagnostics?.logSuccessfulTranslation(dotSyntaxCallExpression.name)
				return .translation("\(leftHandString).\(rightHandString)")
			}
		}

		diagnostics?.logUnknownTranslation(dotSyntaxCallExpression.name)
		return .failed
	}

	private func translate(binaryExpression: GRYAst) -> TranslationResult {
		precondition(binaryExpression.name == "Binary Expression")

		let operatorIdentifier: String

		if let declaration = binaryExpression
				.subtree(named: "Dot Syntax Call Expression")?
				.subtree(named: "Declaration Reference Expression")?["decl"],
			let tupleExpression = binaryExpression.subtree(named: "Tuple Expression"),
			let leftHandExpression = tupleExpression.subtree(at: 0),
			let rightHandExpression = tupleExpression.subtree(at: 1)
		{
			operatorIdentifier = getIdentifierFromDeclaration(declaration)
			let leftHandTranslation = translate(expression: leftHandExpression)
			let rightHandTranslation = translate(expression: rightHandExpression)

			var result = leftHandTranslation
			result += " \(operatorIdentifier) "
			result += rightHandTranslation

			diagnostics?.logResult(result, subtreeName: binaryExpression.name)
			return result
		}
		else {
			diagnostics?.logUnknownTranslation(binaryExpression.name)
			return .failed
		}
	}

	private func translate(prefixUnaryExpression: GRYAst) -> TranslationResult {
		precondition(prefixUnaryExpression.name == "Prefix Unary Expression")

		if let declaration = prefixUnaryExpression
				.subtree(named: "Dot Syntax Call Expression")?
				.subtree(named: "Declaration Reference Expression")?["decl"],
			let expression = prefixUnaryExpression.subtree(at: 1),
			let expressionString = translate(expression: expression).stringValue
		{
			let operatorIdentifier = getIdentifierFromDeclaration(declaration)

			diagnostics?.logSuccessfulTranslation(prefixUnaryExpression.name)
			return .translation("\(operatorIdentifier)\(expressionString)")
		}
		else {
			diagnostics?.logUnknownTranslation(prefixUnaryExpression.name)
			return .failed
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
	private func translate(callExpression: GRYAst) -> TranslationResult {
		precondition(callExpression.name == "Call Expression")

		// If the call expression corresponds to an integer literal
		if let argumentLabels = callExpression["arg_labels"],
			argumentLabels == "_builtinIntegerLiteral:"
		{
			diagnostics?.logSuccessfulTranslation(callExpression.name)
			return translate(asNumericLiteral: callExpression)
		}
		// If the call expression corresponds to an boolean literal
		else if let argumentLabels = callExpression["arg_labels"],
			argumentLabels == "_builtinBooleanLiteral:"
		{
			diagnostics?.logSuccessfulTranslation(callExpression.name)
			return translate(asBooleanLiteral: callExpression)
		}
		// If the call expression corresponds to `nil`
		else if let argumentLabels = callExpression["arg_labels"],
			argumentLabels == "nilLiteral:"
		{
			diagnostics?.logSuccessfulTranslation(callExpression.name)
			return .translation("null")
		}
		else {
			// If it's an empty expression used in an "if" condition
			if callExpression.standaloneAttributes.contains("implicit"),
				callExpression["arg_labels"] == "",
				callExpression["type"] == "Int1",
				let containedExpression = callExpression
					.subtree(named: "Dot Syntax Call Expression")?
					.subtrees.last
			{
				if let result = translate(expression: containedExpression).stringValue {
					return .translation(result)
				}
				else {
					diagnostics?.logUnknownTranslation(callExpression.name)
					return .failed
				}
			}

			let functionName: String
			var result = TranslationResult.translation("")

			if let declarationReferenceExpression = callExpression
				.subtree(named: "Declaration Reference Expression")
			{
				if let string = translate(
					declarationReferenceExpression: declarationReferenceExpression).stringValue
				{
					functionName = string
				}
				else {
					result = .failed
					functionName = ""
				}
			}
			else if let dotSyntaxCallExpression = callExpression
					.subtree(named: "Dot Syntax Call Expression"),
				let methodName = dotSyntaxCallExpression
					.subtree(at: 0, named: "Declaration Reference Expression"),
				let methodOwner = dotSyntaxCallExpression.subtree(at: 1)
			{
				if let methodNameString =
						translate(declarationReferenceExpression: methodName).stringValue,
					let methodOwnerString = translate(expression: methodOwner).stringValue
				{
					functionName = "\(methodOwnerString).\(methodNameString)"
				}
				else {
					result = .failed
					functionName = ""
				}
			}
			else if let typeExpression = callExpression
				.subtree(named: "Constructor Reference Call Expression")?
				.subtree(named: "Type Expression")
			{
				if let string = translate(typeExpression: typeExpression).stringValue {
					functionName = string
				}
				else {
					result = .failed
					functionName = ""
				}
			}
			else if let declaration = callExpression["decl"] {
				functionName = getIdentifierFromDeclaration(declaration)
			}
			else {
				result = .failed
				functionName = ""
			}

			let functionNamePrefix = functionName.prefix(while: { $0 != "(" })

			// If it's a special Gryphon directive
			if result != .failed {
				if functionNamePrefix == "GRYInsert" || functionNamePrefix == "GRYAlternative" {
					diagnostics?.logSuccessfulTranslation(callExpression.name)
					return translate(
						asKotlinLiteral: callExpression,
						withFunctionNamePrefix: functionNamePrefix)
				}
				else if functionNamePrefix == "GRYIgnoreNext" {
					shouldIgnoreNext = true
					diagnostics?.logSuccessfulTranslation(callExpression.name)
					return .translation("")
				}
			}

			// Otherwise, translate it as an explicit function call
			guard let translation = translate(
				asExplicitFunctionCall: callExpression,
				withFunctionNamePrefix: functionNamePrefix).stringValue else
			{
				diagnostics?.logUnknownTranslation(callExpression.name)
				return .failed
			}

			result += translation

			diagnostics?.logSuccessfulTranslation(callExpression.name)
			return result
		}
	}

	/// Translates typical call expressions. The functionNamePrefix is passed as an argument here
	/// only because it has already been calculated by translate(callExpression:).
	///
	/// Diagnostics get logged at caller (`translate(callExpression:)`).
	private func translate(
		asExplicitFunctionCall callExpression: GRYAst,
		withFunctionNamePrefix functionNamePrefix: Substring) -> TranslationResult
	{
		let functionNamePrefix = (functionNamePrefix == "print") ?
			"println" : String(functionNamePrefix)

		let parameters: String
		if let parenthesesExpression = callExpression.subtree(named: "Parentheses Expression"),
			let parametersString = translate(expression: parenthesesExpression).stringValue
		{
			parameters = parametersString
		}
		else if let tupleExpression = callExpression.subtree(named: "Tuple Expression"),
			let parametersString = translate(tupleExpression: tupleExpression).stringValue
		{
			parameters = parametersString
		}
		else if let tupleShuffleExpression = callExpression
			.subtree(named: "Tuple Shuffle Expression")
		{
			if let tupleExpression = tupleShuffleExpression.subtree(named: "Tuple Expression"),
				let parametersString = translate(tupleExpression: tupleExpression).stringValue
			{
				parameters = parametersString
			}
			else if let parenthesesExpression = tupleShuffleExpression
				.subtree(named: "Parentheses Expression"),
				let parametersString = translate(expression: parenthesesExpression).stringValue
			{
				parameters = parametersString
			}
			else {
				return .failed
			}
		}
		else {
			return .failed
		}

		return .translation("\(functionNamePrefix)\(parameters)")
	}

	/// Translates boolean literals, which in swift are modeled as calls to specific builtin
	/// functions.
	///
	/// Diagnostics get logged at caller (`translate(callExpression:)`).
	private func translate(asBooleanLiteral callExpression: GRYAst) -> TranslationResult {
		precondition(callExpression.name == "Call Expression")

		if let tupleExpression = callExpression.subtree(named: "Tuple Expression"),
			let booleanLiteralExpression = tupleExpression
				.subtree(named: "Boolean Literal Expression"),
			let value = booleanLiteralExpression["value"]
		{
			return .translation(value)
		}
		else {
			return .failed
		}
	}

	/// Translates numeric literals, which in swift are modeled as calls to specific builtin
	/// functions.
	///
	/// Diagnostics get logged at caller (`translate(callExpression:)`).
	private func translate(asNumericLiteral callExpression: GRYAst) -> TranslationResult {
		precondition(callExpression.name == "Call Expression")

		if let tupleExpression = callExpression.subtree(named: "Tuple Expression"),
			let integerLiteralExpression = tupleExpression
				.subtree(named: "Integer Literal Expression"),
			let value = integerLiteralExpression["value"],

			let constructorReferenceCallExpression = callExpression
				.subtree(named: "Constructor Reference Call Expression"),
			let typeExpression = constructorReferenceCallExpression
				.subtree(named: "Type Expression"),
			let type = typeExpression["typerepr"]
		{
			if type == "Double" {
				return .translation(value + ".0")
			}
			else {
				return .translation(value)
			}
		}
		else {
			return .failed
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

	Diagnostics get logged at caller (`translate(callExpression:)`).
	*/
	private func translate(
		asKotlinLiteral callExpression: GRYAst,
		withFunctionNamePrefix functionNamePrefix: Substring) -> TranslationResult
	{
		precondition(callExpression.name == "Call Expression")

		let parameterExpression: GRYAst

		if functionNamePrefix == "GRYAlternative",
			let unwrappedExpression = callExpression.subtree(named: "Tuple Expression")
		{
			parameterExpression = unwrappedExpression
		}
		else if functionNamePrefix == "GRYInsert",
			let unwrappedExpression = callExpression.subtree(named: "Parentheses Expression")
		{
			parameterExpression = unwrappedExpression
		}
		else {
			return .failed
		}

		guard let stringExpression = parameterExpression.subtrees.last,
			let string = translate(stringLiteralExpression: stringExpression).stringValue else
		{
			return .failed
		}

		let unquotedString = String(string.dropLast().dropFirst())
		let unescapedString = removeBackslashEscapes(unquotedString)

		return .translation(unescapedString)
	}

	private func translate(declarationReferenceExpression: GRYAst) -> TranslationResult {
		precondition(declarationReferenceExpression.name == "Declaration Reference Expression")

		if let codeDeclaration = declarationReferenceExpression.standaloneAttributes.first,
			codeDeclaration.hasPrefix("code.")
		{
			diagnostics?.logSuccessfulTranslation(declarationReferenceExpression.name)
			return .translation(getIdentifierFromDeclaration(codeDeclaration))
		}
		else if let declaration = declarationReferenceExpression["decl"] {
			diagnostics?.logSuccessfulTranslation(declarationReferenceExpression.name)
			return .translation(getIdentifierFromDeclaration(declaration))
		}
		else {
			diagnostics?.logUnknownTranslation(declarationReferenceExpression.name)
			return .failed
		}
	}

	private func translate(memberReferenceExpression: GRYAst) -> TranslationResult {
		precondition(memberReferenceExpression.name == "Member Reference Expression")

		if let declaration = memberReferenceExpression["decl"],
			let memberOwner = memberReferenceExpression.subtree(at: 0),
			let memberOwnerString = translate(expression: memberOwner).stringValue
		{
			let member = getIdentifierFromDeclaration(declaration)
			diagnostics?.logSuccessfulTranslation(memberReferenceExpression.name)
			return .translation("\(memberOwnerString).\(member)")
		}
		else {
			diagnostics?.logUnknownTranslation(memberReferenceExpression.name)
			return .failed
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

	private func translate(tupleExpression: GRYAst) -> TranslationResult {
		precondition(tupleExpression.name == "Tuple Expression")

		// Only empty tuples don't have a list of names
		guard let names = tupleExpression["names"] else {
			diagnostics?.logSuccessfulTranslation(tupleExpression.name)
			return .translation("()")
		}

		let namesArray = names.split(separator: ",")

		var elements = [TranslationResult]()

		for (name, expression) in zip(namesArray, tupleExpression.subtrees) {
			guard let expressionString = translate(expression: expression).stringValue else {
				elements.append(.failed)
				continue
			}

			// Empty names (like the underscore in "foo(_:)") are represented by ''
			if name == "_" {
				elements.append(.translation(expressionString))
			}
			else {
				elements.append(.translation("\(name) = \(expressionString)"))
			}
		}

		guard !elements.contains(.failed) else {
			diagnostics?.logUnknownTranslation(tupleExpression.name)
			return .failed
		}

		// The stringValue's are always available, as guard statement above guarantees
		let contents = elements.map { $0.stringValue! }.joined(separator: ", ")

		diagnostics?.logSuccessfulTranslation(tupleExpression.name)
		return .translation("(" + contents + ")")
	}

	private func translate(stringLiteralExpression: GRYAst) -> TranslationResult {
		if let value = stringLiteralExpression["value"] {
			diagnostics?.logSuccessfulTranslation(stringLiteralExpression.name)
			return .translation("\"\(value)\"")
		}
		else {
			diagnostics?.logUnknownTranslation(stringLiteralExpression.name)
			return .failed
		}
	}

	private func translate(interpolatedStringLiteralExpression: GRYAst) -> TranslationResult
	{
		precondition(
			interpolatedStringLiteralExpression.name == "Interpolated String Literal Expression")

		var result = TranslationResult.translation("\"")

		for expression in interpolatedStringLiteralExpression.subtrees {
			if expression.name == "String Literal Expression" {
				guard let quotedString = translate(stringLiteralExpression: expression).stringValue
					else
				{
					result = .failed
					continue
				}

				let unquotedString = quotedString.dropLast().dropFirst()

				// Empty strings, as a special case, are represented by the swift ast dump
				// as two double quotes with nothing between them, instead of an actual empty string
				guard unquotedString != "\"\"" else { continue }

				result += unquotedString
			}
			else {
				let expressionTranslation = translate(expression: expression)
				guard let expressionString = expressionTranslation.stringValue else {
					result = .failed
					continue
				}
				result += "${\(expressionString)}"
			}
		}

		result += "\""

		diagnostics?.logResult(result, subtreeName: interpolatedStringLiteralExpression.name)
		return result
	}

	//
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

	//
	enum TranslationResult: Equatable, CustomStringConvertible {
		case translation(String)
		case failed

		init(stringLiteral value: StringLiteralType) {
			self = .translation(value)
		}

		static func +(left: TranslationResult, right: TranslationResult) -> TranslationResult {
			switch (left, right) {
			case (.translation(let leftTranslation), .translation(let rightTranslation)):
				return .translation(leftTranslation + rightTranslation)
			default:
				return .failed
			}
		}

		static func +(left: TranslationResult, right: String) -> TranslationResult {
			return left + .translation(right)
		}

		static func +(left: TranslationResult, right: Substring) -> TranslationResult {
			return left + String(right)
		}

		static func +(left: String, right: TranslationResult) -> TranslationResult {
			return .translation(left) + right
		}

		static func +(left: Substring, right: TranslationResult) -> TranslationResult {
			return String(left) + right
		}

		static func +=(left: inout TranslationResult, right: TranslationResult) {
			left = left + right
		}

		static func +=(left: inout TranslationResult, right: String) {
			left = left + right
		}

		static func +=(left: inout TranslationResult, right: Substring) {
			left = left + right
		}

		var stringValue: String? {
			switch self {
			case .translation(let value):
				return value
			case .failed:
				return nil
			}
		}

		var description: String {
			// The translator must turn TranslationResults into Strings explicitly, so as to force
			// the programmers to consider the possibilities and make their choices clearer.
			// This has already helped catch a few bugs.
			fatalError()
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
