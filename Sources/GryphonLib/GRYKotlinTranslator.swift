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
	public func translateAST(_ ast: GRYSwiftAst) -> String? {
		// First, translate declarations that shouldn't be inside the main function
		let declarationNames = [
			"Class Declaration",
			"Extension Declaration",
			"Function Declaration",
			"Enum Declaration",
		]
		let isDeclaration = { (ast: GRYSwiftAst) -> Bool in declarationNames.contains(ast.name) }

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
	private func translate(subtree: GRYSwiftAst, withIndentation indentation: String)
		-> TranslationResult
	{
		let result: TranslationResult

		switch subtree.name {
		case "Import Declaration":
			diagnostics?.logSuccessfulTranslation(subtree.name)
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
			diagnostics?.logSuccessfulTranslation(subtree.name)
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
			guard case let .throwStatement(expression: expression) =
				GRYSwift4_1Translator().translate(throwStatement: subtree)! else
			{
				return .failed
			}
			result = .translation(translateThrowStatement(
				expression: expression, withIndentation: indentation))
		case "Struct Declaration":
			result = translate(
				structDeclaration: subtree,
				withIndentation: indentation)
		case "Variable Declaration":
			result = translate(
				variableDeclaration: subtree,
				withIndentation: indentation)
		case "Assign Expression":
			guard case let .assignmentStatement(leftHand: leftHand, rightHand: rightHand) =
				GRYSwift4_1Translator().translate(assignExpression: subtree)! else
			{
				return .failed
			}
			result = .translation(translateAssignmentStatement(
				leftHand: leftHand,
				rightHand: rightHand,
				withIndentation: indentation))
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
			guard case let .returnStatement(expression: expression) =
				GRYSwift4_1Translator().translate(returnStatement: subtree)! else
			{
				return .failed
			}
			result = .translation(translateReturnStatement(
				expression: expression, withIndentation: indentation))
		case "Call Expression":
			let ast = GRYSwift4_1Translator().translate(expression: subtree)!
			let translatedExpression = translateExpression(ast)
			if !translatedExpression.isEmpty {
				result = .translation(indentation + translatedExpression + "\n")
			}
			else {
				// GRYIgnoreNext() results in an empty translation
				result = .translation("")
			}
		default:
			if subtree.name.hasSuffix("Expression") {
				let ast = GRYSwift4_1Translator().translate(expression: subtree)!
				let translatedExpression = translateExpression(ast)
				result = .translation(indentation + translatedExpression + "\n")
			}
			else {
				diagnostics?.logUnknownTranslation(subtree.name)
				result = .failed
			}
		}

		return result
	}

	private func translate(subtrees: [GRYSwiftAst], withIndentation indentation: String)
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

	private func process(patternBindingDeclaration: GRYSwiftAst) -> TranslationResult {
		precondition(patternBindingDeclaration.name == "Pattern Binding Declaration")

		// Some patternBindingDeclarations are empty, and that's ok. See the classes.swift test
		// case.
		guard let expression = patternBindingDeclaration.subtrees.last,
			ASTIsExpression(expression) else
		{
			return .translation("")
		}

		let ast = GRYSwift4_1Translator().translate(expression: expression)!
		let translatedExpression = translateExpression(ast)

		let binding: GRYSwiftAst

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
			assertionFailure("Expected to always work")
			return .failed
		}

		guard let identifier = binding.standaloneAttributes.first,
			let rawType = binding.keyValueAttributes["type"] else
		{
			assertionFailure("Expected to always work")
			return .failed
		}

		let type = translateType(rawType)

		danglingPatternBinding =
			(identifier: identifier,
			 type: type,
			 translatedExpression: translatedExpression)

		return .translation("")
	}

	/// This can be reasonably expected to always work, and is also not very useful for diagnostics.
	private func translate(topLevelCode: GRYSwiftAst, withIndentation indentation: String)
		-> TranslationResult
	{
		precondition(topLevelCode.name == "Top Level Code Declaration")

		guard let braceStatement = topLevelCode.subtree(named: "Brace Statement") else {
			assertionFailure("Expected to always work")
			return .failed
		}

		return translate(subtrees: braceStatement.subtrees, withIndentation: indentation)
	}

	private func translate(enumDeclaration: GRYSwiftAst, withIndentation indentation: String)
		-> TranslationResult
	{
		precondition(enumDeclaration.name == "Enum Declaration")

		var result = TranslationResult.translation(indentation)

		if let access = enumDeclaration.keyValueAttributes["access"] {
			result += access + " "
		}

		let enumName: TranslationResult
		if let name = enumDeclaration.standaloneAttributes.first {
			enumName = .translation(name)
			GRYKotlinTranslator.enums.append(name)
		}
		else {
			enumName = .failed
		}

		result += "sealed class " + enumName

		if let inheritanceList = enumDeclaration.keyValueAttributes["inherits"] {
			let rawInheritanceArray = inheritanceList.split(withStringSeparator: ", ")

			if rawInheritanceArray.contains("GRYIgnore") {
				return .translation("")
			}

			var inheritanceArray = rawInheritanceArray.map { translateType($0) }

			// The inheritanceArray isn't empty because the inheritanceList isn't empty.
			inheritanceArray[0] = inheritanceArray[0] + "()"

			let inheritanceString = inheritanceArray.joined(separator: ", ")

			result += ": \(inheritanceString)"
		}

		result += " {\n"

		let increasedIndentation = increaseIndentation(indentation)

		let enumElementDeclarations =
			enumDeclaration.subtrees.filter { $0.name == "Enum Element Declaration" }
		for enumElementDeclaration in enumElementDeclarations {
			guard let elementName = enumElementDeclaration.standaloneAttributes.first else {
				diagnostics?.logUnknownTranslation("[Enum Element Declaration]")
				result = .failed
				continue
			}

			let capitalizedElementName = elementName.capitalizedAsCamelCase

			diagnostics?.logSuccessfulTranslation("[Enum Element Declaration]")
			result += "\(increasedIndentation)class \(capitalizedElementName): " + enumName + "()\n"
		}

		result += "\(indentation)}\n"

		diagnostics?.logResult(result, subtreeName: enumDeclaration.name)
		return result
	}

	private func translate(protocolDeclaration: GRYSwiftAst, withIndentation indentation: String)
		-> TranslationResult
	{
		precondition(protocolDeclaration.name == "Protocol")

		guard let protocolName = protocolDeclaration.standaloneAttributes.first else {
			diagnostics?.logUnknownTranslation(protocolDeclaration.name)
			return .failed
		}

		if protocolName == "GRYIgnore" {
			diagnostics?.logSuccessfulTranslation(protocolDeclaration.name)
			return .translation("")
		}
		else {
			// Add actual protocol translation here
			diagnostics?.logUnknownTranslation(protocolDeclaration.name)
			return .failed
		}
	}

	private func translate(structDeclaration: GRYSwiftAst, withIndentation indentation: String)
		-> TranslationResult
	{
		precondition(structDeclaration.name == "Struct Declaration")

		let result = .refactorable + translate(
			subtrees: structDeclaration.subtrees,
			withIndentation: "")

		diagnostics?.logResult(result, subtreeName: structDeclaration.name)
		return result
	}

	private func translate(classDeclaration: GRYSwiftAst, withIndentation indentation: String)
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

		let result = "class " + classNameTranslation + inheritanceString + " {\n" + classContents +
			"}\n"

		diagnostics?.logResult(result, subtreeName: classDeclaration.name)
		return result
	}

	private func translate(constructorDeclaration: GRYSwiftAst, withIndentation indentation: String)
		-> TranslationResult
	{
		precondition(constructorDeclaration.name == "Constructor Declaration")

		guard !constructorDeclaration.standaloneAttributes.contains("implicit") else {
			diagnostics?.logSuccessfulTranslation(constructorDeclaration.name)
			return .translation("")
		}

		diagnostics?.logUnknownTranslation(constructorDeclaration.name)
		return .failed
	}

	private func translate(destructorDeclaration: GRYSwiftAst, withIndentation indentation: String)
		-> TranslationResult
	{
		precondition(destructorDeclaration.name == "Destructor Declaration")

		guard !destructorDeclaration.standaloneAttributes.contains("implicit") else {
			diagnostics?.logSuccessfulTranslation(destructorDeclaration.name)
			return .translation("")
		}

		diagnostics?.logUnknownTranslation(destructorDeclaration.name)
		return .failed
	}

	private func translate(functionDeclaration: GRYSwiftAst, withIndentation indentation: String)
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
			!functionName.hasPrefix("GRYIgnoreNext(") else
		{
			return .translation("")
		}

		// If it's GRYDeclarations, we want to add its contents as top-level statements
		guard !functionName.hasPrefix("GRYDeclarations(") else {
			if let braceStatement = functionDeclaration.subtree(named: "Brace Statement") {
				diagnostics?.logSuccessfulTranslation(functionDeclaration.name)
				return translate(subtrees: braceStatement.subtrees, withIndentation: indentation)
			}
			else {
				diagnostics?.logUnknownTranslation(functionDeclaration.name)
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
		let parameterList: GRYSwiftAst?

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
					guard name != "self" else {
						continue
					}

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

		diagnostics?.logResult(result, subtreeName: functionDeclaration.name)
		return result
	}

	private func translate(forEachStatement: GRYSwiftAst, withIndentation indentation: String)
		-> TranslationResult
	{
		precondition(forEachStatement.name == "For Each Statement")

		var result = TranslationResult.translation("")

		if let variableName = forEachStatement
				.subtree(named: "Pattern Named")?
				.standaloneAttributes.first,
			let collectionExpression = forEachStatement.subtree(at: 2)
		{
			let ast = GRYSwift4_1Translator().translate(expression: collectionExpression)!
			let collectionString = translateExpression(ast)
			result += .translation("\(indentation)for (\(variableName) in \(collectionString))")
		}
		else {
			result = .failed
		}

		let increasedIndentation = increaseIndentation(indentation)

		if let braceStatement = forEachStatement.subtrees.last,
			braceStatement.name == "Brace Statement"
		{
			let statements = translate(
				subtrees: braceStatement.subtrees,
				withIndentation: increasedIndentation)

			result += " {\n" + statements + indentation + "}\n"
		}
		else {
			result = .failed
		}

		diagnostics?.logResult(result, subtreeName: forEachStatement.name)
		return result
	}

	private func translate(
		ifStatement: GRYSwiftAst,
		asElseIf isElseIf: Bool = false,
		asGuard isGuard: Bool = false,
		withIndentation indentation: String) -> TranslationResult
	{
		precondition(ifStatement.name == "If Statement" || ifStatement.name == "Guard Statement")

		let (letDeclarations, conditions) = translateDeclarationsAndConditions(
			forIfStatement: ifStatement,
			withIndentation: indentation)

		let increasedIndentation = increaseIndentation(indentation)

		let keyword = isElseIf ? "else if" : "if"

		let parenthesizedCondition = isGuard ?
			TranslationResult.translation("(!(") + conditions + "))" :
			TranslationResult.translation("(") + conditions + ")"

		var result = letDeclarations + indentation + keyword + " " + parenthesizedCondition + " {\n"

		var elseIfTranslation = TranslationResult.translation("")
		var elseTranslation = TranslationResult.translation("")
		let braceStatement: GRYSwiftAst

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
			diagnostics?.logUnknownTranslation(ifStatement.name)
			return .failed
		}

		let statements = braceStatement.subtrees
		let statementsString =
			translate(subtrees: statements, withIndentation: increasedIndentation)

		result += statementsString + indentation + "}\n" + elseIfTranslation + elseTranslation

		diagnostics?.logResult(result, subtreeName: ifStatement.name)
		return result
	}

	/// Failures in translating if-let conditions get counted as failures in conditions
	/// and their corresponding let declaration never gets created
	private func translateDeclarationsAndConditions(
		forIfStatement ifStatement: GRYSwiftAst,
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
				let patternNamed: GRYSwiftAst
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
					let lastCondition = condition.subtrees.last else
				{
					diagnostics?.logUnknownTranslation("If-let")
					conditionStrings.append(nil)
					continue
				}
				let ast = GRYSwift4_1Translator().translate(expression: lastCondition)!
				let expressionString = translateExpression(ast)

				diagnostics?.logSuccessfulTranslation("If-let")
				letDeclarations.append(
					"\(indentation)\(varOrValKeyword) \(name)\(typeString) = \(expressionString)\n")
				conditionStrings.append("\(name) != null")
			}
			else {
				let ast = GRYSwift4_1Translator().translate(expression: condition)!
				conditionStrings.append(translateExpression(ast))
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

	private func translateThrowStatement(
		expression: GRYExpression, withIndentation indentation: String) -> String
	{
		let expressionString = translateExpression(expression)
		return "\(indentation)throw \(expressionString)\n"
	}

	private func translateReturnStatement(
		expression: GRYExpression?, withIndentation indentation: String) -> String
	{
		if let expression = expression {
			let expressionString = translateExpression(expression)
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
		variableDeclaration: GRYSwiftAst,
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
			{ (subtree: GRYSwiftAst) -> Bool in
				subtree.name == "Function Declaration" &&
					!subtree.standaloneAttributes.contains("implicit") &&
					subtree.keyValueAttributes["getter_for"] != nil
			})
			let hasSetter = variableDeclaration.subtrees.contains(where:
			{ (subtree: GRYSwiftAst) -> Bool in
				subtree.name == "Function Declaration" &&
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
		forVariableDeclaration variableDeclaration: GRYSwiftAst,
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
				diagnostics?.logUnknownTranslation("Getter/Setter")
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

	private func translateAssignmentStatement(
		leftHand: GRYExpression, rightHand: GRYExpression, withIndentation indentation: String)
		-> String
	{
		let leftTranslation = translateExpression(leftHand)
		let rightTranslation = translateExpression(rightHand)
		return "\(indentation)\(leftTranslation) = \(rightTranslation)\n"
	}

	private func translateExpression(_ expression: GRYExpression) -> String {
		// Most diagnostics are logged by the child subTrees; others represent wrapper expressions
		// with little value in logging. There are a few expections.

		switch expression {
		case let .arrayExpression(elements: elements):
			return translateArrayExpression(elements: elements)
		case let .binaryOperatorExpression(
			leftExpression: leftExpression,
			rightExpression: rightExpression,
			operatorSymbol: operatorSymbol):

			return translateBinaryOperatorExpression(
				leftExpression: leftExpression,
				rightExpression: rightExpression,
				operatorSymbol: operatorSymbol)
		case let .callExpression(function: function, parameters: parameters):
			return translateCallExpression(function: function, parameters: parameters)
		case let .declarationReferenceExpression(identifier: identifier):
			return translateDeclarationReferenceExpression(identifier: identifier)
		case let .dotExpression(leftExpression: leftExpression, rightExpression: rightExpression):
			return translateDotSyntaxCallExpression(
				leftExpression: leftExpression, rightExpression: rightExpression)
		case let .literalStringExpression(value: value):
			return translateStringLiteral(value: value)
		case let .interpolatedStringLiteralExpression(expressions: expressions):
			return translateInterpolatedStringLiteralExpression(expressions: expressions)
		case let .unaryOperatorExpression(expression: expression, operatorSymbol: operatorSymbol):
			return translatePrefixUnaryExpression(
				expression: expression, operatorSymbol: operatorSymbol)
		case let .typeExpression(type: type):
			return type
		case let .subscriptExpression(
			subscriptedExpression: subscriptedExpression, indexExpression: indexExpression):

			return translateSubscriptExpression(
				subscriptedExpression: subscriptedExpression, indexExpression: indexExpression)
		case let .parenthesesExpression(expression: expression):
			return "(" + translateExpression(expression) + ")"
		case let .forceValueExpression(expression: expression):
			return translateExpression(expression) + "!!"
		case let .literalIntExpression(value: value):
			return String(value)
		case let .literalDoubleExpression(value: value):
			return String(value)
		case let .literalBoolExpression(value: value):
			return String(value)
		case .nilLiteralExpression:
			return "null"
		case let .tupleExpression(pairs: pairs):
			return translateTupleExpression(pairs: pairs)
		}
	}

	private func translateSubscriptExpression(
		subscriptedExpression: GRYExpression, indexExpression: GRYExpression) -> String
	{
		return translateExpression(subscriptedExpression) +
			"[\(translateExpression(indexExpression))]"
	}

	private func translateArrayExpression(elements: [GRYExpression]) -> String {
		let expressionsString = elements.map {
			translateExpression($0)
		}.joined(separator: ", ")

		return "mutableListOf(\(expressionsString))"
	}

	private func translateDotSyntaxCallExpression(
		leftExpression: GRYExpression, rightExpression: GRYExpression) -> String
	{
		let leftHandString = translateExpression(leftExpression)
		let rightHandString = translateExpression(rightExpression)

		if GRYKotlinTranslator.enums.contains(leftHandString) {
			let capitalizedEnumCase = rightHandString.capitalizedAsCamelCase
			return "\(leftHandString).\(capitalizedEnumCase)()"
		}
		else {
			return "\(leftHandString).\(rightHandString)"
		}
	}

	private func translateBinaryOperatorExpression(
		leftExpression: GRYExpression,
		rightExpression: GRYExpression,
		operatorSymbol: String) -> String
	{
		let leftTranslation = translateExpression(leftExpression)
		let rightTranslation = translateExpression(rightExpression)
		return "\(leftTranslation) \(operatorSymbol) \(rightTranslation)"
	}

	private func translatePrefixUnaryExpression(
		expression: GRYExpression, operatorSymbol: String) -> String
	{
		let expressionTranslation = translateExpression(expression)
		return operatorSymbol + expressionTranslation
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
	private func translateCallExpression(function: GRYExpression, parameters: GRYExpression)
		-> String
	{
		guard case let .tupleExpression(pairs: pairs) = parameters else {
			preconditionFailure()
		}

		let functionTranslation = translateExpression(function)

		if functionTranslation == "GRYInsert" || functionTranslation == "GRYAlternative" {
			return translateAsKotlinLiteral(
				functionTranslation: functionTranslation,
				parameters: parameters)
		}
		else if functionTranslation == "GRYIgnoreNext" {
			shouldIgnoreNext = true
			return ""
		}

		let parametersTranslation = translateTupleExpression(pairs: pairs)

		// TODO: This should be replaced with a better system
		if functionTranslation == "print" {
			return "println" + parametersTranslation
		}
		else {
			return functionTranslation + parametersTranslation
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
	private func translateAsKotlinLiteral(
		functionTranslation: String,
		parameters: GRYExpression) -> String
	{
		let string: String
		if case let .tupleExpression(pairs: pairs) = parameters,
			let lastPair = pairs.last
		{
			// Remove this extra parentheses expression with an Ast pass
			if case let .literalStringExpression(value: value) = lastPair.expression {
				string = value
			}
			else if case let .parenthesesExpression(expression: expression) = lastPair.expression,
				case let .literalStringExpression(value: value) = expression
			{
				string = value
			}
			else {
				preconditionFailure()
			}

			let unescapedString = removeBackslashEscapes(string)
			return unescapedString
		}

		preconditionFailure()
	}

	private func translateDeclarationReferenceExpression(identifier: String) -> String {
		return String(identifier.prefix { $0 != "(" })
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

	private func translateTupleExpression(pairs: [GRYExpression.TuplePair]) -> String {
		guard !pairs.isEmpty else {
			return "()"
		}

		let contents = pairs.map { (pair: GRYExpression.TuplePair) -> String in

			// TODO: Turn this into an Ast pass
			let expression: String
			if case let .parenthesesExpression(expression: innerExpression) = pair.expression {
				expression = translateExpression(innerExpression)
			}
			else {
				expression = translateExpression(pair.expression)
			}

			if let name = pair.name {
				return "\(name) = \(expression)"
			}
			else {
				return expression
			}
		}.joined(separator: ", ")

		return "(\(contents))"
	}

	private func translateStringLiteral(value: String) -> String {
		return "\"\(value)\""
	}

	private func translateInterpolatedStringLiteralExpression(expressions: [GRYExpression])
		-> String
	{
		var result = "\""

		for expression in expressions {
			if case let .literalStringExpression(value: string) = expression {
				// Empty strings, as a special case, are represented by the swift ast dump
				// as two double quotes with nothing between them, instead of an actual empty string
				guard string != "\"\"" else {
					continue
				}

				result += string
			}
			else {
				result += "${" + translateExpression(expression) + "}"
			}
		}

		result += "\""

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

	private func ASTIsExpression(_ ast: GRYSwiftAst) -> Bool {
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
		case refactorable
		case failed

		init(stringLiteral value: StringLiteralType) {
			self = .translation(value)
		}

		static func +(left: TranslationResult, right: TranslationResult) -> TranslationResult {
			switch (left, right) {
			case (.failed, _), (_, .failed):
				return .failed
			case (.refactorable, _), (_, .refactorable):
				return .refactorable
			case (.translation(let leftTranslation), .translation(let rightTranslation)):
				return .translation(leftTranslation + rightTranslation)
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
			case .failed, .refactorable:
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
