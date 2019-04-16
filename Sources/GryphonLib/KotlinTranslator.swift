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

public class KotlinTranslator {
	static let errorTranslation = "<<Error>>"

	static let lineLimit = 100

	/// Used for the translation of Swift types into Kotlin types.
	static let typeMappings = [
		"Bool": "Boolean",
		"Error": "Exception",
		"UInt8": "UByte",
		"UInt16": "UShort",
		"UInt32": "UInt",
		"UInt64": "ULong",
		"Int8": "Byte",
		"Int16": "Short",
		"Int32": "Int",
		"Int64": "Long",
		"Float32": "Float",
		"Float64": "Double",
		"Character": "Char",

		"String.Index": "Int",
		"Substring.Index": "Int",
		"Substring": "String",
		"String.SubSequence": "String",
		"Range<String.Index>": "IntRange",
	]

	private func translateType(_ type: String) -> String {
		let type = type.replacingOccurrences(of: "()", with: "Unit")

		if type.hasSuffix("?") {
			return translateType(String(type.dropLast())) + "?"
		}
		else if type.hasPrefix("[") {
			if type.contains(":") {
				let innerTypes =
					String(type.dropLast().dropFirst()).split(withStringSeparator: " : ")
				let keyType = innerTypes[0]
				let valueType = innerTypes[1]
				let translatedKey = translateType(keyType)
				let translatedValue = translateType(valueType)
				return "MutableMap<\(translatedKey), \(translatedValue)>"
			}
			else {
				let innerType = String(type.dropLast().dropFirst())
				let translatedInnerType = translateType(innerType)
				return "MutableList<\(translatedInnerType)>"
			}
		}
		else if type.hasPrefix("ArrayReference<") {
			let innerType = String(type.dropLast().dropFirst("ArrayReference<".count))
			let translatedInnerType = translateType(innerType)
			return "MutableList<\(translatedInnerType)>"
		}
		else if type.hasPrefix("DictionaryReference<") {
			let innerTypes = String(type.dropLast().dropFirst("DictionaryReference<".count))
			let keyValue = innerTypes.split(withStringSeparator: ", ")
			let key = keyValue[0]
			let value = keyValue[1]
			let translatedKey = translateType(key)
			let translatedValue = translateType(value)
			return "MutableMap<\(translatedKey), \(translatedValue)>"
		}
		else {
			return KotlinTranslator.typeMappings[type] ?? type
		}
	}

	/**
	This variable is used to store enum definitions in order to allow the translator
	to translate them as sealed classes (see the `translate(dotSyntaxCallExpression)` method).
	*/
	private(set) static var sealedClasses = [String]()

	public static func addSealedClass(_ className: String) {
		sealedClasses.append(className)
	}

	/**
	This variable is used to store enum definitions in order to allow the translator
	to translate them as enum classes (see the `translate(dotSyntaxCallExpression)` method).
	*/
	private(set) static var enumClasses = [String]()

	public static func addEnumClass(_ className: String) {
		enumClasses.append(className)
	}

	/// Stores information on how a Swift function should be translated into Kotlin, including what
	/// its prefix should be and what its parameters should be named. The `swiftAPIName` and the
	/// `type` properties are used to look up the right function translation, and they should match
	/// declarationReferences that reference this function.
	/// This is used, for instance, to translate a function to Kotlin using the internal parameter
	/// names instead of Swift's API label names, improving correctness and readability of the
	/// translation. The information has to be stored because declaration references don't include
	/// the internal parameter names, only the API names.
	public struct FunctionTranslation {
		let swiftAPIName: String
		let type: String
		let prefix: String
		let parameters: [String]
	}

	private static var functionTranslations = [FunctionTranslation]()

	public static func addFunctionTranslation(_ newValue: FunctionTranslation) {
		functionTranslations.append(newValue)
	}

	public static func getFunctionTranslation(forName name: String, type: String)
		-> FunctionTranslation?
	{
		// Functions with unnamed parameters here are identified only by their prefix. For instance
		// `f(_:_:)` here is named `f` but has been stored earlier as `f(_:_:)`.
		for functionTranslation in functionTranslations {
			if functionTranslation.swiftAPIName.hasPrefix(name), functionTranslation.type == type {
				return functionTranslation
			}
		}

		return nil
	}

	// MARK: - Interface

	public init() { }

	public func translateAST(_ sourceFile: GryphonAST) throws -> String {
		let declarationsTranslation =
			try translate(subtrees: sourceFile.declarations, withIndentation: "")

		let indentation = increaseIndentation("")
		let statementsTranslation =
			try translate(subtrees: sourceFile.statements, withIndentation: indentation)

		var result = declarationsTranslation

		guard !statementsTranslation.isEmpty else {
			return result
		}

		// Add newline between declarations and the main function, if needed
		if !declarationsTranslation.isEmpty {
			result += "\n"
		}

		result += "fun main(args: Array<String>) {\n\(statementsTranslation)}\n"

		return result
	}

	// MARK: - Implementation

	private func translate(subtree: Statement, withIndentation indentation: String) throws
		-> String
	{
		let result: String

		switch subtree {
		case .importDeclaration(name: _):
			result = ""
		case .extensionDeclaration(type: _, members: _):
			return try unexpectedASTStructureError(
				"Extension structure should have been removed in a transpilation pass",
				AST: subtree)
		case .deferStatement(statements: _):
			return try unexpectedASTStructureError(
				"Defer statements are only supported as top-level statements in function bodies",
				AST: subtree)
		case let .typealiasDeclaration(identifier: identifier, type: type, isImplicit: isImplicit):
			result = try translateTypealias(
				identifier: identifier, type: type, isImplicit: isImplicit,
				withIndentation: indentation)
		case let .classDeclaration(name: name, inherits: inherits, members: members):
			result = try translateClassDeclaration(
				name: name, inherits: inherits, members: members, withIndentation: indentation)
		case let .structDeclaration(
			annotations: annotations, name: name, inherits: inherits, members: members):

			result = try translateStructDeclaration(
				annotations: annotations,
				name: name, inherits: inherits,
				members: members,
				withIndentation: indentation)
		case let .companionObject(members: members):
			result = try translateCompanionObject(members: members, withIndentation: indentation)
		case let .enumDeclaration(
			access: access, name: name, inherits: inherits, elements: elements, members: members,
			isImplicit: isImplicit):

			result = try translateEnumDeclaration(
				access: access, name: name, inherits: inherits, elements: elements,
				members: members, isImplicit: isImplicit, withIndentation: indentation)
		case let .forEachStatement(
			collection: collection, variable: variable, statements: statements):

			result = try translateForEachStatement(
				collection: collection, variable: variable, statements: statements,
				withIndentation: indentation)
		case let .whileStatement(expression: expression, statements: statements):
			result = try translateWhileStatement(
				expression: expression, statements: statements, withIndentation: indentation)
		case let .functionDeclaration(value: functionDeclaration):
			result = try translateFunctionDeclaration(
				functionDeclaration: functionDeclaration, withIndentation: indentation)
		case let .protocolDeclaration(name: name, members: members):
			result = try translateProtocolDeclaration(
				name: name, members: members, withIndentation: indentation)
		case let .throwStatement(expression: expression):
			result = try translateThrowStatement(
				expression: expression, withIndentation: indentation)
		case let .variableDeclaration(value: variableDeclaration):
			result = try translateVariableDeclaration(
				variableDeclaration, withIndentation: indentation)
		case let .assignmentStatement(leftHand: leftHand, rightHand: rightHand):
			result = try translateAssignmentStatement(
				leftHand: leftHand, rightHand: rightHand, withIndentation: indentation)
		case let .ifStatement(value: ifStatement):
			result = try translateIfStatement(ifStatement, withIndentation: indentation)
		case let .switchStatement(
			convertsToExpression: convertsToExpression, expression: expression,
			cases: cases):

			result = try translateSwitchStatement(
				convertsToExpression: convertsToExpression, expression: expression, cases: cases,
				withIndentation: indentation)
		case let .returnStatement(expression: expression):
			result = try translateReturnStatement(
				expression: expression, withIndentation: indentation)
		case .breakStatement:
			result = "\(indentation)break\n"
		case .continueStatement:
			result = "\(indentation)continue\n"
		case let .expression(expression: expression):
			let expressionTranslation =
				try translateExpression(expression, withIndentation: indentation)
			if !expressionTranslation.isEmpty {
				return indentation + expressionTranslation + "\n"
			}
			else {
				return "\n"
			}
		case .error:
			return KotlinTranslator.errorTranslation
		}

		return result
	}

	private func translate(
		subtrees: [Statement], withIndentation indentation: String,
		limitForAddingNewlines: Int = 0) throws -> String
	{
		let treesAndTranslations = try subtrees.map {
				(subtree: $0, translation: try translate(subtree: $0, withIndentation: indentation))
			}.filter {
				!$0.translation.isEmpty
			}

		if treesAndTranslations.count <= limitForAddingNewlines {
			return treesAndTranslations.map { $0.translation }.joined()
		}

		var result = ""

		for (currentSubtree, nextSubtree)
			in zip(treesAndTranslations, treesAndTranslations.dropFirst())
		{
			result += currentSubtree.translation

			// Cases that should go together
			if case .variableDeclaration = currentSubtree.subtree,
				case .variableDeclaration = nextSubtree.subtree
			{
				continue
			}
			else if case .expression(expression: .callExpression) = currentSubtree.subtree,
				case .expression(expression: .callExpression) = nextSubtree.subtree
			{
				continue
			}
			else if case .expression(expression: .templateExpression) = currentSubtree.subtree,
				case .expression(expression: .templateExpression) = nextSubtree.subtree
			{
				continue
			}
			else if case .expression(expression: .literalCodeExpression) = currentSubtree.subtree,
				case .expression(expression: .literalCodeExpression) = nextSubtree.subtree
			{
				continue
			}
			else if case .assignmentStatement = currentSubtree.subtree,
				case .assignmentStatement = nextSubtree.subtree
			{
				continue
			}
			else if case .typealiasDeclaration = currentSubtree.subtree,
				case .typealiasDeclaration = nextSubtree.subtree
			{
				continue
			}

			result += "\n"
		}

		if let lastSubtree = treesAndTranslations.last {
			result += lastSubtree.translation
		}

		return result
	}

	private func translateEnumDeclaration(
		access: String?, name enumName: String, inherits: [String], elements: [EnumElement],
		members: [Statement], isImplicit: Bool, withIndentation indentation: String)
		throws -> String
	{
		let isEnumClass = KotlinTranslator.enumClasses.contains(enumName)

		let accessString = access ?? ""
		let enumString = isEnumClass ? "enum" : "sealed"

		var result = "\(indentation)\(accessString) \(enumString) class " + enumName

		if !inherits.isEmpty {
			var translatedInheritedTypes = inherits.map(translateType)
			translatedInheritedTypes[0] = translatedInheritedTypes[0] + "()"
			result += ": \(translatedInheritedTypes.joined(separator: ", "))"
		}

		result += " {\n"

		let increasedIndentation = increaseIndentation(indentation)

		var casesTranslation = ""
		if isEnumClass {
			casesTranslation += elements.map { element in
				let capitalizedElementName = element.name
				let annotationsString = (element.annotations == nil) ? "" :
					"\(element.annotations!) "
				return "\(increasedIndentation)\(annotationsString)\(capitalizedElementName)"
				}.joined(separator: ",\n") + ";\n"
		}
		else {
			for element in elements {
				casesTranslation += translateEnumElementDeclaration(
					enumName: enumName, element: element, withIndentation: increasedIndentation)
			}
		}
		result += casesTranslation

		let membersTranslation =
			try translate(subtrees: members, withIndentation: increasedIndentation)

		// Add a newline between cases and members if needed
		if !casesTranslation.isEmpty && !membersTranslation.isEmpty {
			result += "\n"
		}

		result += "\(membersTranslation)\(indentation)}\n"

		return result
	}

	private func translateEnumElementDeclaration(
		enumName: String,
		element: EnumElement,
		withIndentation indentation: String) -> String
	{
		let capitalizedElementName = element.name.capitalizedAsCamelCase
		let annotationsString = (element.annotations == nil) ? "" : "\(element.annotations!) "

		let result = "\(indentation)\(annotationsString)class \(capitalizedElementName)"

		if element.associatedValues.isEmpty {
			return result + ": \(enumName)()\n"
		}
		else {
			let associatedValuesString =
				element.associatedValues
					.map { "val \($0.label): \($0.type)" }.joined(separator: ", ")
			return result + "(\(associatedValuesString)): \(enumName)()\n"
		}
	}

	private func translateProtocolDeclaration(
		name: String, members: [Statement], withIndentation indentation: String) throws
		-> String
	{
		var result = "\(indentation)interface \(name) {\n"
		let contents = try translate(
			subtrees: members, withIndentation: increaseIndentation(indentation))
		result += contents
		result += "\(indentation)}\n"
		return result
	}

	private func translateTypealias(
		identifier: String, type: String, isImplicit: Bool, withIndentation indentation: String)
		throws -> String
	{
		let translatedType = translateType(type)
		return "\(indentation)typealias \(identifier) = \(translatedType)\n"
	}

	private func translateClassDeclaration(
		name: String, inherits: [String], members: [Statement],
		withIndentation indentation: String) throws -> String
	{
		var result = "\(indentation)class \(name)"

		if !inherits.isEmpty {
			let translatedInheritances = inherits.map(translateType)
			result += ": " + translatedInheritances.joined(separator: ", ")
		}

		result += " {\n"

		let increasedIndentation = increaseIndentation(indentation)

		let classContents = try translate(
			subtrees: members,
			withIndentation: increasedIndentation)

		result += classContents + "\(indentation)}\n"

		return result
	}

	/// If a value type's members are all immutable, that value type can safely be translated as a
	/// class. Source: https://forums.swift.org/t/are-immutable-structs-like-classes/16270
	private func translateStructDeclaration(
		annotations: String?, name: String, inherits: [String], members: [Statement],
		withIndentation indentation: String) throws -> String
	{
		let increasedIndentation = increaseIndentation(indentation)

		let annotationsString = annotations.map { "\(indentation)\($0)\n" } ?? ""

		var result = "\(annotationsString)\(indentation)data class \(name)(\n"

		let isProperty = { (member: Statement) -> Bool in
			if case let .variableDeclaration(value: variableDeclaration) = member,
				variableDeclaration.getter == nil,
				variableDeclaration.setter == nil,
				!variableDeclaration.isStatic
			{
				return true
			}
			else {
				return false
			}
		}
		let properties = members.filter(isProperty)
		let otherMembers = members.filter { !isProperty($0) }

		// Translate properties individually, dropping the newlines at the end
		let propertyTranslations = try properties.map {
			try String(translate(subtree: $0, withIndentation: increasedIndentation).dropLast())
		}
		let propertiesTranslation = propertyTranslations.joined(separator: ",\n")

		result += propertiesTranslation + "\n\(indentation))"

		if !inherits.isEmpty {
			let translatedInheritances = inherits.map(translateType)
			result += ": " + translatedInheritances.joined(separator: ", ")
		}

		let otherMembersTranslation = try translate(
			subtrees: otherMembers,
			withIndentation: increasedIndentation)

		if !otherMembersTranslation.isEmpty {
			result += " {\n\(otherMembersTranslation)\(indentation)}\n"
		}
		else {
			result += "\n"
		}

		return result
	}

	private func translateCompanionObject(
		members: [Statement], withIndentation indentation: String) throws -> String
	{
		var result = "\(indentation)companion object {\n"

		let increasedIndentation = increaseIndentation(indentation)

		let contents = try translate(
			subtrees: members,
			withIndentation: increasedIndentation)

		result += contents + "\(indentation)}\n"

		return result
	}

	private func translateFunctionDeclaration(
		functionDeclaration: FunctionDeclaration, withIndentation indentation: String,
		shouldAddNewlines: Bool = false) throws -> String
	{
		guard !functionDeclaration.isImplicit else {
			return ""
		}

		var indentation = indentation
		var result = indentation

		let isInit = (functionDeclaration.prefix == "init")
		if isInit {
			result += "constructor("
		}
		else if functionDeclaration.prefix == "invoke" {
			result += "operator fun invoke("
		}
		else {
			if let annotations = functionDeclaration.annotations {
				result += annotations + " "
			}
			if let access = functionDeclaration.access {
				result += access + " "
			}
			result += "fun "
			if let extensionType = functionDeclaration.extendsType {
				let translatedExtensionType = translateType(extensionType)
				// TODO: test
				let companionString = functionDeclaration.isStatic ? "Companion." : ""

				// TODO: tests
				let genericString: String
				if let genericExtensionIndex = translatedExtensionType.index(of: "<") {
					let genericExtensionString =
						translatedExtensionType.suffix(from: genericExtensionIndex)
					var genericTypes = genericExtensionString
						.dropFirst().dropLast()
						.split(separator: ",")
						.map(String.init)
					genericTypes.append(contentsOf: functionDeclaration.genericTypes)
					genericString = "<\(genericTypes.joined(separator: ", "))> "
				}
				else if !functionDeclaration.genericTypes.isEmpty {
					genericString = "<\(functionDeclaration.genericTypes.joined(separator: ", "))> "
				}
				else {
					genericString = ""
				}

				result += genericString + translatedExtensionType + "." + companionString
			}
			result += functionDeclaration.prefix + "("
		}

		let returnString: String
		if functionDeclaration.returnType != "()", !isInit {
			let translatedReturnType = translateType(functionDeclaration.returnType)
			returnString = ": \(translatedReturnType)"
		}
		else {
			returnString = ""
		}

		let parameterStrings = try functionDeclaration.parameters.map
			{ (parameter: FunctionParameter) -> String in
				let labelAndTypeString = parameter.label + ": " + translateType(parameter.type)
				if let defaultValue = parameter.value {
					return try labelAndTypeString + " = "
						+ translateExpression(defaultValue, withIndentation: indentation)
				}
				else {
					return labelAndTypeString
				}
			}

		if !shouldAddNewlines {
			result += parameterStrings.joined(separator: ", ") + ")" + returnString + " {\n"
			if result.count >= KotlinTranslator.lineLimit {
				return try translateFunctionDeclaration(
					functionDeclaration: functionDeclaration, withIndentation: indentation,
					shouldAddNewlines: true)
			}
		}
		else {
			let parameterIndentation = increaseIndentation(indentation)
			let parametersString = parameterStrings.joined(separator: ",\n\(parameterIndentation)")
			result += "\n\(parameterIndentation)" + parametersString + ")\n"

			if !returnString.isEmpty {
				result += "\(parameterIndentation)\(returnString)\n"
			}

			result += "\(indentation){\n"
		}

		guard let statements = functionDeclaration.statements else {
			return result + "\n"
		}

		// Get all statements that have been deferred
		let innerDeferStatements = statements.flatMap { (statement: Statement) -> [Statement] in
			if case let .deferStatement(statements: innerStatements) = statement {
				return innerStatements
			}
			else {
				return []
			}
		}

		// Get all other statements
		let nonDeferStatements = statements.filter { statement in
			if case .deferStatement = statement {
				return false
			}
			else {
				return true
			}
		}

		indentation = increaseIndentation(indentation)

		if !innerDeferStatements.isEmpty {
			let increasedIndentation = increaseIndentation(indentation)
			result += "\(indentation)try {\n"
			result += try translate(
				subtrees: nonDeferStatements,
				withIndentation: increasedIndentation,
				limitForAddingNewlines: 3)
			result += "\(indentation)}\n"
			result += "\(indentation)finally {\n"
			result += try translate(
				subtrees: innerDeferStatements,
				withIndentation: increasedIndentation,
				limitForAddingNewlines: 3)
			result += "\(indentation)}\n"
		}
		else {
			result += try translate(
				subtrees: statements, withIndentation: indentation, limitForAddingNewlines: 3)
		}

		indentation = decreaseIndentation(indentation)
		result += indentation + "}\n"

		return result
	}

	private func translateForEachStatement(
		collection: Expression, variable: Expression, statements: [Statement],
		withIndentation indentation: String) throws -> String
	{
		var result = "\(indentation)for ("

		let variableTranslation = try translateExpression(variable, withIndentation: indentation)

		result += variableTranslation + " in "

		let collectionTranslation =
			try translateExpression(collection, withIndentation: indentation)

		result += collectionTranslation + ") {\n"

		let increasedIndentation = increaseIndentation(indentation)
		let statementsTranslation = try translate(
			subtrees: statements, withIndentation: increasedIndentation, limitForAddingNewlines: 3)

		result += statementsTranslation

		result += indentation + "}\n"
		return result
	}

	// TODO: Update stdlib tests
	// TODO: Test whiles
	private func translateWhileStatement(
		expression: Expression, statements: [Statement], withIndentation indentation: String)
		throws -> String
	{
		var result = "\(indentation)while ("

		let expressionTranslation =
			try translateExpression(expression, withIndentation: indentation)
		result += expressionTranslation + ") {\n"

		let increasedIndentation = increaseIndentation(indentation)
		let statementsTranslation = try translate(
			subtrees: statements, withIndentation: increasedIndentation, limitForAddingNewlines: 3)

		result += statementsTranslation

		result += indentation + "}\n"
		return result
	}

	private func translateIfStatement(
		_ ifStatement: IfStatement, isElseIf: Bool = false,
		withIndentation indentation: String) throws -> String
	{
		let keyword = (ifStatement.conditions.isEmpty && ifStatement.declarations.isEmpty) ?
			"else" :
			(isElseIf ? "else if" : "if")

		var result = indentation + keyword + " "

		let increasedIndentation = increaseIndentation(indentation)

		let conditionsTranslation = try ifStatement.conditions.map {
				try translateExpression($0, withIndentation: indentation)
			}.joined(separator: " && ")

		if keyword != "else" {
			let parenthesizedCondition = ifStatement.isGuard ?
				("(!(" + conditionsTranslation + ")) ") :
				("(" + conditionsTranslation + ") ")

			result += parenthesizedCondition
		}

		result += "{\n"

		let statementsString = try translate(
			subtrees: ifStatement.statements, withIndentation: increasedIndentation,
			limitForAddingNewlines: 3)

		result += statementsString + indentation + "}\n"

		if let unwrappedElse = ifStatement.elseStatement {
			result += try translateIfStatement(
				unwrappedElse, isElseIf: true, withIndentation: indentation)
		}

		return result
	}

	private func translateSwitchStatement(
		convertsToExpression: Statement?, expression: Expression,
		cases: [SwitchCase], withIndentation indentation: String) throws -> String
	{
		var result: String = ""

		if let convertsToExpression = convertsToExpression {
			if case .returnStatement(expression: _) = convertsToExpression {
				result = "\(indentation)return when ("
			}
			else if case let .assignmentStatement(
				leftHand: leftHand, rightHand: _) = convertsToExpression
			{
				let translatedLeftHand =
					try translateExpression(leftHand, withIndentation: indentation)
				result = "\(indentation)\(translatedLeftHand) = when ("
			}
			else if case let .variableDeclaration(value: variableDeclaration) = convertsToExpression
			{
				let newVariableDeclaration = VariableDeclaration(
					identifier: variableDeclaration.identifier,
					typeName: variableDeclaration.typeName, expression: .nilLiteralExpression,
					getter: nil, setter: nil, isLet: variableDeclaration.isLet, isImplicit: false,
					isStatic: false, extendsType: nil, annotations: variableDeclaration.annotations)
				let translatedVariableDeclaration = try translateVariableDeclaration(
					newVariableDeclaration, withIndentation: indentation)
				let cleanTranslation = translatedVariableDeclaration.dropLast("null\n".count)
				result = "\(cleanTranslation)when ("
			}
		}

		if result.isEmpty {
			result = "\(indentation)when ("
		}

		let expressionTranslation =
			try translateExpression(expression, withIndentation: indentation)
		let increasedIndentation = increaseIndentation(indentation)

		result += "\(expressionTranslation)) {\n"

		for switchCase in cases {
			guard !switchCase.statements.isEmpty else {
				continue
			}

			result += increasedIndentation

			if let caseExpression = switchCase.expression {
				if case let Expression.binaryOperatorExpression(
					leftExpression: declarationReference,
					rightExpression: .typeExpression(type: typeName),
					operatorSymbol: "is",
					type: "Bool") = caseExpression,
					declarationReference == expression
				{
					// TODO: test
					result += "is \(typeName) -> "
				}
				else if case let Expression.binaryOperatorExpression(
					leftExpression: leftExpression, rightExpression: _, operatorSymbol: _,
					type: _) = caseExpression
				{
					let translatedExpression = try translateExpression(
						leftExpression, withIndentation: increasedIndentation)

					// If it's a range
					if case let .templateExpression(pattern: pattern, matches: _) = leftExpression,
						pattern.contains("..") || pattern.contains("until") ||
							pattern.contains("rangeTo")
					{
						result += "in \(translatedExpression) -> "
					}
					else {
						result += "\(translatedExpression) -> "
					}
				}
				else {
					let translatedExpression = try translateExpression(
						caseExpression, withIndentation: increasedIndentation)
					result += "\(translatedExpression) -> "
				}
			}
			else {
				result += "else -> "
			}

			if switchCase.statements.count == 1,
				let onlyStatement = switchCase.statements.first
			{
				let statementTranslation =
					try translate(subtree: onlyStatement, withIndentation: "")
				result += statementTranslation
			}
			else {
				result += "{\n"
				let statementsIndentation = increaseIndentation(increasedIndentation)
				let statementsTranslation = try translate(
					subtrees: switchCase.statements, withIndentation: statementsIndentation,
					limitForAddingNewlines: 3)
				result += "\(statementsTranslation)\(increasedIndentation)}\n"
			}
		}

		result += "\(indentation)}\n"

		return result
	}

	private func translateThrowStatement(
		expression: Expression, withIndentation indentation: String) throws -> String
	{
		let expressionString = try translateExpression(expression, withIndentation: indentation)
		return "\(indentation)throw \(expressionString)\n"
	}

	private func translateReturnStatement(
		expression: Expression?, withIndentation indentation: String) throws -> String
	{
		if let expression = expression {
			let expressionString = try translateExpression(expression, withIndentation: indentation)
			return "\(indentation)return \(expressionString)\n"
		}
		else {
			return "\(indentation)return\n"
		}
	}

	private func translateVariableDeclaration(
		_ variableDeclaration: VariableDeclaration, withIndentation indentation: String)
		throws -> String
	{
		guard !variableDeclaration.isImplicit else {
			return ""
		}

		var result = indentation

		if let annotations = variableDeclaration.annotations {
			result += "\(annotations) "
		}

		var keyword: String
		if variableDeclaration.getter != nil && variableDeclaration.setter != nil {
			keyword = "var"
		}
		else if variableDeclaration.getter != nil && variableDeclaration.setter == nil {
			keyword = "val"
		}
		else {
			if variableDeclaration.isLet {
				keyword = "val"
			}
			else {
				keyword = "var"
			}
		}

		result += "\(keyword) "

		let extensionPrefix: String
		if let extendsType = variableDeclaration.extendsType {
			let translatedExtendedType = translateType(extendsType)

			let genericString: String
			if let genericIndex = translatedExtendedType.index(of: "<") {
				let genericContents = translatedExtendedType.suffix(from: genericIndex)
				genericString = "\(genericContents) "
			}
			else {
				genericString = ""
			}

			extensionPrefix = genericString + translatedExtendedType + "."
		}
		else {
			extensionPrefix = ""
		}

		result += "\(extensionPrefix)\(variableDeclaration.identifier): "

		let translatedType = translateType(variableDeclaration.typeName)
		result += translatedType

		if let expression = variableDeclaration.expression {
			let expressionTranslation =
				try translateExpression(expression, withIndentation: indentation)
			result += " = " + expressionTranslation
		}

		result += "\n"

		let indentation1 = increaseIndentation(indentation)
		let indentation2 = increaseIndentation(indentation1)
		if let getter = variableDeclaration.getter {
			if let statements = getter.statements {
				result += indentation1 + "get() {\n"
				result += try translate(
					subtrees: statements, withIndentation: indentation2, limitForAddingNewlines: 3)
				result += indentation1 + "}\n"
			}
		}

		if let setter = variableDeclaration.setter {
			if let statements = setter.statements {
				result += indentation1 + "set(newValue) {\n"
				result += try translate(
					subtrees: statements, withIndentation: indentation2, limitForAddingNewlines: 3)
				result += indentation1 + "}\n"
			}
		}

		return result
	}

	private func translateAssignmentStatement(
		leftHand: Expression, rightHand: Expression, withIndentation indentation: String)
		throws -> String
	{
		let leftTranslation = try translateExpression(leftHand, withIndentation: indentation)
		let rightTranslation = try translateExpression(rightHand, withIndentation: indentation)
		return "\(indentation)\(leftTranslation) = \(rightTranslation)\n"
	}

	private func translateExpression(
		_ expression: Expression, withIndentation indentation: String) throws -> String
	{
		switch expression {
		case let .templateExpression(pattern: pattern, matches: matches):
			return try translateTemplateExpression(
				pattern: pattern, matches: matches, withIndentation: indentation)
		case .literalCodeExpression(string: let string),
			.literalDeclarationExpression(string: let string):

			return translateLiteralCodeExpression(string: string)
		case let .arrayExpression(elements: elements, type: type):
			return try translateArrayExpression(
				elements: elements, type: type, withIndentation: indentation)
		case let .dictionaryExpression(keys: keys, values: values, type: type):
			return try translateDictionaryExpression(
				keys: keys, values: values, type: type, withIndentation: indentation)
		case let .binaryOperatorExpression(
			leftExpression: leftExpression,
			rightExpression: rightExpression,
			operatorSymbol: operatorSymbol,
			type: type):

			return try translateBinaryOperatorExpression(
				leftExpression: leftExpression,
				rightExpression: rightExpression,
				operatorSymbol: operatorSymbol,
				type: type,
				withIndentation: indentation)
		case let .callExpression(function: function, parameters: parameters, type: type):
			return try translateCallExpression(
				function: function, parameters: parameters, type: type,
				withIndentation: indentation)
		case let .closureExpression(parameters: parameters, statements: statements, type: type):
			return try translateClosureExpression(
				parameters: parameters, statements: statements, type: type,
				withIndentation: indentation)
		case let .declarationReferenceExpression(value: declarationReferenceExpression):
			return translateDeclarationReferenceExpression(declarationReferenceExpression)
		case let .returnExpression(expression: expression):
			return try translateReturnExpression(
				expression: expression, withIndentation: indentation)
		case let .dotExpression(leftExpression: leftExpression, rightExpression: rightExpression):
			return try translateDotSyntaxCallExpression(
				leftExpression: leftExpression,
				rightExpression: rightExpression,
				withIndentation: indentation)
		case let .literalStringExpression(value: value):
			return translateStringLiteral(value: value)
		case let .literalCharacterExpression(value: value):
			return translateCharacterLiteral(value: value)
		case let .interpolatedStringLiteralExpression(expressions: expressions):
			return try translateInterpolatedStringLiteralExpression(
				expressions: expressions, withIndentation: indentation)
		case let .prefixUnaryExpression(
			expression: expression, operatorSymbol: operatorSymbol, type: type):

			return try translatePrefixUnaryExpression(
				expression: expression, operatorSymbol: operatorSymbol, type: type,
				withIndentation: indentation)
		case let .postfixUnaryExpression(
			expression: expression, operatorSymbol: operatorSymbol, type: type):

			return try translatePostfixUnaryExpression(
				expression: expression, operatorSymbol: operatorSymbol, type: type,
				withIndentation: indentation)
		case let .ifExpression(
			condition: condition, trueExpression: trueExpression, falseExpression: falseExpression):

			return try translateIfExpression(
				condition: condition,
				trueExpression: trueExpression,
				falseExpression: falseExpression,
				withIndentation: indentation)
		case let .typeExpression(type: type):
			return translateType(type)
		case let .subscriptExpression(
			subscriptedExpression: subscriptedExpression, indexExpression: indexExpression,
			type: type):

			return try translateSubscriptExpression(
				subscriptedExpression: subscriptedExpression, indexExpression: indexExpression,
				type: type, withIndentation: indentation)
		case let .parenthesesExpression(expression: expression):
			return try "(" + translateExpression(expression, withIndentation: indentation) + ")"
		case let .forceValueExpression(expression: expression):
			return try translateExpression(expression, withIndentation: indentation) + "!!"
		case let .optionalExpression(expression: expression):
			return try translateExpression(expression, withIndentation: indentation) + "?"
		case let .literalIntExpression(value: value):
			return String(value)
		case let .literalUIntExpression(value: value):
			return String(value) + "u"
		case let .literalDoubleExpression(value: value):
			return String(value)
		case let .literalFloatExpression(value: value):
			return String(value) + "f"
		case let .literalBoolExpression(value: value):
			return String(value)
		case .nilLiteralExpression:
			return "null"
		case let .tupleExpression(pairs: pairs):
			return try translateTupleExpression(pairs: pairs, withIndentation: indentation)
		case let .tupleShuffleExpression(
			labels: labels, indices: indices, expressions: expressions):

			return try translateTupleShuffleExpression(
				labels: labels, indices: indices, expressions: expressions,
				withIndentation: indentation)
		case .error:
			return KotlinTranslator.errorTranslation
		}
	}

	private func translateSubscriptExpression(
		subscriptedExpression: Expression, indexExpression: Expression, type: String,
		withIndentation indentation: String)
		throws -> String
	{
		return try translateExpression(subscriptedExpression, withIndentation: indentation) +
			"[\(try translateExpression(indexExpression, withIndentation: indentation))]"
	}

	private func translateArrayExpression(
		elements: [Expression], type: String, withIndentation indentation: String) throws
		-> String
	{
		let expressionsString = try elements.map {
				try translateExpression($0, withIndentation: indentation)
			}.joined(separator: ", ")

		return "mutableListOf(\(expressionsString))"
	}

	private func translateDictionaryExpression(
		keys: [Expression], values: [Expression], type: String,
		withIndentation indentation: String) throws -> String
	{
		let keyExpressions =
			try keys.map { try translateExpression($0, withIndentation: indentation) }
		let valueExpressions =
			try values.map { try translateExpression($0, withIndentation: indentation) }
		let expressionsString =
			zip(keyExpressions, valueExpressions).map { "\($0) to \($1)" }.joined(separator: ", ")

		return "mutableMapOf(\(expressionsString))"
	}

	private func translateReturnExpression(
		expression: Expression?, withIndentation indentation: String) throws -> String
	{
		if let expression = expression {
			let expressionString = try translateExpression(expression, withIndentation: indentation)
			return "return \(expressionString)"
		}
		else {
			return "return"
		}
	}

	private func translateDotSyntaxCallExpression(
		leftExpression: Expression, rightExpression: Expression,
		withIndentation indentation: String) throws -> String
	{
		let leftHandString = try translateExpression(leftExpression, withIndentation: indentation)
		let rightHandString = try translateExpression(rightExpression, withIndentation: indentation)

		if KotlinTranslator.sealedClasses.contains(leftHandString) {
			let translatedEnumCase = rightHandString.capitalizedAsCamelCase
			return "\(leftHandString).\(translatedEnumCase)()"
		}
		else {
			let enumName = leftHandString.split(withStringSeparator: ".").last!
			if KotlinTranslator.enumClasses.contains(enumName) {
				let translatedEnumCase = rightHandString.upperSnakeCase()
				return "\(leftHandString).\(translatedEnumCase)"
			}
			else {
				return "\(leftHandString).\(rightHandString)"
			}
		}
	}

	private func translateBinaryOperatorExpression(
		leftExpression: Expression, rightExpression: Expression, operatorSymbol: String,
		type: String, withIndentation indentation: String) throws -> String
	{
		let leftTranslation = try translateExpression(leftExpression, withIndentation: indentation)
		let rightTranslation =
			try translateExpression(rightExpression, withIndentation: indentation)
		return "\(leftTranslation) \(operatorSymbol) \(rightTranslation)"
	}

	private func translatePrefixUnaryExpression(
		expression: Expression, operatorSymbol: String, type: String,
		withIndentation indentation: String) throws -> String
	{
		let expressionTranslation =
			try translateExpression(expression, withIndentation: indentation)
		return operatorSymbol + expressionTranslation
	}

	private func translatePostfixUnaryExpression(
		expression: Expression, operatorSymbol: String, type: String,
		withIndentation indentation: String) throws -> String
	{
		let expressionTranslation =
			try translateExpression(expression, withIndentation: indentation)
		return expressionTranslation + operatorSymbol
	}

	private func translateIfExpression(
		condition: Expression,
		trueExpression: Expression,
		falseExpression: Expression,
		withIndentation indentation: String) throws -> String
	{
		let conditionTranslation =
			try translateExpression(condition, withIndentation: indentation)
		let trueExpressionTranslation =
			try translateExpression(trueExpression, withIndentation: indentation)
		let falseExpressionTranslation =
			try translateExpression(falseExpression, withIndentation: indentation)

		return "if (\(conditionTranslation)) { \(trueExpressionTranslation) } else " +
			"{ \(falseExpressionTranslation) }"
	}

	private func translateCallExpression(
		function: Expression, parameters: Expression, type: String,
		withIndentation indentation: String, shouldAddNewlines: Bool = false) throws -> String
	{
		var result = ""

		var functionExpression = function
		while case let .dotExpression(
			leftExpression: leftExpression, rightExpression: rightExpression) = functionExpression
		{
			result += try translateExpression(leftExpression, withIndentation: indentation) + "."
			functionExpression = rightExpression
		}

		let functionTranslation: FunctionTranslation?
		if case let .declarationReferenceExpression(value: expression) = functionExpression {
			functionTranslation = KotlinTranslator.getFunctionTranslation(
				forName: expression.identifier,
				type: expression.type)
		}
		else {
			functionTranslation = nil
		}

		let parametersTranslation: String
		if case let .tupleExpression(pairs: pairs) = parameters {
			if let closurePair = pairs.last,
				case let .closureExpression(
					parameters: parameters,
					statements: statements,
					type: type) = closurePair.expression
			{
				let closureTranslation = try translateClosureExpression(
					parameters: parameters,
					statements: statements,
					type: type,
					withIndentation: increaseIndentation(indentation))
				if parameters.count > 1 {
					let firstParametersTranslation = try translateTupleExpression(
						pairs: pairs.dropLast(),
						translation: functionTranslation,
						withIndentation: increaseIndentation(indentation),
						shouldAddNewlines: shouldAddNewlines)
					parametersTranslation = "\(firstParametersTranslation) \(closureTranslation)"
				}
				else {
					parametersTranslation = " \(closureTranslation)"
				}
			}
			else {
				parametersTranslation = try translateTupleExpression(
					pairs: pairs,
					translation: functionTranslation,
					withIndentation: increaseIndentation(indentation),
					shouldAddNewlines: shouldAddNewlines)
			}
		}
		else if case let .tupleShuffleExpression(
			labels: labels, indices: indices, expressions: expressions) = parameters
		{
			parametersTranslation = try translateTupleShuffleExpression(
				labels: labels,
				indices: indices,
				expressions: expressions,
				translation: functionTranslation,
				withIndentation: increaseIndentation(indentation),
				shouldAddNewlines: shouldAddNewlines)
		}
		else {
			return try unexpectedASTStructureError(
				"Expected the parameters to be either a .tupleExpression or a " +
					".tupleShuffleExpression",
				AST: .expression(expression:
					.callExpression(function: function, parameters: parameters, type: type)))
		}

		let prefix = try functionTranslation?.prefix ??
			translateExpression(functionExpression, withIndentation: indentation)

		result += "\(prefix)\(parametersTranslation)"

		if !shouldAddNewlines, result.count >= KotlinTranslator.lineLimit {
			return try translateCallExpression(
				function: function, parameters: parameters, type: type,
				withIndentation: indentation, shouldAddNewlines: true)
		}
		else {
			return result
		}
	}

	private func translateClosureExpression(
		parameters: [LabeledType], statements: [Statement], type: String,
		withIndentation indentation: String) throws -> String
	{
		guard !statements.isEmpty else {
			return "{ }"
		}

		var result = "{"

		let parametersString = parameters.map{ $0.label }.joined(separator: ", ")

		if !parametersString.isEmpty {
			result += " " + parametersString + " ->"
		}

		if statements.count == 1,
			let firstStatement = statements.first,
			case let Statement.expression(expression: expression) = firstStatement
		{
			result += try " " + translateExpression(expression, withIndentation: indentation) + " }"
		}
		else {
			result += "\n"
			let closingBraceIndentation = increaseIndentation(indentation)
			let contentsIndentation = increaseIndentation(closingBraceIndentation)
			result += try translate(subtrees: statements, withIndentation: contentsIndentation)
			result += closingBraceIndentation + "}"
		}

		return result
	}

	private func translateLiteralCodeExpression(string: String) -> String {
		return removeBackslashEscapes(string)
	}

	private func translateTemplateExpression(
		pattern: String, matches: [String: Expression], withIndentation indentation: String)
		throws -> String
	{
		var result = pattern
		for (string, expression) in matches {
			while let range = result.range(of: string) {
				result.replaceSubrange(
					range, with: try translateExpression(expression, withIndentation: indentation))
			}
		}
		return result
	}

	private func translateDeclarationReferenceExpression(
		_ declarationReferenceExpression: DeclarationReferenceExpression) -> String
	{
		return String(declarationReferenceExpression.identifier.prefix { $0 != "(" })
	}

	private func translateTupleExpression(
		pairs: [LabeledExpression], translation: FunctionTranslation? = nil,
		withIndentation indentation: String, shouldAddNewlines: Bool = false) throws -> String
	{
		guard !pairs.isEmpty else {
			return "()"
		}

		// In tuple expressions (when used as parameters for call expressions) there seems to be
		// little risk of triggering errors in Kotlin. Therefore, we can try to omit some parameter
		// labels in the call when they've also been omitted in Swift.
		let parameters: [String?]
		if let translationParameters = translation?.parameters {
			parameters = zip(translationParameters, pairs).map { (translationParameter, pair) in
				if pair.label == nil {
					return nil
				}
				else {
					return translationParameter
				}
			}
		}
		else {
			parameters = pairs.map { $0.label }
		}

		let expressions = pairs.map { $0.expression }

		let expressionIndentation =
			shouldAddNewlines ? increaseIndentation(indentation) : indentation

		let translations = try zip(parameters, expressions)
			.map { (parameter: String?, expression: Expression) -> String in
				let expression =
					try translateExpression(expression, withIndentation: expressionIndentation)

				if let label = parameter {
					return "\(label) = \(expression)"
				}
				else {
					return expression
				}
			}

		if !shouldAddNewlines {
			let contents = translations.joined(separator: ", ")
			return "(\(contents))"
		}
		else {
			let contents = translations.joined(separator: ",\n\(indentation)")
			return "(\n\(indentation)\(contents))"
		}
	}

	private func translateTupleShuffleExpression(
		labels: [String], indices: [TupleShuffleIndex], expressions: [Expression],
		translation: FunctionTranslation? = nil, withIndentation indentation: String,
		shouldAddNewlines: Bool = false) throws -> String
	{
		let parameters = translation?.parameters ?? labels

		let increasedIndentation = increaseIndentation(indentation)

		var translations = [String]()
		var expressionIndex = 0

		// Variadic arguments can't be named, which means all arguments before them can't be named
		// either.
		let containsVariadics = indices.contains { index in
			if case .variadic = index {
				return true
			}
			return false
		}
		var isBeforeVariadic = containsVariadics

		guard parameters.count == indices.count else {
			return try unexpectedASTStructureError(
				"Different number of labels and indices in a tuple shuffle expression. " +
					"Labels: \(labels), indices: \(indices)",
				AST: .expression(expression: .tupleShuffleExpression(
					labels: labels, indices: indices, expressions: expressions)))
		}

		for (label, index) in zip(parameters, indices) {
			switch index {
			case .absent:
				break
			case .present:
				let expression = expressions[expressionIndex]

				var result = ""

				if !isBeforeVariadic {
					result += "\(label) = "
				}

				result += try translateExpression(expression, withIndentation: increasedIndentation)

				translations.append(result)

				expressionIndex += 1
			case let .variadic(count: variadicCount):
				isBeforeVariadic = false
				for _ in 0..<variadicCount {
					let expression = expressions[expressionIndex]
					let result = try translateExpression(
						expression, withIndentation: increasedIndentation)
					translations.append(result)
					expressionIndex += 1
				}
			}
		}

		var result = "("

		if shouldAddNewlines {
			result += "\n\(indentation)"
		}
		let separator = shouldAddNewlines ? ",\n\(indentation)" : ", "

		result += translations.joined(separator: separator) + ")"

		return result
	}

	private func translateStringLiteral(value: String) -> String {
		return "\"\(value)\""
	}

	// TODO: Test chars
	private func translateCharacterLiteral(value: String) -> String {
		return "'\(value)'"
	}

	private func translateInterpolatedStringLiteralExpression(
		expressions: [Expression], withIndentation indentation: String) throws -> String
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
				result +=
					try "${" + translateExpression(expression, withIndentation: indentation) + "}"
			}
		}

		result += "\""

		return result
	}

	// MARK: - Supporting methods
	private func removeBackslashEscapes(_ string: String) -> String {
		var result = ""
		var isEscaping = false

		for character in string {
			if !isEscaping {
				if character == "\\" {
					isEscaping = true
				}
				else {
					result.append(character)
				}
			}
			else {
				switch character {
				case "\\":
					result.append("\\")
				case "n":
					result.append("\n")
				case "t":
					result.append("\t")
				default:
					result.append(character)
					isEscaping = false
				}

				isEscaping = false
			}
		}

		return result
	}

	//
	private func increaseIndentation(_ indentation: String) -> String {
		return indentation + "\t"
	}

	private func decreaseIndentation(_ indentation: String) -> String {
		return String(indentation.dropLast())
	}
}

extension String {
	var capitalizedAsCamelCase: String {
		let firstCharacter = self.first!
		let capitalizedFirstCharacter = String(firstCharacter).uppercased()
		return String(capitalizedFirstCharacter + self.dropFirst())
	}
}

public enum KotlinTranslatorError: Error, CustomStringConvertible {
	case unexpectedASTStructure(
		file: String,
		line: Int,
		function: String,
		message: String,
		AST: Statement)

	public var description: String {
		switch self {
		case let .unexpectedASTStructure(
			file: file, line: line, function: function, message: message, AST: ast):

			var nodeDescription = ""
			ast.prettyPrint(horizontalLimit: 100) {
				nodeDescription += $0
			}

			return "Error: failed to translate Gryphon AST into Kotlin.\n" +
				"On file \(file), line \(line), function \(function).\n" +
				message + ".\n" +
			"Thrown when translating the following AST node:\n\(nodeDescription)"

		}
	}

	public var astName: String {
		switch self {
		case let .unexpectedASTStructure(file: _, line: _, function: _, message: _, AST: ast):
			return ast.name
		}
	}
}

func unexpectedASTStructureError(
	file: String = #file, line: Int = #line, function: String = #function, _ message: String,
	AST ast: Statement) throws -> String
{
	let error = KotlinTranslatorError.unexpectedASTStructure(
		file: file, line: line, function: function, message: message, AST: ast)
	try Compiler.handleError(error)
	return KotlinTranslator.errorTranslation
}
