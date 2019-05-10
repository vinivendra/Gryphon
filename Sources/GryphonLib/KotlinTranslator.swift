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
	// MARK: - Interface - Recording information

	/**
	This variable is used to store enum definitions in order to allow the translator
	to translate them as sealed classes (see the `translate(dotSyntaxCallExpression)` method).
	*/
	private(set) static var sealedClasses: ArrayClass<String> = []

	public static func addSealedClass(_ className: String) {
		sealedClasses.append(className)
	}

	/**
	This variable is used to store enum definitions in order to allow the translator
	to translate them as enum classes (see the `translate(dotSyntaxCallExpression)` method).
	*/
	private(set) static var enumClasses: ArrayClass<String> = []

	public static func addEnumClass(_ className: String) {
		enumClasses.append(className)
	}

	/**
	This variable is used to store protocol definitions in order to allow the translator
	to translate conformances to them correctly (instead of as class inheritances).
	*/
	private(set) static var protocols: ArrayClass<String> = []

	public static func addProtocol(_ protocolName: String) {
		protocols.append(protocolName)
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
		let typeName: String
		let prefix: String
		let parameters: ArrayClass<String>
	}

	private static var functionTranslations: ArrayClass<FunctionTranslation> = []

	public static func addFunctionTranslation(_ newValue: FunctionTranslation) {
		functionTranslations.append(newValue)
	}

	public static func getFunctionTranslation(forName name: String, typeName: String)
		-> FunctionTranslation?
	{
		// Functions with unnamed parameters here are identified only by their prefix. For instance
		// `f(_:_:)` here is named `f` but has been stored earlier as `f(_:_:)`.
		for functionTranslation in functionTranslations {
			if functionTranslation.swiftAPIName.hasPrefix(name),
				functionTranslation.typeName == typeName
			{
				return functionTranslation
			}
		}

		return nil
	}

	// TODO: These records should probably go in a Context class of some kind
	/// Stores pure functions so we can reference them later
	private static var pureFunctions: ArrayClass<FunctionDeclarationData> = []

	public static func recordPureFunction(_ newValue: FunctionDeclarationData) {
		pureFunctions.append(newValue)
	}

	public static func isReferencingPureFunction(
		_ callExpression: CallExpressionData)
		-> Bool
	{
		var finalCallExpression = callExpression.function
		while true {
			if case let .dotExpression(
				leftExpression: _, rightExpression: nextCallExpression) = finalCallExpression
			{
				finalCallExpression = nextCallExpression
			}
			else {
				break
			}
		}

		if case let .declarationReferenceExpression(
			data: declarationReferenceExpression) = finalCallExpression
		{
			for functionDeclaration in pureFunctions {
				if declarationReferenceExpression.identifier.hasPrefix(functionDeclaration.prefix),
					declarationReferenceExpression.typeName == functionDeclaration.functionType
				{
					return true
				}
			}
		}

		return false
	}

	// MARK: - Interface - Translating

	public init() { }

	public func translateAST(_ sourceFile: GryphonAST) throws -> String {
		let declarationsTranslation =
			try translateSubtrees(sourceFile.declarations, withIndentation: "")

		let indentation = increaseIndentation("")
		let statementsTranslation =
			try translateSubtrees(sourceFile.statements, withIndentation: indentation)

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

	// MARK: - Properties for translation

	internal static var indentationString = "\t"

	static let errorTranslation = "<<Error>>"

	static let lineLimit = 100

	// MARK: - Statement translations

	struct TreeAndTranslation {
		let subtree: Statement
		let translation: String
	}

	private func translateSubtrees(
		_ subtrees: ArrayClass<Statement>,
		withIndentation indentation: String,
		limitForAddingNewlines: Int = 0) throws -> String
	{
		let treesAndTranslations = try subtrees.map {
			TreeAndTranslation(
				subtree: $0,
				translation: try translateSubtree($0, withIndentation: indentation))
			}.filter {
				!$0.translation.isEmpty
		}

		if treesAndTranslations.count <= limitForAddingNewlines {
			return treesAndTranslations.map { $0.translation }.joined()
		}

		let treesAndTranslationsWithoutFirst =
			ArrayClass<TreeAndTranslation>(treesAndTranslations.dropFirst())

		var result = ""

		for (currentSubtree, nextSubtree)
			in zipToClass(treesAndTranslations, treesAndTranslationsWithoutFirst)
		{
			result += currentSubtree.translation

			// Cases that should go together
			if case .variableDeclaration = currentSubtree.subtree,
				case .variableDeclaration = nextSubtree.subtree
			{
				continue
			}
			else if case .expressionStatement(
				expression: .callExpression) = currentSubtree.subtree,
				case .expressionStatement(expression: .callExpression) = nextSubtree.subtree
			{
				continue
			}
			else if case .expressionStatement(
				expression: .templateExpression) = currentSubtree.subtree,
				case .expressionStatement(expression: .templateExpression) = nextSubtree.subtree
			{
				continue
			}
			else if case .expressionStatement(
				expression: .literalCodeExpression) = currentSubtree.subtree,
				case .expressionStatement(expression: .literalCodeExpression) = nextSubtree.subtree
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
			else if case .doStatement = currentSubtree.subtree,
				case .catchStatement = nextSubtree.subtree
			{
				continue
			}
			else if case .catchStatement = currentSubtree.subtree,
				case .catchStatement = nextSubtree.subtree
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

	private func translateSubtree(
		_ subtree: Statement,
		withIndentation indentation: String)
		throws -> String
	{
		let result: String

		switch subtree {
		case .importDeclaration:
			result = ""
		case .extensionDeclaration:
			return try unexpectedASTStructureError(
				"Extension structure should have been removed in a transpilation pass",
				AST: subtree)
		case .deferStatement:
			return try unexpectedASTStructureError(
				"Defer statements are only supported as top-level statements in function bodies",
				AST: subtree)
		case let .typealiasDeclaration(
			identifier: identifier, typeName: typeName, isImplicit: isImplicit):

			result = try translateTypealias(
				identifier: identifier, typeName: typeName, isImplicit: isImplicit,
				withIndentation: indentation)
		case let .classDeclaration(className: className, inherits: inherits, members: members):
			result = try translateClassDeclaration(
				className: className,
				inherits: inherits,
				members: members,
				withIndentation: indentation)
		case let .structDeclaration(
			annotations: annotations, structName: structName, inherits: inherits, members: members):

			result = try translateStructDeclaration(
				annotations: annotations,
				structName: structName,
				inherits: inherits,
				members: members,
				withIndentation: indentation)
		case let .companionObject(members: members):
			result = try translateCompanionObject(
				members: members, withIndentation: indentation)
		case let .enumDeclaration(
			access: access,
			enumName: enumName,
			inherits: inherits,
			elements: elements,
			members: members,
			isImplicit: isImplicit):

			result = try translateEnumDeclaration(
				access: access,
				enumName: enumName,
				inherits: inherits,
				elements: elements,
				members: members,
				isImplicit: isImplicit,
				withIndentation: indentation)
		case let .doStatement(statements: statements):
			result = try translateDoStatement(
				statements: statements,
				withIndentation: indentation)
		case let .catchStatement(variableDeclaration: variableDeclaration, statements: statements):
			result = try translateCatchStatement(
				variableDeclaration: variableDeclaration,
				statements: statements,
				withIndentation: indentation)
		case let .forEachStatement(
			collection: collection, variable: variable, statements: statements):

			result = try translateForEachStatement(
				collection: collection, variable: variable, statements: statements,
				withIndentation: indentation)
		case let .whileStatement(expression: expression, statements: statements):
			result = try translateWhileStatement(
				expression: expression, statements: statements, withIndentation: indentation)
		case let .functionDeclaration(data: functionDeclaration):
			result = try translateFunctionDeclaration(
				functionDeclaration: functionDeclaration, withIndentation: indentation)
		case let .protocolDeclaration(protocolName: protocolName, members: members):
			result = try translateProtocolDeclaration(
				protocolName: protocolName, members: members, withIndentation: indentation)
		case let .throwStatement(expression: expression):
			result = try translateThrowStatement(
				expression: expression, withIndentation: indentation)
		case let .variableDeclaration(data: variableDeclaration):
			result = try translateVariableDeclaration(
				variableDeclaration, withIndentation: indentation)
		case let .assignmentStatement(leftHand: leftHand, rightHand: rightHand):
			result = try translateAssignmentStatement(
				leftHand: leftHand, rightHand: rightHand, withIndentation: indentation)
		case let .ifStatement(data: ifStatement):
			result = try translateIfStatement(ifStatement, withIndentation: indentation)
		case let .switchStatement(
			convertsToExpression: convertsToExpression, expression: expression,
			cases: cases):

			result = try translateSwitchStatement(
				convertsToExpression: convertsToExpression,
				expression: expression,
				cases: cases,
				withIndentation: indentation)
		case let .returnStatement(expression: expression):
			result = try translateReturnStatement(
				expression: expression, withIndentation: indentation)
		case .breakStatement:
			result = "\(indentation)break\n"
		case .continueStatement:
			result = "\(indentation)continue\n"
		case let .expressionStatement(expression: expression):
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

	private func translateEnumDeclaration(
		access: String?,
		enumName: String,
		inherits: ArrayClass<String>,
		elements: ArrayClass<EnumElement>,
		members: ArrayClass<Statement>,
		isImplicit: Bool,
		withIndentation indentation: String)
		throws -> String
	{
		let isEnumClass = KotlinTranslator.enumClasses.contains(enumName)

		let accessString = access ?? ""
		let enumString = isEnumClass ? "enum" : "sealed"

		var result = "\(indentation)\(accessString) \(enumString) class " + enumName

		if !inherits.isEmpty {
			var translatedInheritedTypes = inherits.map { translateType($0) }
			translatedInheritedTypes = translatedInheritedTypes.map {
				KotlinTranslator.protocols.contains($0) ?
					$0 :
					$0 + "()"
			}
			result += ": \(translatedInheritedTypes.joined(separator: ", "))"
		}

		result += " {\n"

		let increasedIndentation = increaseIndentation(indentation)

		var casesTranslation = ""
		if isEnumClass {
			casesTranslation += elements.map {
					increasedIndentation +
						(($0.annotations == nil) ? "" : "\($0.annotations!) ") +
						$0.name
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
			try translateSubtrees(members, withIndentation: increasedIndentation)

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
		let capitalizedElementName = element.name.capitalizedAsCamelCase()
		let annotationsString = (element.annotations == nil) ? "" : "\(element.annotations!) "

		let result = "\(indentation)\(annotationsString)class \(capitalizedElementName)"

		if element.associatedValues.isEmpty {
			return result + ": \(enumName)()\n"
		}
		else {
			let associatedValuesString =
				element.associatedValues
					.map { "val \($0.label): \(translateType($0.typeName))" }
					.joined(separator: ", ")
			return result + "(\(associatedValuesString)): \(enumName)()\n"
		}
	}

	private func translateProtocolDeclaration(
		protocolName: String,
		members: ArrayClass<Statement>,
		withIndentation indentation: String)
		throws -> String
	{
		var result = "\(indentation)interface \(protocolName) {\n"
		let contents = try translateSubtrees(
			members, withIndentation: increaseIndentation(indentation))
		result += contents
		result += "\(indentation)}\n"
		return result
	}

	private func translateTypealias(
		identifier: String,
		typeName: String,
		isImplicit: Bool,
		withIndentation indentation: String)
		throws -> String
	{
		let translatedType = translateType(typeName)
		return "\(indentation)typealias \(identifier) = \(translatedType)\n"
	}

	private func translateClassDeclaration(
		className: String,
		inherits: ArrayClass<String>,
		members: ArrayClass<Statement>,
		withIndentation indentation: String)
		throws -> String
	{
		var result = "\(indentation)open class \(className)"

		if !inherits.isEmpty {
			let translatedInheritances = inherits.map { translateType($0) }
			result += ": " + translatedInheritances.joined(separator: ", ")
		}

		result += " {\n"

		let increasedIndentation = increaseIndentation(indentation)

		let classContents = try translateSubtrees(
			members,
			withIndentation: increasedIndentation)

		result += classContents + "\(indentation)}\n"

		return result
	}

	/// If a value type's members are all immutable, that value type can safely be translated as a
	/// class. Source: https://forums.swift.org/t/are-immutable-structs-like-classes/16270
	private func translateStructDeclaration(
		annotations: String?,
		structName: String,
		inherits: ArrayClass<String>,
		members: ArrayClass<Statement>,
		withIndentation indentation: String)
		throws -> String
	{
		let increasedIndentation = increaseIndentation(indentation)

		let annotationsString = annotations.map { "\(indentation)\($0)\n" } ?? ""

		var result = "\(annotationsString)\(indentation)data class \(structName)(\n"

		let properties = members.filter { statementIsStructProperty($0) }
		let otherMembers = members.filter { !statementIsStructProperty($0) }

		// Translate properties individually, dropping the newlines at the end
		let propertyTranslations = try properties.map {
			try String(translateSubtree($0, withIndentation: increasedIndentation).dropLast())
		}
		let propertiesTranslation = propertyTranslations.joined(separator: ",\n")

		result += propertiesTranslation + "\n\(indentation))"

		if !inherits.isEmpty {
			var translatedInheritedTypes = inherits.map { translateType($0) }
			translatedInheritedTypes = translatedInheritedTypes.map {
				KotlinTranslator.protocols.contains($0) ?
					$0 :
					$0 + "()"
			}
			result += ": \(translatedInheritedTypes.joined(separator: ", "))"
		}

		let otherMembersTranslation = try translateSubtrees(
			otherMembers,
			withIndentation: increasedIndentation)

		if !otherMembersTranslation.isEmpty {
			result += " {\n\(otherMembersTranslation)\(indentation)}\n"
		}
		else {
			result += "\n"
		}

		return result
	}

	private func statementIsStructProperty(
		_ statement: Statement)
		-> Bool
	{
		if case let .variableDeclaration(data: variableDeclaration) = statement {
			if variableDeclaration.getter == nil,
				variableDeclaration.setter == nil,
				!variableDeclaration.isStatic
			{
				return true
			}
		}

		return false
	}

	private func translateCompanionObject(
		members: ArrayClass<Statement>,
		withIndentation indentation: String)
		throws -> String
	{
		var result = "\(indentation)companion object {\n"

		let increasedIndentation = increaseIndentation(indentation)

		let contents = try translateSubtrees(
			members,
			withIndentation: increasedIndentation)

		result += contents + "\(indentation)}\n"

		return result
	}

	private func translateFunctionDeclaration(
		functionDeclaration: FunctionDeclarationData, withIndentation indentation: String,
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
						.map { String($0) }
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

		let parameterStrings = try functionDeclaration.parameters
			.map { try translateFunctionDeclarationParameter($0, withIndentation: indentation) }

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
		let innerDeferStatements = statements.flatMap { extractInnerDeferStatements($0) }
		// Get all other statements
		let nonDeferStatements = statements.filter { !isDeferStatement($0) }

		indentation = increaseIndentation(indentation)

		if !innerDeferStatements.isEmpty {
			let increasedIndentation = increaseIndentation(indentation)
			result += "\(indentation)try {\n"
			result += try translateSubtrees(
				nonDeferStatements,
				withIndentation: increasedIndentation,
				limitForAddingNewlines: 3)
			result += "\(indentation)}\n"
			result += "\(indentation)finally {\n"
			result += try translateSubtrees(
				innerDeferStatements,
				withIndentation: increasedIndentation,
				limitForAddingNewlines: 3)
			result += "\(indentation)}\n"
		}
		else {
			result += try translateSubtrees(
				statements,
				withIndentation: indentation,
				limitForAddingNewlines: 3)
		}

		indentation = decreaseIndentation(indentation)
		result += indentation + "}\n"

		return result
	}

	private func isDeferStatement(
		_ maybeDeferStatement: Statement)
		-> Bool
	{
		if case .deferStatement = maybeDeferStatement {
			return true
		}
		else {
			return false
		}
	}

	private func extractInnerDeferStatements(
		_ maybeDeferStatement: Statement)
		-> ArrayClass<Statement>
	{
		if case let .deferStatement(statements: innerStatements) = maybeDeferStatement {
			return innerStatements
		}
		else {
			return []
		}
	}

	private func translateFunctionDeclarationParameter(
		_ parameter: FunctionParameter,
		withIndentation indentation: String)
		throws -> String
	{
		let labelAndTypeString = parameter.label + ": " + translateType(parameter.typeName)
		if let defaultValue = parameter.value {
			return try labelAndTypeString + " = "
				+ translateExpression(defaultValue, withIndentation: indentation)
		}
		else {
			return labelAndTypeString
		}
	}

	private func translateDoStatement(
		statements: ArrayClass<Statement>,
		withIndentation indentation: String)
		throws -> String
	{
		let translatedStatements = try translateSubtrees(
			statements,
			withIndentation: increaseIndentation(indentation),
			limitForAddingNewlines: 3)
		return "\(indentation)try {\n\(translatedStatements)\(indentation)}\n"
	}

	private func translateCatchStatement(
		variableDeclaration: VariableDeclarationData?,
		statements: ArrayClass<Statement>,
		withIndentation indentation: String)
		throws -> String
	{
		var result = ""

		if let variableDeclaration = variableDeclaration {
			let translatedType = translateType(variableDeclaration.typeName)
			result = "\(indentation)catch " +
			"(\(variableDeclaration.identifier): \(translatedType)) {\n"
		}
		else {
			result = "\(indentation)catch {\n"
		}

		let translatedStatements = try translateSubtrees(
			statements,
			withIndentation: increaseIndentation(indentation),
			limitForAddingNewlines: 3)

		result += "\(translatedStatements)"
		result += "\(indentation)}\n"

		return result
	}

	private func translateForEachStatement(
		collection: Expression,
		variable: Expression,
		statements: ArrayClass<Statement>,
		withIndentation indentation: String)
		throws -> String
	{
		var result = "\(indentation)for ("

		let variableTranslation = try translateExpression(variable, withIndentation: indentation)

		result += variableTranslation + " in "

		let collectionTranslation =
			try translateExpression(collection, withIndentation: indentation)

		result += collectionTranslation + ") {\n"

		let increasedIndentation = increaseIndentation(indentation)
		let statementsTranslation = try translateSubtrees(
			statements, withIndentation: increasedIndentation, limitForAddingNewlines: 3)

		result += statementsTranslation

		result += indentation + "}\n"
		return result
	}

	// TODO: Update stdlib tests
	// TODO: Test whiles
	private func translateWhileStatement(
		expression: Expression,
		statements: ArrayClass<Statement>,
		withIndentation indentation: String)
		throws -> String
	{
		var result = "\(indentation)while ("

		let expressionTranslation =
			try translateExpression(expression, withIndentation: indentation)
		result += expressionTranslation + ") {\n"

		let increasedIndentation = increaseIndentation(indentation)
		let statementsTranslation = try translateSubtrees(
			statements, withIndentation: increasedIndentation, limitForAddingNewlines: 3)

		result += statementsTranslation

		result += indentation + "}\n"
		return result
	}

	private func translateIfStatement(
		_ ifStatement: IfStatementData,
		isElseIf: Bool = false,
		withIndentation indentation: String)
		throws -> String
	{
		let keyword = (ifStatement.conditions.isEmpty && ifStatement.declarations.isEmpty) ?
			"else" :
			(isElseIf ? "else if" : "if")

		var result = indentation + keyword + " "

		let increasedIndentation = increaseIndentation(indentation)

		let conditionsTranslation = try ifStatement.conditions.compactMap {
				conditionToExpression($0)
			}.map {
				try translateExpression($0, withIndentation: indentation)
			}.joined(separator: " && ")

		if keyword != "else" {
			let parenthesizedCondition = ifStatement.isGuard ?
				("(!(" + conditionsTranslation + ")) ") :
				("(" + conditionsTranslation + ") ")

			result += parenthesizedCondition
		}

		result += "{\n"

		let statementsString = try translateSubtrees(
			ifStatement.statements,
			withIndentation: increasedIndentation,
			limitForAddingNewlines: 3)

		result += statementsString + indentation + "}\n"

		if let unwrappedElse = ifStatement.elseStatement {
			result += try translateIfStatement(
				unwrappedElse, isElseIf: true, withIndentation: indentation)
		}

		return result
	}

	private func conditionToExpression(_ condition: IfStatementData.IfCondition) -> Expression? {
		if case let .condition(expression: expression) = condition {
			return expression
		}
		else {
			return nil
		}
	}

	private func translateSwitchStatement(
		convertsToExpression: Statement?,
		expression: Expression,
		cases: ArrayClass<SwitchCase>,
		withIndentation indentation: String)
		throws -> String
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
			else if case let .variableDeclaration(data: variableDeclaration) = convertsToExpression
			{
				let newVariableDeclaration = VariableDeclarationData(
					identifier: variableDeclaration.identifier,
					typeName: variableDeclaration.typeName,
					expression: .nilLiteralExpression,
					getter: nil,
					setter: nil,
					isLet: variableDeclaration.isLet,
					isImplicit: false,
					isStatic: false,
					extendsType: nil,
					annotations: variableDeclaration.annotations)
				let translatedVariableDeclaration = try translateVariableDeclaration(
					newVariableDeclaration,
					withIndentation: indentation)
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

			let translatedExpressions: ArrayClass<String> = []

			for caseExpression in switchCase.expressions {
				let translatedExpression = try translateSwitchCaseExpression(
					caseExpression,
					withSwitchExpression: expression,
					indentation: increasedIndentation)
				translatedExpressions.append(translatedExpression)
			}

			if translatedExpressions.isEmpty {
				result += "else -> "
			}
			else {
				result += translatedExpressions.joined(separator: ", ") + " -> "
			}

			if switchCase.statements.count == 1,
				let onlyStatement = switchCase.statements.first
			{
				let statementTranslation =
					try translateSubtree(onlyStatement, withIndentation: "")
				result += statementTranslation
			}
			else {
				result += "{\n"
				let statementsIndentation = increaseIndentation(increasedIndentation)
				let statementsTranslation = try translateSubtrees(
					switchCase.statements,
					withIndentation: statementsIndentation,
					limitForAddingNewlines: 3)
				result += "\(statementsTranslation)\(increasedIndentation)}\n"
			}
		}

		result += "\(indentation)}\n"

		return result
	}

	private func translateSwitchCaseExpression(
		_ caseExpression: Expression,
		withSwitchExpression switchExpression: Expression,
		indentation: String)
		throws -> String
	{
		if case let Expression.binaryOperatorExpression(
			leftExpression: leftExpression,
			rightExpression: rightExpression,
			operatorSymbol: operatorSymbol,
			typeName: typeName) = caseExpression
		{
			if leftExpression == switchExpression, operatorSymbol == "is", typeName == "Bool" {
				// TODO: test
				let translatedType = try translateExpression(
					rightExpression,
					withIndentation: indentation)
				return "is \(translatedType)"
			}
			else {
				let translatedExpression = try translateExpression(
					leftExpression,
					withIndentation: indentation)

				// If it's a range
				if case let .templateExpression(pattern: pattern, matches: _) = leftExpression {
					if pattern.contains("..") || pattern.contains("until") ||
						pattern.contains("rangeTo")
					{
						return "in \(translatedExpression)"
					}
				}

				return translatedExpression
			}
		}

		let translatedExpression = try translateExpression(
			caseExpression,
			withIndentation: indentation)
		return translatedExpression
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
		_ variableDeclaration: VariableDeclarationData,
		withIndentation indentation: String)
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
				result += try translateSubtrees(
					statements,
					withIndentation: indentation2,
					limitForAddingNewlines: 3)
				result += indentation1 + "}\n"
			}
		}

		if let setter = variableDeclaration.setter {
			if let statements = setter.statements {
				result += indentation1 + "set(newValue) {\n"
				result += try translateSubtrees(
					statements,
					withIndentation: indentation2,
					limitForAddingNewlines: 3)
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

	// MARK: - Expression translations

	private func translateExpression(
		_ expression: Expression,
		withIndentation indentation: String)
		throws -> String
	{
		switch expression {
		case let .templateExpression(pattern: pattern, matches: matches):
			return try translateTemplateExpression(
				pattern: pattern, matches: matches, withIndentation: indentation)
		case let .literalCodeExpression(string: string):
			return translateLiteralCodeExpression(string: string)
		case let .literalDeclarationExpression(string: string):
			return translateLiteralCodeExpression(string: string)
		case let .arrayExpression(elements: elements, typeName: typeName):
			return try translateArrayExpression(
				elements: elements, typeName: typeName, withIndentation: indentation)
		case let .dictionaryExpression(keys: keys, values: values, typeName: typeName):
			return try translateDictionaryExpression(
				keys: keys,
				values: values,
				typeName: typeName,
				withIndentation: indentation)
		case let .binaryOperatorExpression(
			leftExpression: leftExpression,
			rightExpression: rightExpression,
			operatorSymbol: operatorSymbol,
			typeName: typeName):

			return try translateBinaryOperatorExpression(
				leftExpression: leftExpression,
				rightExpression: rightExpression,
				operatorSymbol: operatorSymbol,
				typeName: typeName,
				withIndentation: indentation)
		case let .callExpression(data: callExpression):
			return try translateCallExpression(callExpression, withIndentation: indentation)
		case let .closureExpression(
			parameters: parameters, statements: statements, typeName: typeName):

			return try translateClosureExpression(
				parameters: parameters, statements: statements, typeName: typeName,
				withIndentation: indentation)
		case let .declarationReferenceExpression(data: declarationReferenceExpression):
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
			subExpression: subExpression, operatorSymbol: operatorSymbol, typeName: typeName):

			return try translatePrefixUnaryExpression(
				subExpression: subExpression, operatorSymbol: operatorSymbol, typeName: typeName,
				withIndentation: indentation)
		case let .postfixUnaryExpression(
			subExpression: subExpression, operatorSymbol: operatorSymbol, typeName: typeName):

			return try translatePostfixUnaryExpression(
				subExpression: subExpression, operatorSymbol: operatorSymbol, typeName: typeName,
				withIndentation: indentation)
		case let .ifExpression(
			condition: condition, trueExpression: trueExpression, falseExpression: falseExpression):

			return try translateIfExpression(
				condition: condition,
				trueExpression: trueExpression,
				falseExpression: falseExpression,
				withIndentation: indentation)
		case let .typeExpression(typeName: typeName):
			return translateType(typeName)
		case let .subscriptExpression(
			subscriptedExpression: subscriptedExpression, indexExpression: indexExpression,
			typeName: typeName):

			return try translateSubscriptExpression(
				subscriptedExpression: subscriptedExpression, indexExpression: indexExpression,
				typeName: typeName, withIndentation: indentation)
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
		subscriptedExpression: Expression,
		indexExpression: Expression,
		typeName: String,
		withIndentation indentation: String)
		throws -> String
	{
		return try translateExpression(subscriptedExpression, withIndentation: indentation) +
		"[\(try translateExpression(indexExpression, withIndentation: indentation))]"
	}

	private func translateArrayExpression(
		elements: ArrayClass<Expression>,
		typeName: String,
		withIndentation indentation: String)
		throws -> String
	{
		let expressionsString = try elements.map {
			try translateExpression($0, withIndentation: indentation)
			}.joined(separator: ", ")

		return "mutableListOf(\(expressionsString))"
	}

	private func translateDictionaryExpression(
		keys: ArrayClass<Expression>,
		values: ArrayClass<Expression>,
		typeName: String,
		withIndentation indentation: String)
		throws -> String
	{
		let keyExpressions =
			try keys.map { try translateExpression($0, withIndentation: indentation) }
		let valueExpressions =
			try values.map { try translateExpression($0, withIndentation: indentation) }
		let expressionsString = zipToClass(keyExpressions, valueExpressions).map { keyValueTuple in
				"\(keyValueTuple.0) to \(keyValueTuple.1)"
			}.joined(separator: ", ")

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
			let translatedEnumCase = rightHandString.capitalizedAsCamelCase()
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
		leftExpression: Expression,
		rightExpression: Expression,
		operatorSymbol: String,
		typeName: String,
		withIndentation indentation: String)
		throws -> String
	{
		let leftTranslation = try translateExpression(leftExpression, withIndentation: indentation)
		let rightTranslation =
			try translateExpression(rightExpression, withIndentation: indentation)
		return "\(leftTranslation) \(operatorSymbol) \(rightTranslation)"
	}

	private func translatePrefixUnaryExpression(
		subExpression: Expression,
		operatorSymbol: String,
		typeName: String,
		withIndentation indentation: String) throws -> String
	{
		let expressionTranslation =
			try translateExpression(subExpression, withIndentation: indentation)
		return operatorSymbol + expressionTranslation
	}

	private func translatePostfixUnaryExpression(
		subExpression: Expression,
		operatorSymbol: String,
		typeName: String,
		withIndentation indentation: String) throws -> String
	{
		let expressionTranslation =
			try translateExpression(subExpression, withIndentation: indentation)
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
		_ callExpression: CallExpressionData,
		withIndentation indentation: String,
		shouldAddNewlines: Bool = false)
		throws -> String
	{
		var result = ""

		var functionExpression = callExpression.function
		while true {
			if case let .dotExpression(
				leftExpression: leftExpression,
				rightExpression: rightExpression) = functionExpression
			{
				result += try translateExpression(
					leftExpression,
					withIndentation: indentation) + "."
				functionExpression = rightExpression
			}
			else {
				break
			}
		}

		let functionTranslation: FunctionTranslation?
		if case let .declarationReferenceExpression(data: expression) = functionExpression {
			functionTranslation = KotlinTranslator.getFunctionTranslation(
				forName: expression.identifier,
				typeName: expression.typeName)
		}
		else {
			functionTranslation = nil
		}

		let prefix = try functionTranslation?.prefix ??
			translateExpression(functionExpression, withIndentation: indentation)

		let parametersTranslation = try translateParameters(
			forCallExpression: callExpression,
			withFunctionTranslation: functionTranslation,
			withIndentation: indentation,
			shouldAddNewlines: shouldAddNewlines)

		result += "\(prefix)\(parametersTranslation)"

		if !shouldAddNewlines, result.count >= KotlinTranslator.lineLimit {
			return try translateCallExpression(
				callExpression,
				withIndentation: indentation,
				shouldAddNewlines: true)
		}
		else {
			return result
		}
	}

	private func translateParameters(
		forCallExpression callExpression: CallExpressionData,
		withFunctionTranslation functionTranslation: FunctionTranslation?,
		withIndentation indentation: String,
		shouldAddNewlines: Bool)
		throws -> String
	{
		if case let .tupleExpression(pairs: pairs) = callExpression.parameters {
			if let closurePair = pairs.last {
				if case let .closureExpression(
					parameters: parameters,
					statements: statements,
					typeName: typeName) = closurePair.expression
				{
					let closureTranslation = try translateClosureExpression(
						parameters: parameters,
						statements: statements,
						typeName: typeName,
						withIndentation: increaseIndentation(indentation))
					if parameters.count > 1 {
						let firstParametersTranslation = try translateTupleExpression(
							pairs: ArrayClass<LabeledExpression>(pairs.dropLast()),
							translation: functionTranslation,
							withIndentation: increaseIndentation(indentation),
							shouldAddNewlines: shouldAddNewlines)
						return "\(firstParametersTranslation) \(closureTranslation)"
					}
					else {
						return " \(closureTranslation)"
					}
				}
			}

			return try translateTupleExpression(
				pairs: pairs,
				translation: functionTranslation,
				withIndentation: increaseIndentation(indentation),
				shouldAddNewlines: shouldAddNewlines)
		}
		else if case let .tupleShuffleExpression(
			labels: labels, indices: indices, expressions: expressions) = callExpression.parameters
		{
			return try translateTupleShuffleExpression(
				labels: labels,
				indices: indices,
				expressions: expressions,
				translation: functionTranslation,
				withIndentation: increaseIndentation(indentation),
				shouldAddNewlines: shouldAddNewlines)
		}

		return try unexpectedASTStructureError(
			"Expected the parameters to be either a .tupleExpression or a " +
			".tupleShuffleExpression",
			AST: .expressionStatement(expression: .callExpression(data: callExpression)))
	}

	private func translateClosureExpression(
		parameters: ArrayClass<LabeledType>,
		statements: ArrayClass<Statement>,
		typeName: String,
		withIndentation indentation: String)
		throws -> String
	{
		guard !statements.isEmpty else {
			return "{ }"
		}

		var result = "{"

		let parametersString = parameters.map{ $0.label }.joined(separator: ", ")

		if !parametersString.isEmpty {
			result += " " + parametersString + " ->"
		}

		let firstStatement = statements.first
		if statements.count == 1,
			let firstStatement = firstStatement,
			case let .expressionStatement(expression: expression) = firstStatement
		{
			result += try " " + translateExpression(expression, withIndentation: indentation) + " }"
		}
		else {
			result += "\n"
			let closingBraceIndentation = increaseIndentation(indentation)
			let contentsIndentation = increaseIndentation(closingBraceIndentation)
			result += try translateSubtrees(statements, withIndentation: contentsIndentation)
			result += closingBraceIndentation + "}"
		}

		return result
	}

	private func translateLiteralCodeExpression(string: String) -> String {
		return string.removingBackslashEscapes
	}

	private func translateTemplateExpression(
		pattern: String,
		matches: DictionaryClass<String, Expression>,
		withIndentation indentation: String)
		throws -> String
	{
		var result = pattern
		for (string, expression) in matches {
			let expressionTranslation =
				try translateExpression(expression, withIndentation: indentation)
			result = result.replacingOccurrences(of: string, with: expressionTranslation)
		}
		return result
	}

	private func translateDeclarationReferenceExpression(
		_ declarationReferenceExpression: DeclarationReferenceData) -> String
	{
		return String(declarationReferenceExpression.identifier.prefix {
			$0 !=
				"(" // value: '('
		})
	}

	private func translateTupleExpression(
		pairs: ArrayClass<LabeledExpression>,
		translation: FunctionTranslation? = nil,
		withIndentation indentation: String,
		shouldAddNewlines: Bool = false)
		throws -> String
	{
		guard !pairs.isEmpty else {
			return "()"
		}

		// In tuple expressions (when used as parameters for call expressions) there seems to be
		// little risk of triggering errors in Kotlin. Therefore, we can try to omit some parameter
		// labels in the call when they've also been omitted in Swift.
		let parameters: ArrayClass<String?>
		if let translationParameters = translation?.parameters {
			parameters = zipToClass(translationParameters, pairs).map
				{ translationPairTuple in
					(translationPairTuple.1.label == nil) ? nil : translationPairTuple.0
				}
		}
		else {
			parameters = pairs.map { $0.label }
		}

		let expressions = pairs.map { $0.expression }

		let expressionIndentation =
			shouldAddNewlines ? increaseIndentation(indentation) : indentation

		let translations = try zipToClass(parameters, expressions)
			.map { parameterExpressionTuple -> String in
				try translateParameter(
					withLabel: parameterExpressionTuple.0,
					expression: parameterExpressionTuple.1,
					indentation: expressionIndentation)
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

	private func translateParameter(
		withLabel label: String?,
		expression: Expression,
		indentation: String)
		throws -> String
	{
		let expression = try translateExpression(expression, withIndentation: indentation)

		if let label = label {
			return "\(label) = \(expression)"
		}
		else {
			return expression
		}
	}

	private func translateTupleShuffleExpression(
		labels: ArrayClass<String>,
		indices: ArrayClass<TupleShuffleIndex>,
		expressions: ArrayClass<Expression>,
		translation: FunctionTranslation? = nil,
		withIndentation indentation: String,
		shouldAddNewlines: Bool = false)
		throws -> String
	{
		let parameters = translation?.parameters ?? labels

		let increasedIndentation = increaseIndentation(indentation)

		let translations: ArrayClass<String> = []
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
				AST: .expressionStatement(expression: .tupleShuffleExpression(
					labels: labels,
					indices: indices,
					expressions: expressions)))
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
		expressions: ArrayClass<Expression>,
		withIndentation indentation: String)
		throws -> String
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

	internal func translateType(_ typeName: String) -> String {
		let typeName = typeName.replacingOccurrences(of: "()", with: "Unit")

		if typeName.hasSuffix("?") {
			return translateType(String(typeName.dropLast())) + "?"
		}
		else if typeName.hasPrefix("[") {
			if typeName.contains(":") {
				let innerType = String(typeName.dropLast().dropFirst())
				let innerTypes = Utilities.splitTypeList(innerType)
				let keyType = innerTypes[0]
				let valueType = innerTypes[1]
				let translatedKey = translateType(keyType)
				let translatedValue = translateType(valueType)
				return "MutableMap<\(translatedKey), \(translatedValue)>"
			}
			else {
				let innerType = String(typeName.dropLast().dropFirst())
				let translatedInnerType = translateType(innerType)
				return "MutableList<\(translatedInnerType)>"
			}
		}
		else if typeName.hasPrefix("ArrayClass<") {
			let innerType = String(typeName.dropLast().dropFirst("ArrayClass<".count))
			let translatedInnerType = translateType(innerType)
			return "MutableList<\(translatedInnerType)>"
		}
		else if typeName.hasPrefix("DictionaryClass<") {
			let innerTypes = String(typeName.dropLast().dropFirst("DictionaryClass<".count))
			let keyValue = Utilities.splitTypeList(innerTypes)
			let key = keyValue[0]
			let value = keyValue[1]
			let translatedKey = translateType(key)
			let translatedValue = translateType(value)
			return "MutableMap<\(translatedKey), \(translatedValue)>"
		}
		else if Utilities.isInEnvelopingParentheses(typeName) {
			let innerTypeString = String(typeName.dropFirst().dropLast())
			let innerTypes = Utilities.splitTypeList(innerTypeString, separators: [", "])
			if innerTypes.count == 2 {
				return "Pair<\(innerTypes.joined(separator: ", "))>"
			}
			else {
				return translateType(String(typeName.dropFirst().dropLast()))
			}
		}
		else if typeName.contains(" -> ") {
			let functionComponents = Utilities.splitTypeList(typeName, separators: [" -> "])
			let translatedComponents = functionComponents.map {
				translateFunctionTypeComponent($0)
			}

			let firstTypes = translatedComponents.dropLast().map { "(\($0))" }
			let lastType = translatedComponents.last!

			var allTypes = firstTypes
			allTypes.append(lastType)
			return allTypes.joined(separator: " -> ")
		}
		else {
			return Utilities.getTypeMapping(for: typeName) ?? typeName
		}
	}

	private func translateFunctionTypeComponent(_ component: String) -> String {
		if Utilities.isInEnvelopingParentheses(component) {
			let openComponent = String(component.dropFirst().dropLast())
			let componentParts = Utilities.splitTypeList(openComponent, separators: [", "])
			let translatedParts = componentParts.map { translateType($0) }
			return translatedParts.joined(separator: ", ")
		}
		else {
			return translateType(component)
		}
	}

	private func increaseIndentation(_ indentation: String) -> String {
		return indentation + KotlinTranslator.indentationString
	}

	private func decreaseIndentation(_ indentation: String) -> String {
		return String(indentation.dropLast(KotlinTranslator.indentationString.count))
	}
}

// MARK: - Error handling

struct KotlinTranslatorError: Error, CustomStringConvertible {
	let errorMessage: String
	let ast: Statement

	public var description: String { // annotation: override
		var nodeDescription = ""
		ast.prettyPrint(horizontalLimit: 100) {
			nodeDescription += $0
		}

		return "Error: failed to translate Gryphon AST into Kotlin.\n" +
			errorMessage + ".\n" +
			"Thrown when translating the following AST node:\n\(nodeDescription)"
	}
}

func unexpectedASTStructureError(
	_ errorMessage: String,
	AST ast: Statement)
	throws -> String
{
	let error = KotlinTranslatorError(errorMessage: errorMessage, ast: ast)
	try Compiler.handleError(error)
	return KotlinTranslator.errorTranslation
}
