//
// Copyright 2018 Vinícius Jorge Vendramini
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
// http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.
//

import Foundation

public class SwiftTranslator {
	// MARK: - Properties

	var danglingPatternBindings: ArrayClass<PatternBindingDeclaration?> = []

	let errorDanglingPatternDeclaration = PatternBindingDeclaration(
		identifier: "<<Error>>", typeName: "<<Error>>", expression: ErrorExpression(range: nil))

	fileprivate var sourceFile: SourceFile?

	static let functionCompatibleASTNodes: ArrayClass<String> =
		["Function Declaration", "Constructor Declaration", "Accessor Declaration"]

	// MARK: - Interface

	public init() { }

	public func translateAST(
		_ ast: SwiftAST,
		asMainFile isMainFile: Bool)
		throws -> GryphonAST
	{
		let filePath = ast.standaloneAttributes[0]

		let contents = try Utilities.readFile(filePath)
		sourceFile = SourceFile(path: filePath, contents: contents)

		let fileRange = sourceFile.map {
			SourceFileRange(lineStart: 0, lineEnd: $0.numberOfLines, columnStart: 0, columnEnd: 0)
		}
		let translatedSubtrees = try translateSubtrees(
			ast.subtrees,
			scopeRange: fileRange)

		if isMainFile {
			let declarationsAndStatements = filterStatements(translatedSubtrees)

			return GryphonAST(
				sourceFile: sourceFile,
				declarations: declarationsAndStatements.declarations,
				statements: declarationsAndStatements.statements)
		}
		else {
			return GryphonAST(
				sourceFile: sourceFile,
				declarations: translatedSubtrees,
				statements: [])
		}
	}

	struct DeclarationsAndStatements {
		let declarations: ArrayClass<Statement>
		let statements: ArrayClass<Statement>
	}

	func filterStatements(_ allStatements: ArrayClass<Statement>) -> DeclarationsAndStatements {
		let declarations: ArrayClass<Statement> = []
		let statements: ArrayClass<Statement> = []

		var isInTopOfFileComments = true
		var lastTopOfFileCommentLine = 0

		for statement in allStatements {

			// Special case: comments at the top of the source file (i.e. license comments, etc)
			// will be put outside of the main function so they're at the top of the source file
			if isInTopOfFileComments {
				if let commentStatement = statement as? CommentStatement {
					if let range = commentStatement.range,
						lastTopOfFileCommentLine == range.lineStart - 1
					{
						lastTopOfFileCommentLine = range.lineEnd
						declarations.append(statement)
						continue
					}
				}

				isInTopOfFileComments = false
			}

			// Special case: other comments in main files will be ignored because we can't know if
			// they're supposed to be in the main function or not
			if statement is CommentStatement {
				continue
			}

			// Special case: expression statements may be literal declarations or normal statements
			if let expressionStatement = statement as? ExpressionStatement {
				if expressionStatement.expression is LiteralDeclarationExpression {
					declarations.append(statement)
				}
				else {
					statements.append(statement)
				}

				continue
			}

			// Common cases: declarations go outside the main function, everything else goes inside.
			if statement is ProtocolDeclaration ||
				statement is ClassDeclaration ||
				statement is StructDeclaration ||
				statement is ExtensionDeclaration ||
				statement is FunctionDeclaration ||
				statement is EnumDeclaration ||
				statement is TypealiasDeclaration
			{
				declarations.append(statement)
			}
			else {
				statements.append(statement)
			}
		}

		return SwiftTranslator.DeclarationsAndStatements(
			declarations: declarations,
			statements: statements)
	}

	// MARK: - Top-level translations

	internal func translateSubtreesInScope(
		_ subtrees: ArrayClass<SwiftAST>,
		scope: SwiftAST)
		throws -> ArrayClass<Statement>
	{
		let scopeRange = getRange(ofNode: scope)
		return try translateSubtrees(
			subtrees, scopeRange: scopeRange)
	}

	internal func translateSubtrees(
		_ subtrees: ArrayClass<SwiftAST>,
		scopeRange: SourceFileRange?)
		throws -> ArrayClass<Statement>
	{
		let result: ArrayClass<Statement> = []

		var lastRange: SourceFileRange
		// If we have a scope, start at its lower bound
		if let scopeRange = scopeRange {
			lastRange = SourceFileRange(
				lineStart: -1,
				lineEnd: scopeRange.lineStart,
				columnStart: 0,
				columnEnd: 0)
		}
		// If we don't, start at the first statement with a range
		else if let subtree = subtrees.first(where: { getRange(ofNode: $0) != nil }) {
			lastRange = getRange(ofNode: subtree)!
		}
		// If there is no info on ranges, then just translate the subtrees normally
		else {
			return try subtrees.flatMap{ try translateSubtree($0) }.compactMap { $0 }
		}

		for subtree in subtrees {
			if let currentRange = getRange(ofNode: subtree),
				lastRange.lineEnd <= currentRange.lineStart
			{
				let newStatements = insertedCode(
					inRange: lastRange.lineEnd..<currentRange.lineStart)
				result.append(contentsOf: newStatements)

				lastRange = currentRange
			}

			result.append(contentsOf: try translateSubtree(subtree).compactMap { $0 })
		}

		// Insert code in comments after the last translated node
		if let scopeRange = scopeRange,
			lastRange.lineEnd < scopeRange.lineEnd
		{
			let newStatements = insertedCode(
				inRange: lastRange.lineEnd..<scopeRange.lineEnd)
			result.append(contentsOf: newStatements)
		}

		return result
	}

	// MARK: - Statement translations

	internal func translateSubtreesOf(_ ast: SwiftAST)
		throws -> ArrayClass<Statement>
	{
		return try translateSubtreesInScope(ast.subtrees, scope: ast)
	}

	internal func translateBraceStatement(
		_ braceStatement: SwiftAST)
		throws -> ArrayClass<Statement>
	{
		guard braceStatement.name == "Brace Statement" else {
			throw createUnexpectedASTStructureError(
				"Trying to translate \(braceStatement.name) as a brace statement",
				ast: braceStatement, translator: self)
		}

		return try translateSubtreesInScope(braceStatement.subtrees, scope: braceStatement)
	}

	internal func translateSubtree(_ subtree: SwiftAST) throws -> ArrayClass<Statement?> {

		if getKeyedComment(forNode: subtree, key: .kotlin) == "ignore" {
			return []
		}

		let result: ArrayClass<Statement?>
		switch subtree.name {
		case "Top Level Code Declaration":
			result = try translateTopLevelCode(subtree)
		case "Import Declaration":
			result = [ImportDeclaration(range: nil, moduleName: subtree.standaloneAttributes[0])]
		case "Typealias":
			result = [try translateTypealiasDeclaration(subtree)]
		case "Class Declaration":
			result = [try translateClassDeclaration(subtree)]
		case "Struct Declaration":
			result = [try translateStructDeclaration(subtree)]
		case "Enum Declaration":
			result = [try translateEnumDeclaration(subtree)]
		case "Extension Declaration":
			result = [try translateExtensionDeclaration(subtree)]
		case "Do Catch Statement":
			result = try translateDoCatchStatement(subtree)
		case "For Each Statement":
			result = [try translateForEachStatement(subtree)]
		case "While Statement":
			result = [try translateWhileStatement(subtree)]
		case "Function Declaration", "Constructor Declaration":
			result = [try translateFunctionDeclaration(subtree)]
		case "Subscript Declaration":
			result = try subtree.subtrees.filter { $0.name == "Accessor Declaration" }
				.map { try translateFunctionDeclaration($0) }
		case "Protocol":
			result = [try translateProtocolDeclaration(subtree)]
		case "Throw Statement":
			result = [try translateThrowStatement(subtree)]
		case "Variable Declaration":
			result = [try translateVariableDeclaration(subtree)]
		case "Assign Expression":
			result = [try translateAssignExpression(subtree)]
		case "If Statement", "Guard Statement":
			result = [try translateIfStatement(subtree)]
		case "Switch Statement":
			result = [try translateSwitchStatement(subtree)]
		case "Defer Statement":
			result = [try translateDeferStatement(subtree)]
		case "Pattern Binding Declaration":
			try processPatternBindingDeclaration(subtree)
			result = []
		case "Return Statement":
			result = [try translateReturnStatement(subtree)]
		case "Break Statement":
			result = [BreakStatement(range: nil)]
		case "Continue Statement":
			result = [ContinueStatement(range: nil)]
		case "Fail Statement":
			result = [ReturnStatement(range: nil, expression: NilLiteralExpression(range: nil))]
		case "Optional Evaluation Expression":

			// Some assign statements of the form a.b?.c come enveloped in other expressions
			let assignExpression = subtree
				.subtree(named: "Inject Into Optional")?
				.subtree(named: "Assign Expression")
			if let assignExpression = assignExpression {
				result = try translateSubtree(assignExpression)
			}
			else {
				let expression = try translateExpression(subtree)
				result = [ExpressionStatement(range: nil, expression: expression)]
			}

		default:
			if subtree.name.hasSuffix("Expression") {
				let expression = try translateExpression(subtree)
				result = [ExpressionStatement(range: nil, expression: expression)]
			}
			else {
				result = []
			}
		}

		let shouldInspect = (getKeyedComment(forNode: subtree, key: .gryphon) == "inspect")
		if shouldInspect {
			print("===\nInspecting:")
			print(subtree)
			for statement in result {
				statement?.prettyPrint()
			}
		}

		return result
	}

	internal func translateProtocolDeclaration(
		_ protocolDeclaration: SwiftAST)
		throws -> Statement
	{
		guard protocolDeclaration.name == "Protocol" else {
			return try unexpectedASTStructureError(
				"Trying to translate \(protocolDeclaration.name) as 'Protocol'",
				ast: protocolDeclaration, translator: self)
		}

		guard let protocolName = protocolDeclaration.standaloneAttributes.first else {
			return try unexpectedASTStructureError(
				"Unrecognized structure",
				ast: protocolDeclaration, translator: self)
		}

		let members = try translateSubtreesOf(protocolDeclaration)

		return ProtocolDeclaration(range: nil, protocolName: protocolName, members: members)
	}

	internal func translateAssignExpression(_ assignExpression: SwiftAST) throws -> Statement {
		guard assignExpression.name == "Assign Expression" else {
			return try unexpectedASTStructureError(
				"Trying to translate \(assignExpression.name) as 'Assign Expression'",
				ast: assignExpression, translator: self)
		}

		if let leftExpression = assignExpression.subtree(at: 0),
			let rightExpression = assignExpression.subtree(at: 1)
		{
			if leftExpression.name == "Discard Assignment Expression" {
				return try ExpressionStatement(
					range: nil,
					expression: translateExpression(rightExpression))
			}
			else {
				let leftTranslation = try translateExpression(leftExpression)
				let rightTranslation = try translateExpression(rightExpression)

				return AssignmentStatement(
					range: nil,
					leftHand: leftTranslation,
					rightHand: rightTranslation)
			}
		}
		else {
			return try unexpectedASTStructureError(
				"Unrecognized structure",
				ast: assignExpression, translator: self)
		}
	}

	internal func translateTypealiasDeclaration(
		_ typealiasDeclaration: SwiftAST)
		throws -> Statement
	{
		let isImplicit: Bool
		let identifier: String
		if typealiasDeclaration.standaloneAttributes[0] == "implicit" {
			isImplicit = true
			identifier = typealiasDeclaration.standaloneAttributes[1]
		}
		else {
			isImplicit = false
			identifier = typealiasDeclaration.standaloneAttributes[0]
		}

		return TypealiasDeclaration(
			range: nil,
			identifier: identifier,
			typeName: typealiasDeclaration["type"]!,
			isImplicit: isImplicit)
	}

	internal func translateClassDeclaration(_ classDeclaration: SwiftAST) throws -> Statement? {
		guard classDeclaration.name == "Class Declaration" else {
			return try unexpectedASTStructureError(
				"Trying to translate \(classDeclaration.name) as 'Class Declaration'",
				ast: classDeclaration, translator: self)
		}

		if getKeyedComment(forNode: classDeclaration, key: .kotlin) == "ignore" {
			return nil
		}

		// Get the class name
		let name = classDeclaration.standaloneAttributes.first!

		// Check for inheritance
		let inheritanceArray: ArrayClass<String>
		if let inheritanceList = classDeclaration["inherits"] {
			inheritanceArray = inheritanceList.split(withStringSeparator: ", ")
		}
		else {
			inheritanceArray = []
		}

		// Translate the contents
		let classContents = try translateSubtreesOf(classDeclaration)

		return ClassDeclaration(
			range: nil,
			className: name,
			inherits: inheritanceArray,
			members: classContents)
	}

	internal func translateStructDeclaration(_ structDeclaration: SwiftAST) throws -> Statement? {
		guard structDeclaration.name == "Struct Declaration" else {
			return try unexpectedASTStructureError(
				"Trying to translate \(structDeclaration.name) as 'Struct Declaration'",
				ast: structDeclaration, translator: self)
		}

		if getKeyedComment(forNode: structDeclaration, key: .kotlin) == "ignore" {
			return nil
		}

		let annotations = getKeyedComment(forNode: structDeclaration, key: .annotation)

		// Get the struct name
		let name = structDeclaration.standaloneAttributes.first!

		// Check for inheritance
		let inheritanceArray: ArrayClass<String>
		if let inheritanceList = structDeclaration["inherits"] {
			inheritanceArray = inheritanceList.split(withStringSeparator: ", ")
		}
		else {
			inheritanceArray = []
		}

		// Translate the contents
		let structContents = try translateSubtreesOf(structDeclaration)

		return StructDeclaration(
			range: nil,
			annotations: annotations,
			structName: name,
			inherits: inheritanceArray,
			members: structContents)
	}

	internal func translateThrowStatement(_ throwStatement: SwiftAST) throws -> Statement {
		guard throwStatement.name == "Throw Statement" else {
			return try unexpectedASTStructureError(
				"Trying to translate \(throwStatement.name) as 'Throw Statement'",
				ast: throwStatement, translator: self)
		}

		if let expression = throwStatement.subtrees.last {
			let expressionTranslation = try translateExpression(expression)
			return ThrowStatement(range: nil, expression: expressionTranslation)
		}
		else {
			return try unexpectedASTStructureError(
				"Unrecognized structure",
				ast: throwStatement, translator: self)
		}
	}

	internal func translateExtensionDeclaration(
		_ extensionDeclaration: SwiftAST)
		throws -> Statement
	{
		let typeName = cleanUpType(extensionDeclaration.standaloneAttributes[0])

		let members = try translateSubtreesOf(extensionDeclaration)

		return ExtensionDeclaration(range: nil, typeName: typeName, members: members)
	}

	internal func translateEnumDeclaration(_ enumDeclaration: SwiftAST) throws -> Statement? {
		guard enumDeclaration.name == "Enum Declaration" else {
			return try unexpectedASTStructureError(
				"Trying to translate \(enumDeclaration.name) as 'Enum Declaration'",
				ast: enumDeclaration, translator: self)
		}

		if getKeyedComment(forNode: enumDeclaration, key: .kotlin) == "ignore" {
			return nil
		}

		let access = enumDeclaration["access"]

		let name: String
		let isImplicit: Bool
		if enumDeclaration.standaloneAttributes[0] == "implicit" {
			isImplicit = true
			name = enumDeclaration.standaloneAttributes[1]
		}
		else {
			isImplicit = false
			name = enumDeclaration.standaloneAttributes[0]
		}

		let inheritanceArray: ArrayClass<String>
		if let inheritanceList = enumDeclaration["inherits"] {
			inheritanceArray = inheritanceList.split(withStringSeparator: ", ")
		}
		else {
			inheritanceArray = []
		}

		var rawValues: ArrayClass<Expression> = []
		let constructorDeclarations = enumDeclaration.subtrees.filter {
			$0.name ==  "Constructor Declaration"
		}
		for constructorDeclaration in constructorDeclarations {
			if constructorDeclaration.standaloneAttributes.contains("init(rawValue:)"),
				constructorDeclaration.standaloneAttributes.contains("implicit"),
				let arrayExpression = constructorDeclaration.subtree(named: "Brace Statement")?
					.subtree(named: "Switch Statement")?
					.subtree(named: "Call Expression")?
					.subtree(named: "Tuple Expression")?
					.subtree(named: "Array Expression")
			{
				let rawValueASTs = ArrayClass<SwiftAST>(arrayExpression.subtrees.dropLast())
				rawValues = try rawValueASTs.map { try translateExpression($0) }
				break
			}
		}

		let elements: ArrayClass<EnumElement> = []
		let enumElementDeclarations =
			enumDeclaration.subtrees.filter { $0.name == "Enum Element Declaration" }
		for index in enumElementDeclarations.indices {
			let enumElementDeclaration = enumElementDeclarations[index]

			guard getKeyedComment(forNode: enumElementDeclaration, key: .kotlin) != "ignore" else {
				continue
			}

			guard let elementName = enumElementDeclaration.standaloneAttributes.first else {
				return try unexpectedASTStructureError(
					"Expected the element name to be the first standalone attribute in an Enum" +
					"Declaration",
					ast: enumDeclaration, translator: self)
			}

			let annotations = getKeyedComment(forNode: enumElementDeclaration, key: .annotation)

			if !elementName.contains("(") {
				elements.append(EnumElement(
					name: elementName,
					associatedValues: [],
					rawValue: rawValues[safe: index],
					annotations: annotations))
			}
			else {
				let parenthesisIndex = elementName.firstIndex(of: "(")!
				let prefix = String(elementName[elementName.startIndex..<parenthesisIndex])
				let suffix = elementName[parenthesisIndex...]
				let valuesString = suffix.dropFirst().dropLast(2)
				let valueLabels = ArrayClass<String>(
					valuesString.split(separator: ":")
						.map { String($0) })

				guard let enumType = enumElementDeclaration["interface type"] else {
					return try unexpectedASTStructureError(
						"Expected an enum element with associated values to have an interface type",
						ast: enumDeclaration, translator: self)
				}
				let enumTypeComponents = enumType.split(withStringSeparator: " -> ")
				let valuesComponent = enumTypeComponents[1]
				let valueTypesString = String(valuesComponent.dropFirst().dropLast())
				let valueTypes = Utilities.splitTypeList(valueTypesString)

				let associatedValues = zipToClass(valueLabels, valueTypes)
					.map { LabeledType(label: $0.0, typeName: $0.1) }

				elements.append(EnumElement(
					name: prefix,
					associatedValues: associatedValues,
					rawValue: rawValues[safe: index],
					annotations: annotations))
			}
		}

		let members = enumDeclaration.subtrees.filter {
			$0.name != "Enum Element Declaration" && $0.name != "Enum Case Declaration"
		}

		let translatedMembers = try translateSubtreesInScope(members, scope: enumDeclaration)

		return EnumDeclaration(
			range: nil,
			access: access,
			enumName: name,
			inherits: inheritanceArray,
			elements: elements,
			members: translatedMembers,
			isImplicit: isImplicit)
	}

	internal func translateMemberReferenceExpression(
		_ memberReferenceExpression: SwiftAST)
		throws -> Expression
	{
		guard memberReferenceExpression.name == "Member Reference Expression" else {
			return try unexpectedExpressionStructureError(
				"Trying to translate \(memberReferenceExpression.name) as " +
				"'Member Reference Expression'",
				ast: memberReferenceExpression, translator: self)
		}

		if let declaration = memberReferenceExpression["decl"],
			let memberOwner = memberReferenceExpression.subtree(at: 0),
			let rawType = memberReferenceExpression["type"]
		{
			let typeName = cleanUpType(rawType)
			let leftHand = try translateExpression(memberOwner)
			let declarationInformation = getInformationFromDeclaration(declaration)
			let isImplicit = memberReferenceExpression.standaloneAttributes.contains("implicit")
			let range = getRangeRecursively(ofNode: memberReferenceExpression)
			let rightHand = DeclarationReferenceExpression(range: nil, data:
				DeclarationReferenceData(
					identifier: declarationInformation.identifier,
					typeName: typeName,
					isStandardLibrary: declarationInformation.isStandardLibrary,
					isImplicit: isImplicit,
					range: range))
			return DotExpression(
				range: nil,
				leftExpression: leftHand,
				rightExpression: rightHand)
		}
		else {
			return try unexpectedExpressionStructureError(
				"Unrecognized structure",
				ast: memberReferenceExpression, translator: self)
		}
	}

	internal func translateTupleElementExpression(
		_ tupleElementExpression: SwiftAST)
		throws -> Expression
	{
		guard tupleElementExpression.name == "Tuple Element Expression" else {
			return try unexpectedExpressionStructureError(
				"Trying to translate \(tupleElementExpression.name) as " +
				"'Tuple Element Expression'",
				ast: tupleElementExpression, translator: self)
		}

		let numberString = tupleElementExpression.standaloneAttributes
			.first(where: { $0.hasPrefix("#") })?
			.dropFirst()
		let number = numberString.map { Int($0) } ?? nil
		let declarationReference = tupleElementExpression
			.subtree(named: "Declaration Reference Expression")
		let tuple = declarationReference?["type"]

		if let number = number,
			let declarationReference = declarationReference,
			let tuple = tuple
		{
			let leftHand = try translateDeclarationReferenceExpression(declarationReference)
			let tupleComponents =
				String(tuple.dropFirst().dropLast()).split(withStringSeparator: ", ")
			let tupleComponent = tupleComponents[safe: number]

			let labelAndType = tupleComponent?.split(withStringSeparator: ": ")
			let label = labelAndType?[safe: 0]
			let typeName = labelAndType?[safe: 1]

			if let label = label,
				let typeName = typeName,
				let leftExpression = leftHand as? DeclarationReferenceExpression
			{
				return DotExpression(
					range: nil,
					leftExpression: leftHand,
					rightExpression: DeclarationReferenceExpression(range: nil, data:
						DeclarationReferenceData(
							identifier: label,
							typeName: typeName,
							isStandardLibrary: leftExpression.data.isStandardLibrary,
							isImplicit: false,
							range: leftExpression.range)))
			}
			else if let leftExpression = leftHand as? DeclarationReferenceExpression,
				let tupleComponent = tupleComponent
			{
				let memberName = (number == 0) ? "first" : "second"
				return DotExpression(
					range: nil,
					leftExpression: leftHand,
					rightExpression: DeclarationReferenceExpression(range: nil, data:
						DeclarationReferenceData(
							identifier: memberName,
							typeName: tupleComponent,
							isStandardLibrary: leftExpression.data.isStandardLibrary,
							isImplicit: false,
							range: leftExpression.data.range)))
			}
		}

		return try unexpectedExpressionStructureError(
			"Unable to get either the tuple element's number or its label.",
			ast: tupleElementExpression, translator: self)
	}

	internal func translatePrefixUnaryExpression(
		_ prefixExpressionFixme: SwiftAST)
		throws -> Expression
	{
		guard prefixExpressionFixme.name == "Prefix Unary Expression" else {
			return try unexpectedExpressionStructureError(
				"Trying to translate \(prefixExpressionFixme.name) as 'Prefix Unary Expression'",
				ast: prefixExpressionFixme, translator: self)
		}

		if let rawType = prefixExpressionFixme["type"],
			let declaration = prefixExpressionFixme
				.subtree(named: "Dot Syntax Call Expression")?
				.subtree(named: "Declaration Reference Expression")?["decl"],
			let expression = prefixExpressionFixme.subtree(at: 1)
		{
			let typeName = cleanUpType(rawType)
			let expressionTranslation = try translateExpression(expression)
			let operatorInformation = getInformationFromDeclaration(declaration)

			return PrefixUnaryExpression(
				range: nil,
				subExpression: expressionTranslation,
				operatorSymbol: operatorInformation.identifier,
				typeName: typeName)
		}
		else {
			return try unexpectedExpressionStructureError(
				"Expected Prefix Unary Expression to have a Dot Syntax Call Expression with a " +
					"Declaration Reference Expression, for the operator, and expected it to have " +
				"a second expression as the operand.",
				ast: prefixExpressionFixme, translator: self)
		}
	}

	internal func translatePostfixUnaryExpression(
		_ postfixExpressionFixme: SwiftAST)
		throws -> Expression
	{
		guard postfixExpressionFixme.name == "Postfix Unary Expression" else {
			return try unexpectedExpressionStructureError(
				"Trying to translate \(postfixExpressionFixme.name) as 'Postfix Unary Expression'",
				ast: postfixExpressionFixme, translator: self)
		}

		if let rawType = postfixExpressionFixme["type"],
			let declaration = postfixExpressionFixme
				.subtree(named: "Dot Syntax Call Expression")?
				.subtree(named: "Declaration Reference Expression")?["decl"],
			let expression = postfixExpressionFixme.subtree(at: 1)
		{
			let typeName = cleanUpType(rawType)
			let expressionTranslation = try translateExpression(expression)
			let operatorInformation = getInformationFromDeclaration(declaration)

			return PostfixUnaryExpression(
				range: nil,
				subExpression: expressionTranslation,
				operatorSymbol: operatorInformation.identifier,
				typeName: typeName)
		}
		else {
			return try unexpectedExpressionStructureError(
				"Expected Postfix Unary Expression to have a Dot Syntax Call Expression with a " +
					"Declaration Reference Expression, for the operator, and expected it to have " +
				"a second expression as the operand.",
				ast: postfixExpressionFixme, translator: self)
		}
	}

	internal func translateBinaryExpression(_ binaryExpression: SwiftAST) throws -> Expression {
		guard binaryExpression.name == "Binary Expression" else {
			return try unexpectedExpressionStructureError(
				"Trying to translate \(binaryExpression.name) as 'Binary Expression'",
				ast: binaryExpression, translator: self)
		}

		let declarationFromDotSyntax = binaryExpression
			.subtree(named: "Dot Syntax Call Expression")?
			.subtree(named: "Declaration Reference Expression")
		let directDeclaration = binaryExpression
			.subtree(named: "Declaration Reference Expression")
		let declaration = declarationFromDotSyntax?["decl"] ??
			directDeclaration?["decl"]
		let tupleExpression = binaryExpression.subtree(named: "Tuple Expression")
		let leftHandExpression = tupleExpression?.subtree(at: 0)
		let rightHandExpression = tupleExpression?.subtree(at: 1)

		if let rawType = binaryExpression["type"],
			let declaration = declaration,
			let leftHandExpression = leftHandExpression,
			let rightHandExpression = rightHandExpression
		{
			let typeName = cleanUpType(rawType)
			let operatorInformation = getInformationFromDeclaration(declaration)
			let leftHandTranslation = try translateExpression(leftHandExpression)
			let rightHandTranslation = try translateExpression(rightHandExpression)

			return BinaryOperatorExpression(
				range: nil,
				leftExpression: leftHandTranslation,
				rightExpression: rightHandTranslation,
				operatorSymbol: operatorInformation.identifier,
				typeName: typeName)
		}
		else {
			return try unexpectedExpressionStructureError(
				"Unrecognized structure",
				ast: binaryExpression, translator: self)
		}
	}

	// FIXME: Fix the parameter names once Expression subclasses have been capitalized
	internal func translateIfExpression(_ ifExpressionFixme: SwiftAST) throws -> Expression {
		guard ifExpressionFixme.name == "If Expression" else {
			return try unexpectedExpressionStructureError(
				"Trying to translate \(ifExpressionFixme.name) as 'If Expression'",
				ast: ifExpressionFixme, translator: self)
		}

		guard ifExpressionFixme.subtrees.count == 3 else {
			return try unexpectedExpressionStructureError(
				"Expected If Expression to have three subtrees (a condition, a true expression " +
				"and a false expression)",
				ast: ifExpressionFixme, translator: self)
		}

		let condition = try translateExpression(ifExpressionFixme.subtrees[0])
		let trueExpression = try translateExpression(ifExpressionFixme.subtrees[1])
		let falseExpression = try translateExpression(ifExpressionFixme.subtrees[2])

		return IfExpression(
			range: nil,
			condition: condition,
			trueExpression: trueExpression,
			falseExpression: falseExpression)
	}

	internal func translateDotSyntaxCallExpression(
		_ dotSyntaxCallExpression: SwiftAST)
		throws -> Expression
	{
		guard dotSyntaxCallExpression.name == "Dot Syntax Call Expression" else {
			return try unexpectedExpressionStructureError(
				"Trying to translate \(dotSyntaxCallExpression.name) as " +
				"'Dot Syntax Call Expression'",
				ast: dotSyntaxCallExpression, translator: self)
		}

		if let leftHandExpression = dotSyntaxCallExpression.subtree(at: 1),
			let rightHandExpression = dotSyntaxCallExpression.subtree(at: 0)
		{
			let rightHand = try translateExpression(rightHandExpression)
			let leftHand = try translateExpression(leftHandExpression)

			// Swift 4.2
			if leftHand is TypeExpression,
				let rightExpression = rightHand as? DeclarationReferenceExpression
			{
				if rightExpression.data.identifier == "none" {
					return NilLiteralExpression(range: nil)
				}
			}

			return DotExpression(range: nil, leftExpression: leftHand, rightExpression: rightHand)
		}
		else {
			return try unexpectedExpressionStructureError(
				"Unrecognized structure",
				ast: dotSyntaxCallExpression, translator: self)
		}
	}

	internal func translateReturnStatement(_ returnStatement: SwiftAST) throws -> Statement {
		guard returnStatement.name == "Return Statement" else {
			return try unexpectedASTStructureError(
				"Trying to translate \(returnStatement.name) as 'Return Statement'",
				ast: returnStatement, translator: self)
		}

		if let expression = returnStatement.subtrees.last {
			let translatedExpression = try translateExpression(expression)
			return ReturnStatement(range: nil, expression: translatedExpression)
		}
		else {
			return ReturnStatement(range: nil, expression: nil)
		}
	}

	internal func translateDoCatchStatement(
		_ doCatchStatement: SwiftAST)
		throws -> ArrayClass<Statement?>
	{
		guard doCatchStatement.name == "Do Catch Statement" else {
			return try [unexpectedASTStructureError(
				"Trying to translate \(doCatchStatement.name) as 'Do Catch Statement'",
				ast: doCatchStatement, translator: self), ]
		}

		guard let braceStatement = doCatchStatement.subtrees.first,
			braceStatement.name == "Brace Statement" else
		{
			return try [unexpectedASTStructureError(
				"Unable to find do statement's inner statements. Expected there to be a Brace " +
				"Statement as the first subtree.",
				ast: doCatchStatement, translator: self), ]
		}

		let translatedInnerDoStatements = try translateBraceStatement(braceStatement)
		let translatedDoStatement = DoStatement(range: nil, statements: translatedInnerDoStatements)

		let catchStatements: ArrayClass<Statement?> = []
		for catchStatement in doCatchStatement.subtrees.dropFirst() {
			guard catchStatement.name == "Catch" else {
				continue
			}

			let variableDeclaration: VariableDeclarationData?

			let patternNamed = catchStatement
				.subtree(named: "Pattern Let")?
				.subtree(named: "Pattern Named")
			let patternAttributes = patternNamed?.standaloneAttributes
			let variableName = patternAttributes?.first
			let variableType = patternNamed?["type"]

			if let variableName = variableName, let variableType = variableType {
				variableDeclaration = VariableDeclarationData(
					identifier: variableName,
					typeName: variableType,
					expression: nil,
					getter: nil,
					setter: nil,
					isLet: true,
					isImplicit: false,
					isStatic: false,
					extendsType: nil,
					annotations: nil)
			}
			else {
				variableDeclaration = nil
			}

			guard let braceStatement = catchStatement.subtree(named: "Brace Statement") else {
				return try [unexpectedASTStructureError(
					"Unable to find catch statement's inner statements. Expected there to be a " +
					"Brace Statement.",
					ast: doCatchStatement, translator: self), ]
			}

			let translatedStatements = try translateBraceStatement(braceStatement)

			catchStatements.append(CatchStatement(
				range: nil,
				variableDeclaration: variableDeclaration,
				statements: translatedStatements))
		}

		let resultingStatements: ArrayClass<Statement?> = [translatedDoStatement]
		resultingStatements.append(contentsOf: catchStatements)

		return resultingStatements
	}

	internal func translateForEachStatement(_ forEachStatement: SwiftAST) throws -> Statement {
		guard forEachStatement.name == "For Each Statement" else {
			return try unexpectedASTStructureError(
				"Trying to translate \(forEachStatement.name) as 'For Each Statement'",
				ast: forEachStatement, translator: self)
		}

		let variableRange = getRangeRecursively(ofNode: forEachStatement.subtrees[0])

		let variable: Expression
		let collectionExpression: SwiftAST

		let maybeCollectionExpression = forEachStatement.subtree(at: 2)

		let variableSubtreeTuple = forEachStatement.subtree(named: "Pattern Tuple")
		let variableSubtreeNamed = forEachStatement.subtree(named: "Pattern Named")
		let variableSubtreeAny = forEachStatement.subtree(named: "Pattern Any")
		let rawTypeNamed = variableSubtreeNamed?["type"]
		let rawTypeAny = variableSubtreeAny?["type"]
		let variableAttributes = variableSubtreeNamed?.standaloneAttributes
		let variableName = variableAttributes?.first

		if let rawTypeNamed = rawTypeNamed,
			let maybeCollectionExpression = maybeCollectionExpression,
			let variableName = variableName
		{
			variable = DeclarationReferenceExpression(range: nil, data:
				DeclarationReferenceData(
					identifier: variableName,
					typeName: cleanUpType(rawTypeNamed),
					isStandardLibrary: false,
					isImplicit: false,
					range: variableRange))
			collectionExpression = maybeCollectionExpression
		}
		else if let variableSubtreeTuple = variableSubtreeTuple,
			let maybeCollectionExpression = maybeCollectionExpression
		{
			let variableNames = variableSubtreeTuple.subtrees.map { $0.standaloneAttributes[0] }
			let variableTypes = variableSubtreeTuple.subtrees.map { $0.keyValueAttributes["type"]! }

			let variables = zipToClass(variableNames, variableTypes).map {
				LabeledExpression(
					label: nil,
					expression: DeclarationReferenceExpression(range: nil, data:
						DeclarationReferenceData(
							identifier: $0.0,
							typeName: cleanUpType($0.1),
							isStandardLibrary: false,
							isImplicit: false,
							range: variableRange)))
			}

			variable = TupleExpression(range: nil, pairs: variables)
			collectionExpression = maybeCollectionExpression
		}
		else if let rawTypeAny = rawTypeAny,
			let maybeCollectionExpression = maybeCollectionExpression
		{
			let typeName = cleanUpType(rawTypeAny)
			variable = DeclarationReferenceExpression(range: nil, data:
				DeclarationReferenceData(
					identifier: "_0",
					typeName: typeName,
					isStandardLibrary: false,
					isImplicit: false,
					range: variableRange))
			collectionExpression = maybeCollectionExpression
		}
		else {
			return try unexpectedASTStructureError(
				"Unable to detect variable or collection",
				ast: forEachStatement, translator: self)
		}

		guard let braceStatement = forEachStatement.subtrees.last,
			braceStatement.name == "Brace Statement" else
		{
			return try unexpectedASTStructureError(
				"Unable to detect body of statements",
				ast: forEachStatement, translator: self)
		}

		let collectionTranslation = try translateExpression(collectionExpression)
		let statements = try translateBraceStatement(braceStatement)

		return ForEachStatement(
			range: nil,
			collection: collectionTranslation,
			variable: variable,
			statements: statements)
	}

	internal func translateWhileStatement(_ whileStatement: SwiftAST) throws -> Statement {
		guard whileStatement.name == "While Statement" else {
			return try unexpectedASTStructureError(
				"Trying to translate \(whileStatement.name) as 'While Statement'",
				ast: whileStatement, translator: self)
		}

		guard let expressionSubtree = whileStatement.subtrees.first else {
			return try unexpectedASTStructureError(
				"Unable to detect expression",
				ast: whileStatement, translator: self)
		}

		guard let braceStatement = whileStatement.subtrees.last,
			braceStatement.name == "Brace Statement" else
		{
			return try unexpectedASTStructureError(
				"Unable to detect body of statements",
				ast: whileStatement, translator: self)
		}

		let expression = try translateExpression(expressionSubtree)
		let statements = try translateBraceStatement(braceStatement)

		return WhileStatement(range: nil, expression: expression, statements: statements)
	}

	internal func translateDeferStatement(_ deferStatement: SwiftAST) throws -> Statement {
		guard deferStatement.name == "Defer Statement" else {
			return try unexpectedASTStructureError(
				"Trying to translate \(deferStatement.name) as a 'Defer Statement'",
				ast: deferStatement, translator: self)
		}

		guard let braceStatement = deferStatement
			.subtree(named: "Function Declaration")?
			.subtree(named: "Brace Statement") else
		{
			return try unexpectedASTStructureError(
				"Expected defer statement to have a function declaration with a brace statement " +
				"containing the deferred statements.",
				ast: deferStatement, translator: self)
		}

		let statements = try translateBraceStatement(braceStatement)
		return DeferStatement(range: nil, statements: statements)
	}

	internal func translateIfStatement(_ ifStatement: SwiftAST) throws -> Statement {
		do {
			let result: IfStatementData = try translateIfStatementData(ifStatement)
			return IfStatement(range: nil, data: result)
		}
		catch let error {
			return try handleUnexpectedASTStructureError(error)
		}
	}

	internal func translateIfStatementData(_ ifStatement: SwiftAST) throws -> IfStatementData {
		guard ifStatement.name == "If Statement" || ifStatement.name == "Guard Statement" else {
			throw createUnexpectedASTStructureError(
				"Trying to translate \(ifStatement.name) as an if or guard statement",
				ast: ifStatement, translator: self)
		}

		let isGuard = (ifStatement.name == "Guard Statement")

		let ifConditions = try translateIfConditions(forIfStatement: ifStatement)
		let conditions = ifConditions.conditions
		let extraStatements = ifConditions.statements

		let braceStatement: SwiftAST
		let elseStatement: IfStatementData?

		let secondToLastTree = ifStatement.subtrees.secondToLast
		let lastTree = ifStatement.subtrees.last

		if ifStatement.subtrees.count > 2,
			let secondToLastTree = secondToLastTree,
			secondToLastTree.name == "Brace Statement",
			let lastTree = lastTree,
			lastTree.name == "If Statement"
		{
			braceStatement = secondToLastTree
			elseStatement = try translateIfStatementData(lastTree)
		}
		else if ifStatement.subtrees.count > 2,
			let secondToLastTree = secondToLastTree,
			secondToLastTree.name == "Brace Statement",
			let lastTree = lastTree,
			lastTree.name == "Brace Statement"
		{
			braceStatement = secondToLastTree
			let statements = try translateBraceStatement(lastTree)
			elseStatement = IfStatementData(
				conditions: [], declarations: [],
				statements: statements,
				elseStatement: nil,
				isGuard: false)
		}
		else if let lastTree = lastTree,
			lastTree.name == "Brace Statement"
		{
			braceStatement = lastTree
			elseStatement = nil
		}
		else {
			throw createUnexpectedASTStructureError(
				"Unable to detect body of statements",
				ast: ifStatement, translator: self)
		}

		let statements = try translateBraceStatement(braceStatement)

		let resultingStatements = extraStatements
		resultingStatements.append(contentsOf: statements)

		return IfStatementData(
			conditions: conditions,
			declarations: [],
			statements: resultingStatements,
			elseStatement: elseStatement,
			isGuard: isGuard)
	}

	internal func translateSwitchStatement(_ switchStatement: SwiftAST) throws -> Statement {
		guard switchStatement.name == "Switch Statement" else {
			return try unexpectedASTStructureError(
				"Trying to translate \(switchStatement.name) as 'Switch Statement'",
				ast: switchStatement, translator: self)
		}

		guard let expression = switchStatement.subtrees.first else {
			return try unexpectedASTStructureError(
				"Unable to detect primary expression for switch statement",
				ast: switchStatement, translator: self)
		}

		let translatedExpression = try translateExpression(expression)

		let cases: ArrayClass<SwitchCase> = []
		let caseSubtrees = ArrayClass<SwiftAST>(switchStatement.subtrees.dropFirst())
		for caseSubtree in caseSubtrees {
			let caseExpressions: ArrayClass<Expression> = []
			var extraStatements: ArrayClass<Statement> = []

			for caseLabelItem in caseSubtree.subtrees.filter({ $0.name == "Case Label Item" }) {
				let firstSubtreeSubtrees = caseLabelItem.subtrees.first?.subtrees
				let maybeExpression = firstSubtreeSubtrees?.first

				let patternLet = caseLabelItem.subtree(named: "Pattern Let")
				let patternLetResult = try translateEnumPattern(patternLet)

				if let patternLetResult = patternLetResult, let patternLet = patternLet {
					guard patternLetResult.comparisons.isEmpty else {
						return try unexpectedASTStructureError(
							"Comparison expressions are not supported in switch cases",
							ast: caseLabelItem, translator: self)
					}

					let enumType = patternLetResult.enumType
					let enumCase = patternLetResult.enumCase
					let declarations = patternLetResult.declarations
					let enumClassName = enumType + "." + enumCase.capitalizedAsCamelCase()

					caseExpressions.append(BinaryOperatorExpression(
						range: nil,
						leftExpression: translatedExpression,
						rightExpression: TypeExpression(range: nil, typeName: enumClassName),
						operatorSymbol: "is",
						typeName: "Bool"))

					let range = getRangeRecursively(ofNode: patternLet)

					extraStatements = declarations.map {
						VariableDeclaration(range: nil, data: VariableDeclarationData(
							identifier: $0.newVariable,
							typeName: $0.associatedValueType,
							expression: DotExpression(
								range: nil,
								leftExpression: translatedExpression,
								rightExpression: DeclarationReferenceExpression(range: nil, data:
									DeclarationReferenceData(
										identifier: $0.associatedValueName,
										typeName: $0.associatedValueType,
										isStandardLibrary: false,
										isImplicit: false,
										range: range))),
							getter: nil,
							setter: nil,
							isLet: true,
							isImplicit: false,
							isStatic: false,
							extendsType: nil,
							annotations: nil))
					}
				}
				else if let patternEnumElement =
					caseLabelItem.subtree(named: "Pattern Enum Element")
				{
					try caseExpressions.append(
						translateSimplePatternEnumElement(patternEnumElement))
					extraStatements = []
				}
				else if let expression = maybeExpression {
					let translatedExpression = try translateExpression(expression)
					caseExpressions.append(translatedExpression)
					extraStatements = []
				}
			}

			guard let braceStatement = caseSubtree.subtree(named: "Brace Statement") else {
				return try unexpectedASTStructureError(
					"Unable to find a case's statements",
					ast: switchStatement, translator: self)
			}

			let translatedStatements = try translateBraceStatement(braceStatement)

			let resultingStatements = extraStatements
			resultingStatements.append(contentsOf: translatedStatements)

			cases.append(SwitchCase(
				expressions: caseExpressions, statements: resultingStatements))
		}

		return SwitchStatement(
			range: nil,
			convertsToExpression: nil,
			expression: translatedExpression,
			cases: cases)
	}

	internal func translateSimplePatternEnumElement(
		_ simplePatternEnumElement: SwiftAST)
		throws -> Expression
	{
		guard simplePatternEnumElement.name == "Pattern Enum Element" else {
			return try unexpectedExpressionStructureError(
				"Trying to translate \(simplePatternEnumElement.name) as 'Pattern Enum Element'",
				ast: simplePatternEnumElement, translator: self)
		}

		guard let enumReference = simplePatternEnumElement.standaloneAttributes.first,
			let typeName = simplePatternEnumElement["type"] else
		{
			return try unexpectedExpressionStructureError(
				"Expected a Pattern Enum Element to have a reference to the enum case and a type.",
				ast: simplePatternEnumElement, translator: self)
		}

		let enumElements = ArrayClass<Substring>(enumReference.split(separator: "."))

		guard let lastEnumElement = enumElements.last else {
			return try unexpectedExpressionStructureError(
				"Expected a Pattern Enum Element to have a period (i.e. `MyEnum.myEnumCase`)",
				ast: simplePatternEnumElement, translator: self)
		}

		let range = getRangeRecursively(ofNode: simplePatternEnumElement)
		let lastExpression = DeclarationReferenceExpression(range: nil, data:
			DeclarationReferenceData(
				identifier: String(lastEnumElement),
				typeName: typeName,
				isStandardLibrary: false,
				isImplicit: false,
				range: range))

		enumElements.removeLast()
		if !enumElements.isEmpty {
			return DotExpression(
				range: nil,
				leftExpression: TypeExpression(
					range: nil,
					typeName: enumElements.joined(separator: ".")),
				rightExpression: lastExpression)
		}
		else {
			return lastExpression
		}
	}

	private func translateIfConditions(
		forIfStatement ifStatement: SwiftAST)
		throws -> IfConditionsTranslation
	{
		guard ifStatement.name == "If Statement" || ifStatement.name == "Guard Statement" else {
			return try IfConditionsTranslation(
				conditions: [],
				statements: [unexpectedASTStructureError(
					"Trying to translate \(ifStatement.name) as an if or guard statement",
					ast: ifStatement, translator: self), ])
		}

		let conditionsResult: ArrayClass<IfStatementData.IfCondition> = []
		let statementsResult: ArrayClass<Statement> = []

		let conditions = ifStatement.subtrees.filter {
			$0.name != "If Statement" && $0.name != "Brace Statement"
		}

		for condition in conditions {
			let patternEnumElement = condition.subtree(named: "Pattern Enum Element")
			let patternAttributes = patternEnumElement?.standaloneAttributes
			let enumElementType = patternAttributes?.first

			// If it's an `if let`
			if condition.name == "Pattern",
				let optionalSomeElement =
					condition.subtree(named: "Optional Some Element") ?? // Swift 4.1
						condition.subtree(named: "Pattern Optional Some") // Swift 4.2
			{
				let patternNamed: SwiftAST
				let isLet: Bool
				if let unwrappedPatternLetNamed = optionalSomeElement
					.subtree(named: "Pattern Let")?
					.subtree(named: "Pattern Named")
				{
					patternNamed = unwrappedPatternLetNamed
					isLet = true
				}
				else if let unwrappedPatternVariableNamed = optionalSomeElement
					.subtree(named: "Pattern Variable")?
					.subtree(named: "Pattern Named")
				{
					patternNamed = unwrappedPatternVariableNamed
					isLet = false
				}
				else {
					return try IfConditionsTranslation(
						conditions: [],
						statements: [unexpectedASTStructureError(
							"Unable to detect pattern in let declaration",
							ast: ifStatement, translator: self), ])
				}

				guard let rawType = optionalSomeElement["type"] else {
					return try IfConditionsTranslation(
						conditions: [],
						statements: [unexpectedASTStructureError(
							"Unable to detect type in let declaration",
							ast: ifStatement, translator: self), ])
				}

				let typeName = cleanUpType(rawType)

				guard let name = patternNamed.standaloneAttributes.first,
					let lastCondition = condition.subtrees.last else
				{
					return try IfConditionsTranslation(
						conditions: [],
						statements: [unexpectedASTStructureError(
							"Unable to get expression in let declaration",
							ast: ifStatement, translator: self), ])
				}

				let expression = try translateExpression(lastCondition)

				conditionsResult.append(.declaration(variableDeclaration: VariableDeclarationData(
					identifier: name,
					typeName: typeName,
					expression: expression,
					getter: nil, setter: nil,
					isLet: isLet,
					isImplicit: false,
					isStatic: false,
					extendsType: nil,
					annotations: nil)))
			}
			// If it's an `if case let`
			else if condition.name == "Pattern",
				let patternLet = condition.subtree(named: "Pattern Let"),
				condition.subtrees.count >= 2,
				let declarationReferenceAST = condition.subtrees.last
			{
				// TODO: test
				guard let patternLetResult = try translateEnumPattern(patternLet) else {
					return try IfConditionsTranslation(
						conditions: [],
						statements: [unexpectedASTStructureError(
							"Unable to translate Pattern Let",
							ast: ifStatement, translator: self), ])
				}

				let enumType = patternLetResult.enumType
				let enumCase = patternLetResult.enumCase
				let declarations = patternLetResult.declarations
				let comparisons = patternLetResult.comparisons
				let enumClassName = enumType + "." + enumCase.capitalizedAsCamelCase()

				let declarationReference = try translateExpression(declarationReferenceAST)

				conditionsResult.append(.condition(expression: BinaryOperatorExpression(
					range: nil,
					leftExpression: declarationReference,
					rightExpression: TypeExpression(range: nil, typeName: enumClassName),
					operatorSymbol: "is",
					typeName: "Bool")))

				// TODO: test
				for comparison in comparisons {
					conditionsResult.append(.condition(expression: BinaryOperatorExpression(
						range: nil,
						leftExpression: DotExpression(
							range: nil,
							leftExpression: declarationReference,
							rightExpression: DeclarationReferenceExpression(range: nil, data:
								DeclarationReferenceData(
									identifier: comparison.associatedValueName,
									typeName: comparison.associatedValueType,
									isStandardLibrary: false,
									isImplicit: false,
									range: comparison.comparedExpression.range))),
						rightExpression: comparison.comparedExpression,
						operatorSymbol: "==",
						typeName: "Bool")))
				}

				for declaration in declarations {
					let range = getRangeRecursively(ofNode: patternLet)

					statementsResult.append(VariableDeclaration(
						range: nil,
						data: VariableDeclarationData(
							identifier: declaration.newVariable,
							typeName: declaration.associatedValueType,
							expression: DotExpression(
								range: nil,
								leftExpression: declarationReference,
								rightExpression: DeclarationReferenceExpression(
									range: nil,
									data: DeclarationReferenceData(
										identifier: String(declaration.associatedValueName),
										typeName: declaration.associatedValueType,
										isStandardLibrary: false,
										isImplicit: false,
										range: range))),
							getter: nil,
							setter: nil,
							isLet: true,
							isImplicit: false,
							isStatic: false,
							extendsType: nil,
							annotations: nil)))
				}
			}
			// If it's an `if case`
			else if condition.name == "Pattern",
				let enumElementType = enumElementType,
				condition.subtrees.count > 1,
				let expressionTree = condition.subtrees.last
			{
				let enumTypeComponents = enumElementType
					.split(separator: ".")
					.map { String($0).capitalizedAsCamelCase() }
					.joined(separator: ".")

				let translatedExpression = try translateExpression(expressionTree)

				conditionsResult.append(.condition(expression: BinaryOperatorExpression(
					range: nil,
					leftExpression: translatedExpression,
					rightExpression: TypeExpression(range: nil, typeName: enumTypeComponents),
					operatorSymbol: "is",
					typeName: "Bool")))
			}
			else {
				conditionsResult.append(.condition(expression:
					try translateExpression(condition)))
			}
		}

		return IfConditionsTranslation(conditions: conditionsResult, statements: statementsResult)
	}

	private func translateEnumPattern(_ enumPattern: SwiftAST?)
		throws -> EnumPatternTranslation?
	{
		guard let enumPattern = enumPattern,
			(enumPattern.name == "Pattern Let" || enumPattern.name == "Pattern") else
		{
			return nil
		}

		let maybeEnumType = enumPattern["type"]
		let maybePatternEnumElement = enumPattern.subtree(named: "Pattern Enum Element")
		let maybePatternTuple = maybePatternEnumElement?.subtree(named: "Pattern Tuple")
		let maybeAssociatedValueTuple = maybePatternTuple?["type"]

		guard let enumType = maybeEnumType,
			let patternEnumElement = maybePatternEnumElement,
			let patternTuple = maybePatternTuple,
			let associatedValueTuple = maybeAssociatedValueTuple else
		{
			return nil
		}

		// Process a string like `(label1: Type1, label2: Type2)` to get the labels
		let valuesTupleWithoutParentheses = String(associatedValueTuple.dropFirst().dropLast())
		let valueTuplesComponents =
			Utilities.splitTypeList(valuesTupleWithoutParentheses, separators: [","])
		let associatedValueNames =
			valueTuplesComponents.map { $0.split(withStringSeparator: ":")[0] }

		let caseName =
			String(patternEnumElement.standaloneAttributes[0].split(separator: ".").last!)

		guard associatedValueNames.count == patternTuple.subtrees.count else {
			return nil
		}

		let associatedValuesInfo = // kotlin: ignore
			zipToClass(associatedValueNames, patternTuple.subtrees)
		// insert: val associatedValuesInfo: List<Pair<String, SwiftAST>> =
		// insert: 	associatedValueNames.zip(patternTuple.subtrees)

		let declarations: ArrayClass<AssociatedValueDeclaration> = []
		let comparisons: ArrayClass<AssociatedValueComparison> = []
		for associatedValueInfo in associatedValuesInfo {
			let associatedValueName = associatedValueInfo.0
			let ast = associatedValueInfo.1

			guard let associatedValueType = ast["type"] else {
				return nil
			}

			if ast.name == "Pattern Named" {
				declarations.append(AssociatedValueDeclaration(
					associatedValueName: String(associatedValueName),
					associatedValueType: associatedValueType,
					newVariable: ast.standaloneAttributes[0]))
				continue
			}

			let tupleExpression = ast.subtree(named: "Binary Expression")?
				.subtree(named: "Tuple Expression")
			let tupleExpressionSubtrees = tupleExpression?.subtrees
			let innerExpression = tupleExpressionSubtrees?.first
			if ast.name == "Pattern Expression", let innerExpression = innerExpression {
				let translatedExpression = try translateExpression(innerExpression)
				comparisons.append(AssociatedValueComparison(
					associatedValueName: String(associatedValueName),
					associatedValueType: associatedValueType,
					comparedExpression: translatedExpression))
				continue
			}
		}

		return EnumPatternTranslation(
			enumType: enumType,
			enumCase: caseName,
			declarations: declarations,
			comparisons: comparisons)
	}

	internal func translateFunctionDeclaration(_ functionDeclaration: SwiftAST)
		throws -> Statement?
	{
		guard SwiftTranslator.functionCompatibleASTNodes.contains(functionDeclaration.name) else {
			return try unexpectedASTStructureError(
				"Trying to translate \(functionDeclaration.name) as 'Function Declaration'",
				ast: functionDeclaration, translator: self)
		}

		// Subscripts get translated as `get(i)` or `set(i, a)` functions
		let isSubscript = (functionDeclaration.name == "Accessor Declaration")

		// Getters and setters will appear again in the Variable Declaration AST and get translated
		let isGetterOrSetter =
			(functionDeclaration["getter_for"] != nil) || (functionDeclaration["setter_for"] != nil)
		let isImplicit = functionDeclaration.standaloneAttributes.contains("implicit")
		guard !isImplicit && !isGetterOrSetter else {
			return nil
		}

		// TODO: test subscripts
		let functionName: String
		if isSubscript {
			if functionDeclaration["get_for"] != nil {
				functionName = "get"
			}
			else if functionDeclaration["set_for"] != nil {
				functionName = "set"
			}
			else {
				return try unexpectedASTStructureError(
					"Trying to translate subscript declaration that isn't getter or setter",
					ast: functionDeclaration, translator: self)
			}
		}
		else {
			functionName = functionDeclaration.standaloneAttributes.first ?? ""
		}

		let access = functionDeclaration["access"]

		// Find out if it's static and if it's mutating
		let maybeInterfaceType = functionDeclaration["interface type"]
		let maybeInterfaceTypeComponents = functionDeclaration["interface type"]?
			.split(withStringSeparator: " -> ")
		let maybeFirstInterfaceTypeComponent = maybeInterfaceTypeComponents?.first

		guard let interfaceType = maybeInterfaceType,
			let interfaceTypeComponents = maybeInterfaceTypeComponents,
			let firstInterfaceTypeComponent = maybeFirstInterfaceTypeComponent else
		{
			return try unexpectedASTStructureError(
				"Unable to find out if function is static",
				ast: functionDeclaration,
				translator: self)
		}
		let isStatic = firstInterfaceTypeComponent.contains(".Type")
		let isMutating = firstInterfaceTypeComponent.contains("inout")

		let genericTypes: ArrayClass<String>
		if let firstGenericString = functionDeclaration.standaloneAttributes
			.first(where: { $0.hasPrefix("<") })
		{
			genericTypes = ArrayClass<String>(
				firstGenericString
					.dropLast()
					.dropFirst()
					.split(separator: ",")
					.map { String($0) })
		}
		else {
			genericTypes = []
		}

		let functionNamePrefix = functionName.prefix {
			$0 !=
				"(" // value: '('
		}

		// Get the function parameters.
		let parameterList: SwiftAST?

		// If it's a method, it includes an extra Parameter List with only `self`
		let list = functionDeclaration.subtree(named: "Parameter List")
		let listStandaloneAttributes = list?.subtree(at: 0, named: "Parameter")?
			.standaloneAttributes

		if let list = list,
			let name = listStandaloneAttributes?.first,
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
		let parameters: ArrayClass<FunctionParameter> = []
		if let parameterList = parameterList {
			for parameter in parameterList.subtrees {
				if let name = parameter.standaloneAttributes.first,
					let typeName = parameter["interface type"]
				{
					guard name != "self" else {
						continue
					}

					let parameterName = name
					let parameterApiLabel = parameter["apiName"]
					let parameterType = cleanUpType(typeName)

					let defaultValue: Expression?
					if let defaultValueTree = parameter.subtrees.first {
						defaultValue = try translateExpression(defaultValueTree)
					}
					else {
						defaultValue = nil
					}

					parameters.append(FunctionParameter(
						label: parameterName,
						apiLabel: parameterApiLabel,
						typeName: parameterType,
						value: defaultValue))
				}
				else {
					return try unexpectedASTStructureError(
						"Unable to detect name or attribute for a parameter",
						ast: functionDeclaration, translator: self)
				}
			}
		}

		// Subscript setters in Kotlin must be (index, newValue) instead of Swift's
		// (newValue, index)
		if isSubscript {
			parameters.reverse()
		}

		// Translate the return type
		// FIXME: Doesn't allow to return function types
		guard let returnType = interfaceTypeComponents.last else
		{
			return try unexpectedASTStructureError(
				"Unable to get return type", ast: functionDeclaration, translator: self)
		}

		// Translate the function body
		let statements: ArrayClass<Statement>
		if let braceStatement = functionDeclaration.subtree(named: "Brace Statement") {
			statements = try translateBraceStatement(braceStatement)
		}
		else {
			statements = []
		}

		// TODO: test annotations in functions
		let annotations: ArrayClass<String?> = []
		annotations.append(getKeyedComment(forNode: functionDeclaration, key: .annotation))
		if isSubscript {
			annotations.append("operator")
		}
		let joinedAnnotations = annotations.compactMap { $0 }.joined(separator: " ")
		let annotationsResult = joinedAnnotations.isEmpty ? nil : joinedAnnotations

		let isPure = (getKeyedComment(forNode: functionDeclaration, key: .gryphon) == "pure")

		let prefix = String(functionNamePrefix)
		if prefix == "init" {
			return InitializerDeclaration(
				range: nil,
				parameters: parameters,
				returnType: returnType,
				functionType: interfaceType,
				genericTypes: genericTypes,
				isImplicit: isImplicit,
				isStatic: isStatic,
				isMutating: isMutating,
				isPure: isPure,
				extendsType: nil,
				statements: statements,
				access: access,
				annotations: annotationsResult,
				superCall: nil)
		}
		else {
			return FunctionDeclaration(
				range: nil,
				prefix: prefix,
				parameters: parameters,
				returnType: returnType,
				functionType: interfaceType,
				genericTypes: genericTypes,
				isImplicit: isImplicit,
				isStatic: isStatic,
				isMutating: isMutating,
				isPure: isPure,
				extendsType: nil,
				statements: statements,
				access: access,
				annotations: annotationsResult)
		}
	}

	internal func translateTopLevelCode(_ topLevelCodeDeclaration: SwiftAST) throws
		-> ArrayClass<Statement?>
	{
		guard topLevelCodeDeclaration.name == "Top Level Code Declaration" else {
			return try [unexpectedASTStructureError(
				"Trying to translate \(topLevelCodeDeclaration.name) as " +
				"'Top Level Code Declaration'",
				ast: topLevelCodeDeclaration, translator: self), ]
		}

		guard let braceStatement = topLevelCodeDeclaration.subtree(named: "Brace Statement") else {
			return try [unexpectedASTStructureError(
				"Unrecognized structure", ast: topLevelCodeDeclaration, translator: self), ]
		}

		let subtrees = try translateBraceStatement(braceStatement)

		return ArrayClass<Statement?>(subtrees)
	}

	internal func translateVariableDeclaration(
		_ variableDeclaration: SwiftAST)
		throws -> Statement
	{
		guard variableDeclaration.name == "Variable Declaration" else {
			return try unexpectedASTStructureError(
				"Trying to translate \(variableDeclaration.name) as 'Variable Declaration'",
				ast: variableDeclaration, translator: self)
		}

		let isImplicit = variableDeclaration.standaloneAttributes.contains("implicit")

		let annotations = getKeyedComment(forNode: variableDeclaration, key: .annotation)

		let isStatic: Bool

		let accessorDeclaration = variableDeclaration.subtree(named: "Accessor Declaration")
		let interfaceType = accessorDeclaration?["interface type"]
		let typeComponents = interfaceType?.split(withStringSeparator: " -> ")
		let firstTypeComponent = typeComponents?.first
		if let firstTypeComponent = firstTypeComponent, firstTypeComponent.contains(".Type") {
			isStatic = true
		}
		else {
			isStatic = false
		}

		guard let identifier =
			variableDeclaration.standaloneAttributes.first(where: { $0 != "implicit" }),
			let rawType = variableDeclaration["interface type"] else
		{
			return try unexpectedASTStructureError(
				"Failed to get identifier and type", ast: variableDeclaration, translator: self)
		}

		let isLet = variableDeclaration.standaloneAttributes.contains("let")
		let typeName = cleanUpType(rawType)

		// TODO: Add a warning when double optionals are found, their behaviour is different in
		// Kotlin.
		var expression: Expression?
		if !danglingPatternBindings.isEmpty {
			let firstBindingExpression = danglingPatternBindings[0]

			if let firstBindingExpression = firstBindingExpression {
				if (firstBindingExpression.identifier == identifier &&
					firstBindingExpression.typeName == typeName) ||
					(firstBindingExpression.identifier == "<<Error>>")
				{
					expression = firstBindingExpression.expression
				}
			}

			_ = danglingPatternBindings.removeFirst()
		}

		if let valueReplacement = getKeyedComment(forNode: variableDeclaration, key: .value),
			expression == nil
		{
			expression = LiteralCodeExpression(range: nil, string: valueReplacement)
		}

		var getter: FunctionDeclaration?
		var setter: FunctionDeclaration?
		for subtree in variableDeclaration.subtrees {
			let access = subtree["access"]

			let statements: ArrayClass<Statement>
			if let braceStatement = subtree.subtree(named: "Brace Statement") {
				statements = try translateBraceStatement(braceStatement)
			}
			else {
				statements = []
			}

			let isImplicit = subtree.standaloneAttributes.contains("implicit")
			let isPure = (getKeyedComment(forNode: subtree, key: .gryphon) == "pure")
			let annotations = getKeyedComment(forNode: subtree, key: .annotation)

			if subtree["get_for"] != nil {
				getter = FunctionDeclaration(
					range: nil,
					prefix: "get",
					parameters: [],
					returnType: typeName,
					functionType: "() -> (\(typeName))",
					genericTypes: [],
					isImplicit: isImplicit,
					isStatic: false,
					isMutating: false,
					isPure: isPure,
					extendsType: nil,
					statements: statements,
					access: access,
					annotations: annotations)
			}
			else if subtree["materializeForSet_for"] != nil || subtree["set_for"] != nil {
				setter = FunctionDeclaration(
					range: nil,
					prefix: "set",
					parameters: [FunctionParameter(
						label: "newValue", apiLabel: nil, typeName: typeName, value: nil), ],
					returnType: "()",
					functionType: "(\(typeName)) -> ()",
					genericTypes: [],
					isImplicit: isImplicit,
					isStatic: false,
					isMutating: false,
					isPure: isPure,
					extendsType: nil,
					statements: statements,
					access: access,
					annotations: annotations)
			}
		}

		return VariableDeclaration(range: nil, data: VariableDeclarationData(
			identifier: identifier,
			typeName: typeName,
			expression: expression,
			getter: getter,
			setter: setter,
			isLet: isLet,
			isImplicit: isImplicit,
			isStatic: isStatic,
			extendsType: nil,
			annotations: annotations))
	}

	// MARK: - Expression translations

	internal func translateExpression(_ expression: SwiftAST) throws -> Expression {

		if let valueReplacement = getKeyedComment(forNode: expression, key: .value) {
			return LiteralCodeExpression(range: nil, string: valueReplacement)
		}

		let result: Expression
		switch expression.name {
		case "Array Expression":
			result = try translateArrayExpression(expression)
		case "Dictionary Expression":
			result = try translateDictionaryExpression(expression)
		case "Binary Expression":
			result = try translateBinaryExpression(expression)
		case "If Expression":
			result = try translateIfExpression(expression)
		case "Call Expression", "Constructor Reference Call Expression":
			result = try translateCallExpression(expression)
		case "Closure Expression":
			result = try translateClosureExpression(expression)
		case "Declaration Reference Expression":
			result = try translateDeclarationReferenceExpression(expression)
		case "Dot Syntax Call Expression":
			result = try translateDotSyntaxCallExpression(expression)
		case "String Literal Expression":
			result = try translateStringLiteralExpression(expression)
		case "Interpolated String Literal Expression":
			result = try translateInterpolatedStringLiteralExpression(expression)
		case "Erasure Expression":
			if let lastExpression = expression.subtrees.last {
				// If we're erasing an optional expresison, just skip it
				if lastExpression.name == "Bind Optional Expression",
					let innerExpression = lastExpression.subtrees.last
				{
					result = try translateExpression(innerExpression)
				}
				else {
					result = try translateExpression(lastExpression)
				}
			}
			else {
				result = try unexpectedExpressionStructureError(
					"Unrecognized structure in automatic expression",
					ast: expression, translator: self)
			}
		case "Prefix Unary Expression":
			result = try translatePrefixUnaryExpression(expression)
		case "Postfix Unary Expression":
			result = try translatePostfixUnaryExpression(expression)
		case "Type Expression":
			result = try translateTypeExpression(expression)
		case "Member Reference Expression":
			result = try translateMemberReferenceExpression(expression)
		case "Tuple Element Expression":
			result = try translateTupleElementExpression(expression)
		case "Tuple Expression":
			result = try translateTupleExpression(expression)
		case "Subscript Expression":
			result = try translateSubscriptExpression(expression)
		case "Nil Literal Expression":
			result = NilLiteralExpression(range: nil)
		case "Open Existential Expression":
			let processedExpression = try processOpenExistentialExpression(expression)
			result = try translateExpression(processedExpression)
		case "Parentheses Expression":
			if let innerExpression = expression.subtree(at: 0) {
				// Swift 5: Compiler-created parentheses expressions may be marked with "implicit"
				if expression.standaloneAttributes.contains("implicit") {
					result = try translateExpression(innerExpression)
				}
				else {
					result = ParenthesesExpression(
						range: nil,
						expression: try translateExpression(innerExpression))
				}
			}
			else {
				result = try unexpectedExpressionStructureError(
					"Expected parentheses expression to have at least one subtree",
					ast: expression, translator: self)
			}
		case "Force Value Expression":
			if let firstExpression = expression.subtree(at: 0) {
				let expression = try translateExpression(firstExpression)
				result = ForceValueExpression(range: nil, expression: expression)
			}
			else {
				result = try unexpectedExpressionStructureError(
					"Expected force value expression to have at least one subtree",
					ast: expression, translator: self)
			}
		case "Bind Optional Expression":
			if let firstExpression = expression.subtree(at: 0) {
				let expression = try translateExpression(firstExpression)
				result = OptionalExpression(range: nil, expression: expression)
			}
			else {
				result = try unexpectedExpressionStructureError(
					"Expected optional expression to have at least one subtree",
					ast: expression, translator: self)
			}
		case "Conditional Checked Cast Expression":
			let subExpression = expression.subtrees.first
			let subExpressionSubtrees = subExpression?.subtrees
			let subSubExpression = subExpressionSubtrees?.first
			let typeName = expression["type"]

			if let typeName = typeName, let subSubExpression = subSubExpression {
				result = BinaryOperatorExpression(
					range: nil,
					leftExpression: try translateExpression(subSubExpression),
					rightExpression: TypeExpression(range: nil, typeName: typeName),
					operatorSymbol: "as?",
					typeName: typeName)
			}
			else if let typeName = typeName, let subExpression = subExpression {
				result = BinaryOperatorExpression(
					range: nil,
					leftExpression: try translateExpression(subExpression),
					rightExpression: TypeExpression(range: nil, typeName: typeName),
					operatorSymbol: "as?",
					typeName: typeName)
			}
			else {
				result = try unexpectedExpressionStructureError(
					"Expected Conditional Checked Cast Expression to have a type and " +
					"an expression as a subtree",
					ast: expression, translator: self)
			}
		case "Is Subtype Expression":
			let subExpression = expression.subtrees.first
			let typeName = expression["writtenType"]

			if let typeName = typeName, let subExpression = subExpression {
				result = BinaryOperatorExpression(
					range: nil,
					leftExpression: try translateExpression(subExpression),
					rightExpression: TypeExpression(range: nil, typeName: typeName),
					operatorSymbol: "is",
					typeName: "Bool")
			}
			else {
				result = try unexpectedExpressionStructureError(
					"Expected Is Subtype Expression to have a type and an expression as a subtree",
					ast: expression, translator: self)
			}
		case "Super Reference Expression":
			if let typeName = expression["type"] {
				result = DeclarationReferenceExpression(range: nil, data: DeclarationReferenceData(
					identifier: "super",
					typeName: typeName,
					isStandardLibrary: false,
					isImplicit: false,
					range: getRange(ofNode: expression)))
			}
			else {
				result = try unexpectedExpressionStructureError(
					"Unable to get type from Super Reference Expression",
					ast: expression, translator: self)
			}
		case "Autoclosure Expression",
			 "Inject Into Optional",
			 "Optional Evaluation Expression",
			 "Inout Expression",
			 "Load Expression",
			 "Function Conversion Expression",
			 "Try Expression",
			 "Force Try Expression",
			 "Dot Self Expression",
			 "Derived To Base Expression",
			 "Rebind Self In Constructor Expression":

			if let lastExpression = expression.subtrees.last {
				result = try translateExpression(lastExpression)
			}
			else {
				result = try unexpectedExpressionStructureError(
					"Unrecognized structure in automatic expression",
					ast: expression, translator: self)
			}
		case "Collection Upcast Expression":
			if let firstExpression = expression.subtrees.first {
				result = try translateExpression(firstExpression)
			}
			else {
				result = try unexpectedExpressionStructureError(
					"Unrecognized structure in automatic expression",
					ast: expression, translator: self)
			}
		case "Other Constructor Reference Expression":
			result = DeclarationReferenceExpression(range: nil, data: DeclarationReferenceData(
				identifier: "init",
				typeName: expression["type"]!,
				isStandardLibrary: false,
				isImplicit: false,
				range: nil))

		default:
			result = try unexpectedExpressionStructureError(
				"Unknown expression", ast: expression, translator: self)
		}

		let shouldInspect = (getKeyedComment(forNode: expression, key: .gryphon) == "inspect")
		if shouldInspect {
			print("===\nInspecting:")
			print(expression)
			result.prettyPrint()
		}

		return result
	}

	internal func translateTypeExpression(_ typeExpressionFixme: SwiftAST) throws -> Expression {
		guard typeExpressionFixme.name == "Type Expression" else {
			return try unexpectedExpressionStructureError(
				"Trying to translate \(typeExpressionFixme.name) as 'Type Expression'",
				ast: typeExpressionFixme, translator: self)
		}

		guard let typeName = typeExpressionFixme["typerepr"] else {
			return try unexpectedExpressionStructureError(
				"Unrecognized structure",
				ast: typeExpressionFixme, translator: self)
		}

		return TypeExpression(range: nil, typeName: cleanUpType(typeName))
	}

	internal func translateCallExpression(_ callExpressionFixme: SwiftAST) throws -> Expression {
		guard callExpressionFixme.name == "Call Expression" else {
			return try unexpectedExpressionStructureError(
				"Trying to translate \(callExpressionFixme.name) as 'Call Expression'",
				ast: callExpressionFixme, translator: self)
		}

		// If the call expression corresponds to an integer literal
		if let argumentLabels = callExpressionFixme["arg_labels"] {
			if argumentLabels == "_builtinIntegerLiteral:" ||
				argumentLabels == "_builtinFloatLiteral:"
			{
				return try translateAsNumericLiteral(callExpressionFixme)
			}
			else if argumentLabels == "_builtinBooleanLiteral:" {
				return try translateAsBooleanLiteral(callExpressionFixme)
			}
			else if argumentLabels == "nilLiteral:" {
				return NilLiteralExpression(range: nil)
			}
		}

		let function: Expression

		// If it's an empty expression used in an "if" condition
		let dotSyntaxSubtrees = callExpressionFixme
			.subtree(named: "Dot Syntax Call Expression")?.subtrees
		let containedExpression = dotSyntaxSubtrees?.last

		if let containedExpression = containedExpression,
			callExpressionFixme.standaloneAttributes.contains("implicit"),
			callExpressionFixme["arg_labels"] == "",
			callExpressionFixme["type"] == "Int1"
		{
			return try translateExpression(containedExpression)
		}

		guard let rawType = callExpressionFixme["type"] else {
			return try unexpectedExpressionStructureError(
				"Failed to recognize type", ast: callExpressionFixme, translator: self)
		}
		let typeName = cleanUpType(rawType)

		let dotSyntaxCallExpression = callExpressionFixme
			.subtree(named: "Dot Syntax Call Expression")
		let methodName = dotSyntaxCallExpression?
			.subtree(at: 0, named: "Declaration Reference Expression")
		let methodOwner = dotSyntaxCallExpression?.subtree(at: 1)

		if let methodName = methodName, let methodOwner = methodOwner {
			let methodName = try translateDeclarationReferenceExpression(methodName)
			let methodOwner = try translateExpression(methodOwner)
			function = DotExpression(
				range: nil,
				leftExpression: methodOwner,
				rightExpression: methodName)
		}
		else if let declarationReferenceExpression = callExpressionFixme
			.subtree(named: "Declaration Reference Expression")
		{
			function = try translateDeclarationReferenceExpression(
				declarationReferenceExpression)
		}
		else if let typeExpression = callExpressionFixme
			.subtree(named: "Constructor Reference Call Expression")?
			.subtree(named: "Type Expression")
		{
			function = try translateTypeExpression(typeExpression)
		}
		else {
			function = try translateExpression(callExpressionFixme.subtrees[0])
		}

		let parameters = try translateCallExpressionParameters(callExpressionFixme)

		let range = getRange(ofNode: callExpressionFixme)

		return CallExpression(range: nil, data: CallExpressionData(
			function: function,
			parameters: parameters,
			typeName: typeName,
			range: range))
	}

	internal func translateClosureExpression(_ closureExpressionFixme: SwiftAST) throws -> Expression {
		guard closureExpressionFixme.name == "Closure Expression" else {
			return try unexpectedExpressionStructureError(
				"Trying to translate \(closureExpressionFixme.name) as 'Closure Expression'",
				ast: closureExpressionFixme, translator: self)
		}

		// Get the parameters.
		let parameterList: SwiftAST?

		if let unwrapped = closureExpressionFixme.subtree(named: "Parameter List") {
			parameterList = unwrapped
		}
		else {
			parameterList = nil
		}

		// Translate the parameters
		let parameters: ArrayClass<LabeledType> = []
		if let parameterList = parameterList {
			for parameter in parameterList.subtrees {
				if let name = parameter.standaloneAttributes.first,
					let typeName = parameter["interface type"]
				{
					if name.hasPrefix("anonname=0x") {
						continue
					}
					parameters.append(LabeledType(label: name, typeName: cleanUpType(typeName)))
				}
				else {
					return try unexpectedExpressionStructureError(
						"Unable to detect name or attribute for a parameter",
						ast: closureExpressionFixme, translator: self)
				}
			}
		}

		// Translate the return type
		// FIXME: Doesn't allow to return function types
		guard let typeName = closureExpressionFixme["type"] else {
			return try unexpectedExpressionStructureError(
				"Unable to get type or return type", ast: closureExpressionFixme, translator: self)
		}

		// Translate the closure body
		guard let lastSubtree = closureExpressionFixme.subtrees.last else {
			return try unexpectedExpressionStructureError(
				"Unable to get closure body", ast: closureExpressionFixme, translator: self)
		}

		let statements: ArrayClass<Statement>
		if lastSubtree.name == "Brace Statement" {
			statements = try translateBraceStatement(lastSubtree)
		}
		else {
			let expression = try translateExpression(lastSubtree)
			statements = [ExpressionStatement(range: nil, expression: expression)]
		}

		return ClosureExpression(
			range: nil,
			parameters: parameters,
			statements: statements,
			typeName: cleanUpType(typeName))
	}

	internal func translateCallExpressionParameters(_ callExpression: SwiftAST) throws
		-> Expression
	{
		guard callExpression.name == "Call Expression" else {
			return try unexpectedExpressionStructureError(
				"Trying to translate \(callExpression.name) as 'Call Expression'",
				ast: callExpression, translator: self)
		}

		let parameters: Expression
		if let parenthesesExpression = callExpression.subtree(named: "Parentheses Expression") {
			let expression = try translateExpression(parenthesesExpression)
			parameters = TupleExpression(
				range: nil,
				pairs: [LabeledExpression(label: nil, expression: expression)])
		}
		else if let tupleExpression = callExpression.subtree(named: "Tuple Expression") {
			parameters = try translateTupleExpression(tupleExpression)
		}
		else if let tupleShuffleExpressionFixme = callExpression
			.subtree(named: "Tuple Shuffle Expression")
		{
			let parenthesesExpression = tupleShuffleExpressionFixme
				.subtree(named: "Parentheses Expression")

			let tupleExpressionFixme = tupleShuffleExpressionFixme.subtree(named: "Tuple Expression")
			let typeName = tupleShuffleExpressionFixme["type"]
			let elements = tupleShuffleExpressionFixme["elements"]
			let rawIndicesStrings = elements?.split(withStringSeparator: ", ")
			let rawIndices = rawIndicesStrings.map({ $0.map { Int($0) } })

			if let parenthesesExpression = parenthesesExpression {
				let expression = try translateExpression(parenthesesExpression)
				parameters = TupleExpression(
					range: nil,
					pairs: [LabeledExpression(label: nil, expression: expression)])
			}
			else if let tupleExpression = tupleExpressionFixme,
				let typeName = typeName,
				let rawIndices = rawIndices
			{
				let indices: ArrayClass<TupleShuffleIndex> = []
				for rawIndex in rawIndices {

					guard let rawIndex = rawIndex else {
						return try unexpectedExpressionStructureError(
							"Expected Tuple shuffle index but found nil",
							ast: callExpression,
							translator: self)
					}

					if rawIndex == -2 {
						let variadicSources = tupleShuffleExpressionFixme["variadic_sources"]?
							.split(withStringSeparator: ", ")
						guard let variadicCount = variadicSources?.count else {
							return try unexpectedExpressionStructureError(
								"Failed to read variadic sources",
								ast: callExpression,
								translator: self)
						}
						indices.append(.variadic(count: variadicCount))
					}
					else if rawIndex == -1 {
						indices.append(.absent)
					}
					else if rawIndex >= 0 {
						indices.append(.present)
					}
					else {
						return try unexpectedExpressionStructureError(
							"Unknown tuple shuffle index: \(rawIndex)",
							ast: callExpression,
							translator: self)
					}
				}

				let tupleComponents =
					String(typeName.dropFirst().dropLast()).split(withStringSeparator: ", ")
				let labels = tupleComponents
					.map { $0.prefix(while: {
						$0 !=
							":" // value: ':'
					}) }
					.map { String($0) }
				let expressions = try tupleExpression.subtrees.map {
					try translateExpression($0)
				}
				parameters = TupleShuffleExpression(
					range: nil,
					labels: labels,
					indices: indices,
					expressions: expressions)
			}
			else {
				return try unexpectedExpressionStructureError(
					"Unrecognized structure in parameters", ast: callExpression, translator: self)
			}
		}
		else {
			return try unexpectedExpressionStructureError(
				"Unrecognized structure in parameters", ast: callExpression, translator: self)
		}

		return parameters
	}

	internal func translateTupleExpression(_ tupleExpressionFixme: SwiftAST) throws -> Expression {
		guard tupleExpressionFixme.name == "Tuple Expression" else {
			return try unexpectedExpressionStructureError(
				"Trying to translate \(tupleExpressionFixme.name) as 'Tuple Expression'",
				ast: tupleExpressionFixme, translator: self)
		}

		// Only empty tuples don't have a list of names
		guard let names = tupleExpressionFixme["names"] else {
			return TupleExpression(range: nil, pairs: [])
		}

		let namesArray = ArrayClass<Substring>(names.split(separator: ","))

		let tuplePairs: ArrayClass<LabeledExpression> = []

		for (name, expression) in zipToClass(namesArray, tupleExpressionFixme.subtrees) {
			let expression = try translateExpression(expression)

			// Empty names (like the underscore in "foo(_:)") are represented by ''
			if name == "_" {
				tuplePairs.append(LabeledExpression(label: nil, expression: expression))
			}
			else {
				tuplePairs.append(
					LabeledExpression(label: String(name), expression: expression))
			}
		}

		return TupleExpression(range: nil, pairs: tuplePairs)
	}

	internal func translateInterpolatedStringLiteralExpression(
		_ interpolatedStringLiteralExpressionFixme: SwiftAST)
		throws -> Expression
	{
		guard interpolatedStringLiteralExpressionFixme.name == "Interpolated String Literal Expression"
			else
		{
			return try unexpectedExpressionStructureError(
				"Trying to translate \(interpolatedStringLiteralExpressionFixme.name) as " +
				"'Interpolated String Literal Expression'",
				ast: interpolatedStringLiteralExpressionFixme, translator: self)
		}

		guard let braceStatement = interpolatedStringLiteralExpressionFixme
			.subtree(named: "Tap Expression")?
			.subtree(named: "Brace Statement") else
		{
			return try unexpectedExpressionStructureError(
				"Expected the Interpolated String Literal Expression to contain a Tap" +
					"Expression containing a Brace Statement containing the String " +
				"interpolation contents",
				ast: interpolatedStringLiteralExpressionFixme, translator: self)
		}

		let expressions: ArrayClass<Expression> = []

		for callExpression in braceStatement.subtrees.dropFirst() {
			let maybeSubtrees = callExpression.subtree(named: "Parentheses Expression")?.subtrees
			let maybeExpression = maybeSubtrees?.first
			guard callExpression.name == "Call Expression",
				let expression = maybeExpression else
			{
				return try unexpectedExpressionStructureError(
					"Expected the brace statement to contain only Call Expressions containing " +
					"Parentheses Expressions containing the relevant expressions.",
					ast: interpolatedStringLiteralExpressionFixme, translator: self)
			}

			let translatedExpression = try translateExpression(expression)
			expressions.append(translatedExpression)
		}

		return InterpolatedStringLiteralExpression(range: nil, expressions: expressions)
	}

	internal func translateSubscriptExpression(_ subscriptExpressionFixme: SwiftAST)
		throws -> Expression
	{
		guard subscriptExpressionFixme.name == "Subscript Expression" else {
			return try unexpectedExpressionStructureError(
				"Trying to translate \(subscriptExpressionFixme.name) as 'Subscript Expression'",
				ast: subscriptExpressionFixme, translator: self)
		}

		let rawType = subscriptExpressionFixme["type"]
		let subscriptContents = subscriptExpressionFixme.subtree(
			at: 1,
			named: "Parentheses Expression") ??
			subscriptExpressionFixme.subtree(
				at: 1, named: "Tuple Expression")
		let subscriptedExpression = subscriptExpressionFixme.subtree(at: 0)

		if let rawType = rawType,
			let subscriptContents = subscriptContents,
			let subscriptedExpression = subscriptedExpression
		{
			let typeName = cleanUpType(rawType)
			let subscriptContentsTranslation = try translateExpression(subscriptContents)
			let subscriptedExpressionTranslation = try translateExpression(subscriptedExpression)

			return SubscriptExpression(
				range: nil,
				subscriptedExpression: subscriptedExpressionTranslation,
				indexExpression: subscriptContentsTranslation,
				typeName: typeName)
		}
		else {
			return try unexpectedExpressionStructureError(
				"Unrecognized structure", ast: subscriptExpressionFixme, translator: self)
		}
	}

	internal func translateArrayExpression(_ arrayExpressionFixme: SwiftAST) throws -> Expression {
		guard arrayExpressionFixme.name == "Array Expression" else {
			return try unexpectedExpressionStructureError(
				"Trying to translate \(arrayExpressionFixme.name) as 'Array Expression'",
				ast: arrayExpressionFixme, translator: self)
		}

		// Drop the "Semantic Expression" at the end
		let expressionsToTranslate = ArrayClass<SwiftAST>(arrayExpressionFixme.subtrees.dropLast())

		let expressionsArray = try expressionsToTranslate.map { try translateExpression($0) }

		guard let rawType = arrayExpressionFixme["type"] else {
			return try unexpectedExpressionStructureError(
				"Failed to get type", ast: arrayExpressionFixme, translator: self)
		}
		let typeName = cleanUpType(rawType)

		return ArrayExpression(range: nil, elements: expressionsArray, typeName: typeName)
	}

	internal func translateDictionaryExpression(_ dictionaryExpressionFixme: SwiftAST)
		throws -> Expression
	{
		guard dictionaryExpressionFixme.name == "Dictionary Expression" else {
			return try unexpectedExpressionStructureError(
				"Trying to translate \(dictionaryExpressionFixme.name) as 'Dictionary Expression'",
				ast: dictionaryExpressionFixme, translator: self)
		}

		let keys: ArrayClass<Expression> = []
		let values: ArrayClass<Expression> = []
		for tupleExpression in dictionaryExpressionFixme.subtrees {
			guard tupleExpression.name == "Tuple Expression" else {
				continue
			}
			guard let keyAST = tupleExpression.subtree(at: 0),
				let valueAST = tupleExpression.subtree(at: 1) else
			{
				return try unexpectedExpressionStructureError(
					"Unable to get either key or value for one of the tuple expressions",
					ast: dictionaryExpressionFixme, translator: self)
			}

			let keyTranslation = try translateExpression(keyAST)
			let valueTranslation = try translateExpression(valueAST)
			keys.append(keyTranslation)
			values.append(valueTranslation)
		}

		guard let typeName = dictionaryExpressionFixme["type"] else {
			return try unexpectedExpressionStructureError(
				"Unable to get type",
				ast: dictionaryExpressionFixme, translator: self)
		}

		return DictionaryExpression(range: nil, keys: keys, values: values, typeName: typeName)
	}

	internal func translateAsNumericLiteral(_ callExpression: SwiftAST) throws -> Expression {
		guard callExpression.name == "Call Expression" else {
			return try unexpectedExpressionStructureError(
				"Trying to translate \(callExpression.name) as 'Call Expression'",
				ast: callExpression, translator: self)
		}

		// FIXME: Negative float literals are translated as positive becuase the AST dump doesn't
		// seemd to include any info showing they're negative.
		// Bug filed at https://bugs.swift.org/browse/SR-10131
		let tupleExpression = callExpression.subtree(named: "Tuple Expression")
		let literalExpression = tupleExpression?.subtree(named: "Integer Literal Expression") ??
			tupleExpression?.subtree(named: "Float Literal Expression")
		let value = literalExpression?["value"]

		let constructorReferenceCallExpression = callExpression
			.subtree(named: "Constructor Reference Call Expression")
		let typeExpression = constructorReferenceCallExpression?.subtree(named: "Type Expression")
		let rawType = typeExpression?["typerepr"]

		if let value = value, let literalExpression = literalExpression, let rawType = rawType {
			if value.hasPrefix("0b") || value.hasPrefix("0o") || value.hasPrefix("0x") {
				// Fixable
				return try unexpectedExpressionStructureError(
					"No support yet for alternative integer formats",
					ast: callExpression,
					translator: self)
			}

			let signedValue: String
			if literalExpression.standaloneAttributes.contains("negative") {
				signedValue = "-" + value
			}
			else {
				signedValue = value
			}

			let typeName = cleanUpType(rawType)
			if typeName == "Double" || typeName == "Float64" {
				return LiteralDoubleExpression(range: nil, value: Double(signedValue)!)
			}
			else if typeName == "Float" || typeName == "Float32" {
				return LiteralFloatExpression(range: nil, value: Float(signedValue)!)
			}
			else if typeName == "Float80" {
				return try unexpectedExpressionStructureError(
					"No support for 80-bit Floats", ast: callExpression, translator: self)
			}
			else if typeName.hasPrefix("U") {
				return LiteralUIntExpression(range: nil, value: UInt64(signedValue)!)
			}
			else {
				if signedValue == "-9223372036854775808" {
					return try unexpectedExpressionStructureError(
						"Kotlin's Long (equivalent to Int64) only goes down to " +
						"-9223372036854775807", ast: callExpression, translator: self)
				}
				else {
					return LiteralIntExpression(range: nil, value: Int64(signedValue)!)
				}
			}
		}
		else {
			return try unexpectedExpressionStructureError(
				"Unrecognized structure for numeric literal", ast: callExpression, translator: self)
		}
	}

	internal func translateAsBooleanLiteral(_ callExpression: SwiftAST) throws
		-> Expression
	{
		guard callExpression.name == "Call Expression" else {
			return try unexpectedExpressionStructureError(
				"Trying to translate \(callExpression.name) as 'Call Expression'",
				ast: callExpression, translator: self)
		}

		if let value = callExpression
			.subtree(named: "Tuple Expression")?
			.subtree(named: "Boolean Literal Expression")?["value"]
		{
			return LiteralBoolExpression(range: nil, value: (value == "true"))
		}
		else {
			return try unexpectedExpressionStructureError(
				"Unrecognized structure for boolean literal", ast: callExpression, translator: self)
		}
	}

	internal func translateStringLiteralExpression(
		_ stringLiteralExpression: SwiftAST)
		throws -> Expression
	{
		guard stringLiteralExpression.name == "String Literal Expression" else {
			return try unexpectedExpressionStructureError(
				"Trying to translate \(stringLiteralExpression.name) as " +
				"'String Literal Expression'",
				ast: stringLiteralExpression, translator: self)
		}

		if let value = stringLiteralExpression["value"] {
			if stringLiteralExpression["type"] == "Character" {
				if value == "\'" {
					return LiteralCharacterExpression(range: nil, value: "\\\'")
				}
				else {
					return LiteralCharacterExpression(range: nil, value: value)
				}
			}
			else {
				return LiteralStringExpression(range: nil, value: value)
			}
		}
		else {
			return try unexpectedExpressionStructureError(
				"Unrecognized structure", ast: stringLiteralExpression, translator: self)
		}
	}

	internal func translateDeclarationReferenceExpression(
		_ declarationReferenceExpressionFixme: SwiftAST)
		throws -> Expression
	{
		guard declarationReferenceExpressionFixme.name == "Declaration Reference Expression" else {
			return try unexpectedExpressionStructureError(
				"Trying to translate \(declarationReferenceExpressionFixme.name) as " +
				"'Declaration Reference Expression'",
				ast: declarationReferenceExpressionFixme, translator: self)
		}

		guard let rawType = declarationReferenceExpressionFixme["type"] else {
			return try unexpectedExpressionStructureError(
				"Failed to recognize type", ast: declarationReferenceExpressionFixme, translator: self)
		}
		let typeName = cleanUpType(rawType)

		let isImplicit = declarationReferenceExpressionFixme.standaloneAttributes.contains("implicit")

		let range = getRange(ofNode: declarationReferenceExpressionFixme)

		if let discriminator = declarationReferenceExpressionFixme["discriminator"] {
			let declarationInformation = getInformationFromDeclaration(discriminator)

			return DeclarationReferenceExpression(range: nil, data: DeclarationReferenceData(
				identifier: declarationInformation.identifier,
				typeName: typeName,
				isStandardLibrary: declarationInformation.isStandardLibrary,
				isImplicit: isImplicit,
				range: range))
		}
		else if let codeDeclaration = declarationReferenceExpressionFixme.standaloneAttributes.first,
			codeDeclaration.hasPrefix("code.")
		{
			let declarationInformation = getInformationFromDeclaration(codeDeclaration)
			return DeclarationReferenceExpression(range: nil, data: DeclarationReferenceData(
				identifier: declarationInformation.identifier,
				typeName: typeName,
				isStandardLibrary: declarationInformation.isStandardLibrary,
				isImplicit: isImplicit,
				range: range))
		}
		else if let declaration = declarationReferenceExpressionFixme["decl"] {
			let declarationInformation = getInformationFromDeclaration(declaration)
			return DeclarationReferenceExpression(range: nil, data: DeclarationReferenceData(
				identifier: declarationInformation.identifier,
				typeName: typeName,
				isStandardLibrary: declarationInformation.isStandardLibrary,
				isImplicit: isImplicit,
				range: range))
		}
		else {
			return try unexpectedExpressionStructureError(
				"Unrecognized structure", ast: declarationReferenceExpressionFixme, translator: self)
		}
	}

	// MARK: - Source file interactions

	internal func insertedCode(inRange range: Range<Int>) -> ArrayClass<Statement> {
		let result: ArrayClass<Statement> = []
		for lineNumber in range {
			if let insertComment = sourceFile?.getKeyedCommentFromLine(lineNumber) {
				if insertComment.key == .insert {
					result.append(ExpressionStatement(range: nil, expression:
						LiteralCodeExpression(range: nil, string: insertComment.value)))
				}
				else if insertComment.key == .declaration {
					result.append(ExpressionStatement(range: nil, expression:
						LiteralDeclarationExpression(range: nil, string: insertComment.value)))
				}
			}
			else if let normalComment = sourceFile?.getCommentFromLine(lineNumber) {
				result.append(CommentStatement(
					range: normalComment.range,
					value: normalComment.contents))
			}
		}
		return result
	}

	internal func getRangeRecursively(ofNode ast: SwiftAST) -> SourceFileRange? {
		if let range = getRange(ofNode: ast) {
			return range
		}

		for subtree in ast.subtrees {
			if let range = getRange(ofNode: subtree) {
				return range
			}
		}

		return nil
	}

	internal func getKeyedComment(forNode ast: SwiftAST, key: SourceFile.CommentKey) -> String? {
		if let comment = getKeyedComment(forNode: ast), comment.key == key {
			return comment.value
		}
		return nil
	}

	internal func getKeyedComment(forNode ast: SwiftAST) -> SourceFile.KeyedComment? {
		if let lineNumber = getRange(ofNode: ast)?.lineStart {
			return sourceFile?.getKeyedCommentFromLine(lineNumber)
		}
		else {
			return nil
		}
	}

	/// Extracts the range numbers from a string in the form
	/// `Path/to/file.swift:1:2 - line:3:4`, where the numbers 1, 2, 3 and 4 represent (in order)
	/// the lineStart, columnStart, lineEnd and columndEnd.
	internal func getRange(ofNode ast: SwiftAST) -> SourceFileRange? {
		guard let rangeString = ast["range"] else {
			return nil
		}

		guard let firstSwiftExtensionEndIndex =
			rangeString.occurrences(of: ".swift:").first?.upperBound else
		{
			return nil
		}

		// - Get the line start number
		var numberStartIndex = firstSwiftExtensionEndIndex
		// Find the end of the number
		var numberEndIndex = numberStartIndex
		while rangeString[numberEndIndex].isNumber {
			numberEndIndex = rangeString.index(after: numberEndIndex)
		}
		// Turn the number string into an Int
		let lineStartString = rangeString[numberStartIndex..<numberEndIndex]
		guard let lineStart = Int(lineStartString) else {
			return nil
		}

		// - Get the column start number
		// Skip the ":"
		numberStartIndex = rangeString.index(after: numberEndIndex)
		// Find the end of the number
		numberEndIndex = numberStartIndex
		while rangeString[numberEndIndex].isNumber {
			numberEndIndex = rangeString.index(after: numberEndIndex)
		}
		// Turn the number string into an Int
		let columnStartString = rangeString[numberStartIndex..<numberEndIndex]
		guard let columnStart = Int(columnStartString) else {
			return nil
		}

		// - Get the line end number
		// Skip the " - line:"
		numberStartIndex = rangeString.index(numberEndIndex, offsetBy: " - line:".count)
		// Find the end of the number
		numberEndIndex = numberStartIndex
		while rangeString[numberEndIndex].isNumber {
			numberEndIndex = rangeString.index(after: numberEndIndex)
		}
		// Turn the number string into an Int
		let lineEndString = rangeString[numberStartIndex..<numberEndIndex]
		guard let lineEnd = Int(lineEndString) else {
			return nil
		}

		// - Get the column end number
		// Skip the ":"
		numberStartIndex = rangeString.index(after: numberEndIndex)
		// Find the end of the number
		numberEndIndex = numberStartIndex
		while numberEndIndex < rangeString.endIndex, rangeString[numberEndIndex].isNumber {
			numberEndIndex = rangeString.index(after: numberEndIndex)
		}
		// Turn the number string into an Int
		let columnEndString = rangeString[numberStartIndex..<numberEndIndex]
		guard let columnEnd = Int(columnEndString) else {
			return nil
		}

		return SourceFileRange(
			lineStart: lineStart,
			lineEnd: lineEnd,
			columnStart: columnStart,
			columnEnd: columnEnd)
	}

	// MARK: - Helper functions

	internal func processPatternBindingDeclaration(_ patternBindingDeclaration: SwiftAST) throws {
		guard patternBindingDeclaration.name == "Pattern Binding Declaration" else {
			_ = try unexpectedExpressionStructureError(
				"Trying to translate \(patternBindingDeclaration.name) as " +
				"'Pattern Binding Declaration'",
				ast: patternBindingDeclaration, translator: self)
			danglingPatternBindings = [errorDanglingPatternDeclaration]
			return
		}

		let result: ArrayClass<PatternBindingDeclaration?> = []

		let subtreesCopy = patternBindingDeclaration.subtrees.copy()
		while !subtreesCopy.isEmpty {
			var pattern = subtreesCopy[0]
			subtreesCopy.removeFirst()

			if let newPattern = pattern.subtree(named: "Pattern Named"),
				pattern.name == "Pattern Typed"
			{
				pattern = newPattern
			}

			if let expression = subtreesCopy.first, astIsExpression(expression) {
				_ = subtreesCopy.removeFirst()

				let translatedExpression = try translateExpression(expression)

				guard let identifier = pattern.standaloneAttributes.first,
					let rawType = pattern["type"] else
				{
					_ = try unexpectedExpressionStructureError(
						"Type not recognized", ast: patternBindingDeclaration, translator: self)
					result.append(errorDanglingPatternDeclaration)
					continue
				}

				let typeName = cleanUpType(rawType)

				result.append(PatternBindingDeclaration(
					identifier: identifier,
					typeName: typeName,
					expression: translatedExpression))
			}
			else {
				result.append(nil)
			}
		}

		danglingPatternBindings = result
	}

	internal func processOpenExistentialExpression(_ openExistentialExpression: SwiftAST)
		throws -> SwiftAST
	{
		guard openExistentialExpression.name == "Open Existential Expression" else {
			_ = try unexpectedExpressionStructureError(
				"Trying to translate \(openExistentialExpression.name) as " +
				"'Open Existential Expression'",
				ast: openExistentialExpression, translator: self)
			return SwiftAST("Error", [], [:], [])
		}

		guard let replacementSubtree = openExistentialExpression.subtree(at: 1),
			let resultSubtree = openExistentialExpression.subtrees.last else
		{
			_ = try unexpectedExpressionStructureError(
				"Expected the AST to contain 3 subtrees: an Opaque Value Expression, an " +
					"expression to replace the opaque value, and an expression containing " +
				"opaque values to be replaced.",
				ast: openExistentialExpression, translator: self)
			return SwiftAST("Error", [], [:], [])
		}

		return astReplacingOpaqueValues(in: resultSubtree, with: replacementSubtree)
	}

	internal func astReplacingOpaqueValues(in ast: SwiftAST, with replacementAST: SwiftAST)
		-> SwiftAST
	{
		if ast.name == "Opaque Value Expression" {
			return replacementAST
		}

		let newSubtrees: ArrayClass<SwiftAST> = []
		for subtree in ast.subtrees {
			newSubtrees.append(astReplacingOpaqueValues(in: subtree, with: replacementAST))
		}

		return SwiftAST(
			ast.name,
			ast.standaloneAttributes,
			ast.keyValueAttributes,
			newSubtrees)
	}

	internal func getInformationFromDeclaration(_ declaration: String)
		-> DeclarationInformation
	{
		let isStandardLibrary = declaration.hasPrefix("Swift.")

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

		// If it's an identifier that contains periods, like the range operators `..<` etc
		var beforeLastPeriodIndex = declaration.index(before: lastPeriodIndex)
		while declaration[beforeLastPeriodIndex] == "." {
			lastPeriodIndex = beforeLastPeriodIndex
			beforeLastPeriodIndex = declaration.index(before: lastPeriodIndex)
		}

		let identifierStartIndex = declaration.index(after: lastPeriodIndex)

		let identifier = declaration[identifierStartIndex..<index]

		return DeclarationInformation(
			identifier: String(identifier),
			isStandardLibrary: isStandardLibrary)
	}

	internal func cleanUpType(_ typeName: String) -> String {
		if typeName.hasPrefix("@lvalue ") {
			return String(typeName.suffix(from: "@lvalue ".endIndex))
		}
		else if typeName.hasPrefix("("),
			typeName.hasSuffix(")"),
			!typeName.contains("->"),
			!typeName.contains(",")
		{
			return String(typeName.dropFirst().dropLast())
		}
		else {
			return typeName
		}
	}

	internal func astIsExpression(_ ast: SwiftAST) -> Bool {
		return ast.name.hasSuffix("Expression") || ast.name == "Inject Into Optional"
	}

	// MARK: - Error handling

	func createUnexpectedASTStructureError(
		_ errorMessage: String,
		ast: SwiftAST,
		translator: SwiftTranslator)
		-> SwiftTranslatorError
	{
		return SwiftTranslatorError(
			errorMessage: errorMessage,
			ast: ast,
			translator: translator)
	}

	func handleUnexpectedASTStructureError(_ error: Error) throws -> Statement {
		try Compiler.handleError(error)
		return ErrorStatement(range: nil)
	}

	func unexpectedASTStructureError(
		_ errorMessage: String,
		ast: SwiftAST,
		translator: SwiftTranslator)
		throws -> Statement
	{
		let error = createUnexpectedASTStructureError(
			errorMessage,
			ast: ast,
			translator: translator)
		return try handleUnexpectedASTStructureError(error)
	}

	func unexpectedExpressionStructureError(
		_ errorMessage: String,
		ast: SwiftAST,
		translator: SwiftTranslator)
		throws -> Expression
	{
		let errorFixme = SwiftTranslatorError(
			errorMessage: errorMessage,
			ast: ast,
			translator: translator)
		try Compiler.handleError(errorFixme)
		return ErrorExpression(range: nil)
	}
}

// MARK: - Supporting structs

struct PatternBindingDeclaration {
	let identifier: String
	let typeName: String
	let expression: Expression?
}

struct DeclarationInformation {
	let identifier: String
	let isStandardLibrary: Bool
}

private struct IfConditionsTranslation {
	let conditions: ArrayClass<IfStatementData.IfCondition>
	let statements: ArrayClass<Statement>
}

private struct EnumPatternTranslation {
	let enumType: String
	let enumCase: String
	let declarations: ArrayClass<AssociatedValueDeclaration>
	let comparisons: ArrayClass<AssociatedValueComparison>
}

private struct AssociatedValueDeclaration {
	let associatedValueName: String
	let associatedValueType: String
	let newVariable: String
}

private struct AssociatedValueComparison {
	let associatedValueName: String
	let associatedValueType: String
	let comparedExpression: Expression
}

struct SwiftTranslatorError: Error, CustomStringConvertible {
	let errorMessage: String
	let ast: SwiftAST
	let translator: SwiftTranslator

	// TODO: descriptions' override annotations should be automatic
	var description: String { // annotation: override
		var nodeDescription = ""
		ast.prettyPrint {
			nodeDescription += $0
		}
		let details = "When translating the following AST node:\n\(nodeDescription)"

		return Compiler.createErrorOrWarningMessage(
			message: errorMessage,
			details: details,
			sourceFile: translator.sourceFile,
			sourceFileRange: translator.getRangeRecursively(ofNode: ast))
	}
}
