//
// Copyright 2018 Vinicius Jorge Vendramini
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

// gryphon output: Sources/GryphonLib/SwiftTranslator.swiftAST
// gryphon output: Sources/GryphonLib/SwiftTranslator.gryphonASTRaw
// gryphon output: Sources/GryphonLib/SwiftTranslator.gryphonAST
// gryphon output: Bootstrap/SwiftTranslator.kt

import Foundation

public class SwiftTranslator {
	// MARK: - Properties

	var outputFileMap: MutableMap<FileExtension, String> = [:]

	var danglingPatternBindings: MutableList<PatternBindingDeclaration?> = []

	let errorDanglingPatternDeclaration = PatternBindingDeclaration(
		identifier: "<<Error>>",
		typeName: "<<Error>>",
		expression: ErrorExpression(range: nil))

	internal var context: TranspilationContext
	internal var sourceFile: SourceFile?

	static let functionCompatibleASTNodes: List<String> =
		["Function Declaration", "Constructor Declaration", "Accessor Declaration"]

	// MARK: - Interface

	public init(context: TranspilationContext) {
		self.context = context
	}

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
				statements: declarationsAndStatements.statements,
				outputFileMap: outputFileMap)
		}
		else {
			return GryphonAST(
				sourceFile: sourceFile,
				declarations: translatedSubtrees,
				statements: [],
				outputFileMap: outputFileMap)
		}
	}

	struct DeclarationsAndStatements {
		let declarations: MutableList<Statement>
		let statements: MutableList<Statement>
	}

	func filterStatements(_ allStatements: MutableList<Statement>) -> DeclarationsAndStatements {
		let declarations: MutableList<Statement> = []
		let statements: MutableList<Statement> = []

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
				if let literalCodeExpression =
						expressionStatement.expression as? LiteralCodeExpression,
					!literalCodeExpression.shouldGoToMainFunction
				{
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
		_ subtrees: List<SwiftAST>,
		scope: SwiftAST)
		throws -> MutableList<Statement>
	{
		let scopeRange = getRange(ofNode: scope)
		return try translateSubtrees(
			subtrees, scopeRange: scopeRange)
	}

	internal func translateSubtrees(
		_ subtrees: List<SwiftAST>,
		scopeRange: SourceFileRange?)
		throws -> MutableList<Statement>
	{
		let result: MutableList<Statement> = []

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
			return try subtrees.flatMap{ try translateSubtree($0) }
				.compactMap { $0 }
				.toMutableList()
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
		throws -> MutableList<Statement>
	{
		return try translateSubtreesInScope(ast.subtrees, scope: ast)
	}

	internal func translateBraceStatement(
		_ braceStatement: SwiftAST)
		throws -> MutableList<Statement>
	{
		guard braceStatement.name == "Brace Statement" else {
			return try [unexpectedASTStructureError(
				"Trying to translate \(braceStatement.name) as a brace statement",
				ast: braceStatement), ]
		}

		return try translateSubtreesInScope(braceStatement.subtrees, scope: braceStatement)
	}

	internal func translateSingleStatementFunction(
		_ ast: SwiftAST)
		throws -> MutableList<Statement>
	{
		guard hasSingleStatement(ast) else {
			return try [unexpectedASTStructureError(
				"Trying to translate \(ast.name) as a single-statement function",
				ast: ast), ]
		}

		return try translateSubtreesInScope([ast.subtrees.last!], scope: ast)
	}

	private func hasSingleStatement(_ ast: SwiftAST) -> Bool {
		if let singleStatement = ast.subtrees.last,
			!singleStatement.name.contains("Parameter")
		{
			return true
		}
		else {
			return false
		}
	}

	internal func translateSubtree(_ subtree: SwiftAST) throws -> MutableList<Statement?> {

		if nodeHasTranslationComment(subtree, withKey: .ignore) {
			return []
		}

		let result: MutableList<Statement?>
		switch subtree.name {
		case "Top Level Code Declaration":
			result = try translateTopLevelCode(subtree)
		case "Import Declaration":
			result = [ImportDeclaration(
				range: getRangeRecursively(ofNode: subtree),
				moduleName: subtree.standaloneAttributes[0]), ]
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
				.toMutableList()
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
			result = [BreakStatement(range: getRangeRecursively(ofNode: subtree))]
		case "Continue Statement":
			result = [ContinueStatement(range: getRangeRecursively(ofNode: subtree))]
		case "Fail Statement":
			let range = getRangeRecursively(ofNode: subtree)
			result = [ReturnStatement(
				range: range,
				expression: NilLiteralExpression(range: range)), ]
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
				result = [ExpressionStatement(
					range: getRangeRecursively(ofNode: subtree),
					expression: expression), ]
			}

		default:
			if subtree.name.hasSuffix("Expression") {
				let expression = try translateExpression(subtree)
				result = [ExpressionStatement(
					range: getRangeRecursively(ofNode: subtree),
					expression: expression), ]
			}
			else {
				result = []
			}
		}

		let shouldInspect = nodeHasTranslationComment(subtree, withKey: .inspect)
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
				ast: protocolDeclaration)
		}

		guard let protocolName = protocolDeclaration.standaloneAttributes.first else {
			return try unexpectedASTStructureError(
				"Unrecognized structure",
				ast: protocolDeclaration)
		}

		let access = protocolDeclaration["access"]
		let annotations = getTranslationCommentValue(forNode: protocolDeclaration, key: .annotation)

		let members = try translateSubtreesOf(protocolDeclaration)

		return ProtocolDeclaration(
			range: getRangeRecursively(ofNode: protocolDeclaration),
			protocolName: protocolName,
			access: access,
			annotations: annotations,
			members: members)
	}

	internal func translateAssignExpression(_ assignExpression: SwiftAST) throws -> Statement {
		guard assignExpression.name == "Assign Expression" else {
			return try unexpectedASTStructureError(
				"Trying to translate \(assignExpression.name) as 'Assign Expression'",
				ast: assignExpression)
		}

		if let leftExpression = assignExpression.subtree(at: 0),
			let rightExpression = assignExpression.subtree(at: 1)
		{
			if leftExpression.name == "Discard Assignment Expression" {
				return try ExpressionStatement(
					range: getRangeRecursively(ofNode: rightExpression),
					expression: translateExpression(rightExpression))
			}
			else {
				let leftTranslation = try translateExpression(leftExpression)
				let rightTranslation = try translateExpression(rightExpression)

				return AssignmentStatement(
					range: getRangeRecursively(ofNode: assignExpression),
					leftHand: leftTranslation,
					rightHand: rightTranslation)
			}
		}
		else {
			return try unexpectedASTStructureError(
				"Unrecognized structure",
				ast: assignExpression)
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

		let access = typealiasDeclaration["access"]

		return TypealiasDeclaration(
			range: getRangeRecursively(ofNode: typealiasDeclaration),
			identifier: identifier,
			typeName: typealiasDeclaration["type"]!,
			access: access,
			isImplicit: isImplicit)
	}

	internal func translateClassDeclaration(_ classDeclaration: SwiftAST) throws -> Statement? {
		guard classDeclaration.name == "Class Declaration" else {
			return try unexpectedASTStructureError(
				"Trying to translate \(classDeclaration.name) as 'Class Declaration'",
				ast: classDeclaration)
		}

		if nodeHasTranslationComment(classDeclaration, withKey: .ignore) {
			return nil
		}

		// Get the class name and access modifier
		let name = classDeclaration.standaloneAttributes.first!
		let annotations = getTranslationCommentValue(forNode: classDeclaration, key: .annotation)?
			.split(withStringSeparator: " ") ?? []
		let access = classDeclaration["access"]

		let isOpen: Bool
		if classDeclaration.standaloneAttributes.contains("final") {
			isOpen = false
		}
		else if let access = access, access == "open" {
			isOpen = true
		}
		else {
			isOpen = !context.defaultFinal
		}

		// Check for inheritance
		let inheritanceArray: MutableList<String>
		if let inheritanceList = classDeclaration["inherits"] {
			inheritanceArray = inheritanceList.split(withStringSeparator: ", ")
		}
		else {
			inheritanceArray = []
		}

		// Translate the contents
		let classContents = try translateSubtreesOf(classDeclaration)

		return ClassDeclaration(
			range: getRangeRecursively(ofNode: classDeclaration),
			className: name,
			annotations: annotations,
			access: access,
			isOpen: isOpen,
			inherits: inheritanceArray,
			members: classContents)
	}

	internal func translateStructDeclaration(_ structDeclaration: SwiftAST) throws -> Statement? {
		guard structDeclaration.name == "Struct Declaration" else {
			return try unexpectedASTStructureError(
				"Trying to translate \(structDeclaration.name) as 'Struct Declaration'",
				ast: structDeclaration)
		}

		if nodeHasTranslationComment(structDeclaration, withKey: .ignore) {
			return nil
		}

		let annotations = getTranslationCommentValue(forNode: structDeclaration, key: .annotation)

		let access = structDeclaration["access"]

		// Get the struct name
		let name = structDeclaration.standaloneAttributes.first!

		// Check for inheritance
		let inheritanceArray: MutableList<String>
		if let inheritanceList = structDeclaration["inherits"] {
			inheritanceArray = inheritanceList.split(withStringSeparator: ", ")
		}
		else {
			inheritanceArray = []
		}

		// Translate the contents
		let structContents = try translateSubtreesOf(structDeclaration)

		return StructDeclaration(
			range: getRangeRecursively(ofNode: structDeclaration),
			annotations: annotations,
			structName: name,
			access: access,
			inherits: inheritanceArray,
			members: structContents)
	}

	internal func translateThrowStatement(_ throwStatement: SwiftAST) throws -> Statement {
		guard throwStatement.name == "Throw Statement" else {
			return try unexpectedASTStructureError(
				"Trying to translate \(throwStatement.name) as 'Throw Statement'",
				ast: throwStatement)
		}

		if let expression = throwStatement.subtrees.last {
			let expressionTranslation = try translateExpression(expression)
			return ThrowStatement(
				range: getRangeRecursively(ofNode: throwStatement),
				expression: expressionTranslation)
		}
		else {
			return try unexpectedASTStructureError(
				"Unrecognized structure",
				ast: throwStatement)
		}
	}

	internal func translateExtensionDeclaration(
		_ extensionDeclaration: SwiftAST)
		throws -> Statement
	{
		let typeName = cleanUpType(extensionDeclaration.standaloneAttributes[0])

		let members = try translateSubtreesOf(extensionDeclaration)

		return ExtensionDeclaration(
			range: getRangeRecursively(ofNode: extensionDeclaration),
			typeName: typeName,
			members: members)
	}

	internal func translateEnumDeclaration(_ enumDeclaration: SwiftAST) throws -> Statement? {
		guard enumDeclaration.name == "Enum Declaration" else {
			return try unexpectedASTStructureError(
				"Trying to translate \(enumDeclaration.name) as 'Enum Declaration'",
				ast: enumDeclaration)
		}

		if nodeHasTranslationComment(enumDeclaration, withKey: .ignore) {
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

		let inheritanceArray: MutableList<String>
		if let inheritanceList = enumDeclaration["inherits"] {
			inheritanceArray = inheritanceList.split(withStringSeparator: ", ")
		}
		else {
			inheritanceArray = []
		}

		var rawValues: MutableList<Expression> = []
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
				let rawValueASTs = MutableList<SwiftAST>(arrayExpression.subtrees.dropLast())
				rawValues = try rawValueASTs.map { try translateExpression($0) }.toMutableList()
				break
			}
		}

		let elements: MutableList<EnumElement> = []
		let enumElementDeclarations =
			enumDeclaration.subtrees.filter { $0.name == "Enum Element Declaration" }
		for index in enumElementDeclarations.indices {
			let enumElementDeclaration = enumElementDeclarations[index]

			guard !nodeHasTranslationComment(enumElementDeclaration, withKey: .ignore) else {
				continue
			}

			guard let elementName = enumElementDeclaration.standaloneAttributes.first else {
				return try unexpectedASTStructureError(
					"Expected the element name to be the first standalone attribute in an Enum" +
					"Declaration",
					ast: enumDeclaration)
			}

			let annotations = getTranslationCommentValue(
				forNode: enumElementDeclaration,
				key: .annotation)

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
				let valueLabels = MutableList<String>(
					valuesString.split(separator: ":")
						.map { String($0) })

				guard let enumType = enumElementDeclaration["interface type"] else {
					return try unexpectedASTStructureError(
						"Expected an enum element with associated values to have an interface type",
						ast: enumDeclaration)
				}
				let enumTypeComponents = enumType.split(withStringSeparator: " -> ")
				let valuesComponent = enumTypeComponents[1]
				let valueTypesString = String(valuesComponent.dropFirst().dropLast())
				let valueTypes = Utilities.splitTypeList(valueTypesString)

				let associatedValues = zip(valueLabels, valueTypes)
					.map { LabeledType(label: $0.0, typeName: $0.1) }
					.toMutableList()

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

		let annotations = getTranslationCommentValue(forNode: enumDeclaration, key: .annotation)

		let translatedMembers = try translateSubtreesInScope(
			members.toMutableList(),
			scope: enumDeclaration)

		return EnumDeclaration(
			range: getRangeRecursively(ofNode: enumDeclaration),
			access: access,
			enumName: name,
			annotations: annotations,
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
				ast: memberReferenceExpression)
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
			let rightHand = DeclarationReferenceExpression(
				range: range,
				identifier: declarationInformation.identifier,
				typeName: typeName,
				isStandardLibrary: declarationInformation.isStandardLibrary,
				isImplicit: isImplicit)
			return DotExpression(
				range: getRangeRecursively(ofNode: memberOwner),
				leftExpression: leftHand,
				rightExpression: rightHand)
		}
		else {
			return try unexpectedExpressionStructureError(
				"Unrecognized structure",
				ast: memberReferenceExpression)
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
				ast: tupleElementExpression)
		}

		let numberString = tupleElementExpression.standaloneAttributes
			.first(where: { $0.hasPrefix("#") })?
			.dropFirst()
		let number = numberString.map { Int($0) } ?? nil
		let leftHandExpression = tupleElementExpression.subtrees.first
		let tuple = leftHandExpression?["type"]

		if let number = number,
			let leftHandExpression = leftHandExpression,
			let tuple = tuple
		{
			let translatedLeftExpression = try translateExpression(leftHandExpression)
			let tupleComponents =
				String(tuple.dropFirst().dropLast()).split(withStringSeparator: ", ")
			let tupleComponent = tupleComponents[safe: number]

			let labelAndType = tupleComponent?.split(withStringSeparator: ": ")
			let label = labelAndType?[safe: 0]
			let typeName = labelAndType?[safe: 1]

			if let label = label, let typeName = typeName {
				let range = getRangeRecursively(ofNode: leftHandExpression)
				return DotExpression(
					range: range,
					leftExpression: translatedLeftExpression,
					rightExpression: DeclarationReferenceExpression(
						range: range,
						identifier: label,
						typeName: typeName,
						isStandardLibrary: false,
						isImplicit: false))
			}
			else if let tupleComponent = tupleComponent {
				let memberName = (number == 0) ? "first" : "second"
				let range = getRangeRecursively(ofNode: tupleElementExpression)
				return DotExpression(
					range: range,
					leftExpression: translatedLeftExpression,
					rightExpression: DeclarationReferenceExpression(
						range: range,
						identifier: memberName,
						typeName: tupleComponent,
						isStandardLibrary: false,
						isImplicit: false))
			}
		}

		return try unexpectedExpressionStructureError(
			"Unable to get either the tuple element's number or its label.",
			ast: tupleElementExpression)
	}

	internal func translatePrefixUnaryExpression(
		_ prefixExpression: SwiftAST)
		throws -> Expression
	{
		guard prefixExpression.name == "Prefix Unary Expression" else {
			return try unexpectedExpressionStructureError(
				"Trying to translate \(prefixExpression.name) as 'Prefix Unary Expression'",
				ast: prefixExpression)
		}

		if let rawType = prefixExpression["type"],
			let declaration = prefixExpression
				.subtree(named: "Dot Syntax Call Expression")?
				.subtree(named: "Declaration Reference Expression")?["decl"],
			let expression = prefixExpression.subtree(at: 1)
		{
			let typeName = cleanUpType(rawType)
			let expressionTranslation = try translateExpression(expression)
			let operatorInformation = getInformationFromDeclaration(declaration)

			return PrefixUnaryExpression(
				range: getRangeRecursively(ofNode: prefixExpression),
				subExpression: expressionTranslation,
				operatorSymbol: operatorInformation.identifier,
				typeName: typeName)
		}
		else {
			return try unexpectedExpressionStructureError(
				"Expected Prefix Unary Expression to have a Dot Syntax Call Expression with a " +
					"Declaration Reference Expression, for the operator, and expected it to have " +
				"a second expression as the operand.",
				ast: prefixExpression)
		}
	}

	internal func translatePostfixUnaryExpression(
		_ postfixExpression: SwiftAST)
		throws -> Expression
	{
		guard postfixExpression.name == "Postfix Unary Expression" else {
			return try unexpectedExpressionStructureError(
				"Trying to translate \(postfixExpression.name) as 'Postfix Unary Expression'",
				ast: postfixExpression)
		}

		if let rawType = postfixExpression["type"],
			let declaration = postfixExpression
				.subtree(named: "Dot Syntax Call Expression")?
				.subtree(named: "Declaration Reference Expression")?["decl"],
			let expression = postfixExpression.subtree(at: 1)
		{
			let typeName = cleanUpType(rawType)
			let expressionTranslation = try translateExpression(expression)
			let operatorInformation = getInformationFromDeclaration(declaration)

			return PostfixUnaryExpression(
				range: getRangeRecursively(ofNode: postfixExpression),
				subExpression: expressionTranslation,
				operatorSymbol: operatorInformation.identifier,
				typeName: typeName)
		}
		else {
			return try unexpectedExpressionStructureError(
				"Expected Postfix Unary Expression to have a Dot Syntax Call Expression with a " +
					"Declaration Reference Expression, for the operator, and expected it to have " +
				"a second expression as the operand.",
				ast: postfixExpression)
		}
	}

	internal func translateBinaryExpression(_ binaryExpression: SwiftAST) throws -> Expression {
		guard binaryExpression.name == "Binary Expression" else {
			return try unexpectedExpressionStructureError(
				"Trying to translate \(binaryExpression.name) as 'Binary Expression'",
				ast: binaryExpression)
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
				range: getRangeRecursively(ofNode: binaryExpression),
				leftExpression: leftHandTranslation,
				rightExpression: rightHandTranslation,
				operatorSymbol: operatorInformation.identifier,
				typeName: typeName)
		}
		else {
			return try unexpectedExpressionStructureError(
				"Unrecognized structure",
				ast: binaryExpression)
		}
	}

	internal func translateIfExpression(_ ifExpression: SwiftAST) throws -> Expression {
		guard ifExpression.name == "If Expression" else {
			return try unexpectedExpressionStructureError(
				"Trying to translate \(ifExpression.name) as 'If Expression'",
				ast: ifExpression)
		}

		guard ifExpression.subtrees.count == 3 else {
			return try unexpectedExpressionStructureError(
				"Expected If Expression to have three subtrees (a condition, a true expression " +
				"and a false expression)",
				ast: ifExpression)
		}

		let condition = try translateExpression(ifExpression.subtrees[0])
		let trueExpression = try translateExpression(ifExpression.subtrees[1])
		let falseExpression = try translateExpression(ifExpression.subtrees[2])

		return IfExpression(
			range: getRangeRecursively(ofNode: ifExpression),
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
				ast: dotSyntaxCallExpression)
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
				if rightExpression.identifier == "none" {
					return NilLiteralExpression(
						range: getRangeRecursively(ofNode: dotSyntaxCallExpression))
				}
			}

			return DotExpression(
				range: getRangeRecursively(ofNode: dotSyntaxCallExpression),
				leftExpression: leftHand,
				rightExpression: rightHand)
		}
		else {
			return try unexpectedExpressionStructureError(
				"Unrecognized structure",
				ast: dotSyntaxCallExpression)
		}
	}

	internal func translateReturnStatement(_ returnStatement: SwiftAST) throws -> Statement {
		guard returnStatement.name == "Return Statement" else {
			return try unexpectedASTStructureError(
				"Trying to translate \(returnStatement.name) as 'Return Statement'",
				ast: returnStatement)
		}

		if let expression = returnStatement.subtrees.last {
			let translatedExpression = try translateExpression(expression)
			return ReturnStatement(
				range: getRangeRecursively(ofNode: returnStatement),
				expression: translatedExpression)
		}
		else {
			return ReturnStatement(
				range: getRangeRecursively(ofNode: returnStatement),
				expression: nil)
		}
	}

	internal func translateDoCatchStatement(
		_ doCatchStatement: SwiftAST)
		throws -> MutableList<Statement?>
	{
		guard doCatchStatement.name == "Do Catch Statement" else {
			return try [unexpectedASTStructureError(
				"Trying to translate \(doCatchStatement.name) as 'Do Catch Statement'",
				ast: doCatchStatement), ]
		}

		guard let braceStatement = doCatchStatement.subtrees.first,
			braceStatement.name == "Brace Statement" else
		{
			return try [unexpectedASTStructureError(
				"Unable to find do statement's inner statements. Expected there to be a Brace " +
				"Statement as the first subtree.",
				ast: doCatchStatement), ]
		}

		let translatedInnerDoStatements = try translateBraceStatement(braceStatement)
		let translatedDoStatement = DoStatement(
			range: getRangeRecursively(ofNode: doCatchStatement),
			statements: translatedInnerDoStatements)

		let catchStatements: MutableList<Statement?> = []
		for catchStatement in doCatchStatement.subtrees.dropFirst() {
			guard catchStatement.name == "Catch" else {
				continue
			}

			let variableDeclaration: VariableDeclaration?

			let patternNamed = catchStatement
				.subtree(named: "Pattern Let")?
				.subtree(named: "Pattern Named")
			let patternAttributes = patternNamed?.standaloneAttributes
			let variableName = patternAttributes?.first
			let variableType = patternNamed?["type"]

			if let patternNamed = patternNamed,
				let variableName = variableName,
				let variableType = variableType
			{
				variableDeclaration = VariableDeclaration(
					range: getRangeRecursively(ofNode: patternNamed),
					identifier: variableName,
					typeName: variableType,
					expression: nil,
					getter: nil,
					setter: nil,
					access: nil,
					isOpen: false,
					isLet: true,
					isImplicit: false,
					isStatic: false,
					extendsType: nil,
					annotations: [])
			}
			else {
				variableDeclaration = nil
			}

			guard let braceStatement = catchStatement.subtree(named: "Brace Statement") else {
				return try [unexpectedASTStructureError(
					"Unable to find catch statement's inner statements. Expected there to be a " +
					"Brace Statement.",
					ast: doCatchStatement), ]
			}

			let translatedStatements = try translateBraceStatement(braceStatement)

			catchStatements.append(CatchStatement(
				range: getRangeRecursively(ofNode: doCatchStatement),
				variableDeclaration: variableDeclaration,
				statements: translatedStatements))
		}

		let resultingStatements: MutableList<Statement?> = [translatedDoStatement]
		resultingStatements.append(contentsOf: catchStatements)

		return resultingStatements
	}

	internal func translateForEachStatement(_ forEachStatement: SwiftAST) throws -> Statement {
		guard forEachStatement.name == "For Each Statement" else {
			return try unexpectedASTStructureError(
				"Trying to translate \(forEachStatement.name) as 'For Each Statement'",
				ast: forEachStatement)
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
			variable = DeclarationReferenceExpression(
				range: variableRange,
				identifier: variableName,
				typeName: cleanUpType(rawTypeNamed),
				isStandardLibrary: false,
				isImplicit: false)
			collectionExpression = maybeCollectionExpression
		}
		else if let variableSubtreeTuple = variableSubtreeTuple,
			let maybeCollectionExpression = maybeCollectionExpression
		{
			let variables: MutableList<LabeledExpression> =
				variableSubtreeTuple.subtrees.map { subtree in
					let name = subtree.standaloneAttributes[0]
					let typeName = subtree.keyValueAttributes["type"]!
					return LabeledExpression(
						label: nil,
						expression: DeclarationReferenceExpression(
							range: variableRange,
							identifier: name,
							typeName: cleanUpType(typeName),
							isStandardLibrary: false,
							isImplicit: false))
				}.toMutableList()

			variable = TupleExpression(
				range: getRangeRecursively(ofNode: variableSubtreeTuple),
				pairs: variables)
			collectionExpression = maybeCollectionExpression
		}
		else if let rawTypeAny = rawTypeAny,
			let maybeCollectionExpression = maybeCollectionExpression
		{
			let typeName = cleanUpType(rawTypeAny)
			variable = DeclarationReferenceExpression(
				range: variableRange,
				identifier: "_0",
				typeName: typeName,
				isStandardLibrary: false,
				isImplicit: false)
			collectionExpression = maybeCollectionExpression
		}
		else {
			return try unexpectedASTStructureError(
				"Unable to detect variable or collection",
				ast: forEachStatement)
		}

		guard let braceStatement = forEachStatement.subtrees.last,
			braceStatement.name == "Brace Statement" else
		{
			return try unexpectedASTStructureError(
				"Unable to detect body of statements",
				ast: forEachStatement)
		}

		let collectionTranslation = try translateExpression(collectionExpression)
		let statements = try translateBraceStatement(braceStatement)

		return ForEachStatement(
			range: getRangeRecursively(ofNode: forEachStatement),
			collection: collectionTranslation,
			variable: variable,
			statements: statements)
	}

	internal func translateWhileStatement(_ whileStatement: SwiftAST) throws -> Statement {
		guard whileStatement.name == "While Statement" else {
			return try unexpectedASTStructureError(
				"Trying to translate \(whileStatement.name) as 'While Statement'",
				ast: whileStatement)
		}

		guard let expressionSubtree = whileStatement.subtrees.first else {
			return try unexpectedASTStructureError(
				"Unable to detect expression",
				ast: whileStatement)
		}

		guard let braceStatement = whileStatement.subtrees.last,
			braceStatement.name == "Brace Statement" else
		{
			return try unexpectedASTStructureError(
				"Unable to detect body of statements",
				ast: whileStatement)
		}

		let expression = try translateExpression(expressionSubtree)
		let statements = try translateBraceStatement(braceStatement)

		return WhileStatement(
			range: getRangeRecursively(ofNode: whileStatement),
			expression: expression,
			statements: statements)
	}

	internal func translateDeferStatement(_ deferStatement: SwiftAST) throws -> Statement {
		guard deferStatement.name == "Defer Statement" else {
			return try unexpectedASTStructureError(
				"Trying to translate \(deferStatement.name) as a 'Defer Statement'",
				ast: deferStatement)
		}

		guard let braceStatement = deferStatement
			.subtree(named: "Function Declaration")?
			.subtree(named: "Brace Statement") else
		{
			return try unexpectedASTStructureError(
				"Expected defer statement to have a function declaration with a brace statement " +
				"containing the deferred statements.",
				ast: deferStatement)
		}

		let statements = try translateBraceStatement(braceStatement)
		return DeferStatement(
			range: getRangeRecursively(ofNode: deferStatement),
			statements: statements)
	}

	internal func translateIfStatement(_ ifStatement: SwiftAST) throws -> IfStatement? {
		guard ifStatement.name == "If Statement" || ifStatement.name == "Guard Statement" else {
			return try unexpectedIfStructureError(
				"Trying to translate \(ifStatement.name) as an if or guard statement",
				ast: ifStatement)
		}

		let isGuard = (ifStatement.name == "Guard Statement")

		let ifConditions = try translateIfConditions(forIfStatement: ifStatement)
		let conditions = ifConditions.conditions
		let extraStatements = ifConditions.statements

		let braceStatement: SwiftAST
		let elseStatement: IfStatement?

		let secondToLastTree = ifStatement.subtrees.secondToLast
		let lastTree = ifStatement.subtrees.last

		if ifStatement.subtrees.count > 2,
			let secondToLastTree = secondToLastTree,
			secondToLastTree.name == "Brace Statement",
			let lastTree = lastTree,
			lastTree.name == "If Statement"
		{
			braceStatement = secondToLastTree
			elseStatement = try translateIfStatement(lastTree)
		}
		else if ifStatement.subtrees.count > 2,
			let secondToLastTree = secondToLastTree,
			secondToLastTree.name == "Brace Statement",
			let lastTree = lastTree,
			lastTree.name == "Brace Statement"
		{
			braceStatement = secondToLastTree
			let statements = try translateBraceStatement(lastTree)
			elseStatement = IfStatement(
				range: getRangeRecursively(ofNode: ifStatement),
				conditions: [],
				declarations: [],
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
			return try unexpectedIfStructureError(
				"Unable to detect body of statements",
				ast: ifStatement)
		}

		let statements = try translateBraceStatement(braceStatement)

		let resultingStatements = extraStatements
		resultingStatements.append(contentsOf: statements)

		return IfStatement(
			range: getRangeRecursively(ofNode: ifStatement),
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
				ast: switchStatement)
		}

		guard let expression = switchStatement.subtrees.first else {
			return try unexpectedASTStructureError(
				"Unable to detect primary expression for switch statement",
				ast: switchStatement)
		}

		let translatedExpression = try translateExpression(expression)

		let cases: MutableList<SwitchCase> = []
		let caseSubtrees = MutableList<SwiftAST>(switchStatement.subtrees.dropFirst())
		for caseSubtree in caseSubtrees {
			let caseExpressions: MutableList<Expression> = []
			var extraStatements: MutableList<Statement> = []

			for caseLabelItem in caseSubtree.subtrees.filter({ $0.name == "Case Label Item" }) {
				let firstSubtreeSubtrees = caseLabelItem.subtrees.first?.subtrees
				let maybeExpression = firstSubtreeSubtrees?.first

				let patternLet = caseLabelItem.subtree(named: "Pattern Let")
				let patternLetResult = try translateEnumPattern(patternLet)

				if let patternLetResult = patternLetResult, let patternLet = patternLet {
					guard patternLetResult.comparisons.isEmpty else {
						return try unexpectedASTStructureError(
							"Comparison expressions are not supported in switch cases",
							ast: caseLabelItem)
					}

					let enumType = patternLetResult.enumType
					let enumCase = patternLetResult.enumCase
					let declarations = patternLetResult.declarations
					let enumClassName = enumType + "." + enumCase.capitalizedAsCamelCase()

					caseExpressions.append(BinaryOperatorExpression(
						range: getRangeRecursively(ofNode: patternLet),
						leftExpression: translatedExpression,
						rightExpression: TypeExpression(
							range: getRangeRecursively(ofNode: patternLet),
							typeName: enumClassName),
						operatorSymbol: "is",
						typeName: "Bool"))

					let range = getRangeRecursively(ofNode: patternLet)

					extraStatements = declarations.map {
						VariableDeclaration(
							range: getRangeRecursively(ofNode: patternLet),
							identifier: $0.newVariable,
							typeName: $0.associatedValueType,
							expression: DotExpression(
								range: getRangeRecursively(ofNode: patternLet),
								leftExpression: translatedExpression,
								rightExpression: DeclarationReferenceExpression(
									range: range,
									identifier: $0.associatedValueName,
									typeName: $0.associatedValueType,
									isStandardLibrary: false,
									isImplicit: false)),
							getter: nil,
							setter: nil,
							access: nil,
							isOpen: false,
							isLet: true,
							isImplicit: false,
							isStatic: false,
							extendsType: nil,
							annotations: [])
					}.toMutableList()
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
					ast: switchStatement)
			}

			let translatedStatements = try translateBraceStatement(braceStatement)

			let resultingStatements = extraStatements
			resultingStatements.append(contentsOf: translatedStatements)

			cases.append(SwitchCase(
				expressions: caseExpressions, statements: resultingStatements))
		}

		return SwitchStatement(
			range: getRangeRecursively(ofNode: switchStatement),
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
				ast: simplePatternEnumElement)
		}

		guard let enumReference = simplePatternEnumElement.standaloneAttributes.first,
			let typeName = simplePatternEnumElement["type"] else
		{
			return try unexpectedExpressionStructureError(
				"Expected a Pattern Enum Element to have a reference to the enum case and a type.",
				ast: simplePatternEnumElement)
		}

		let enumElements = MutableList<Substring>(enumReference.split(separator: "."))

		guard let lastEnumElement = enumElements.last else {
			return try unexpectedExpressionStructureError(
				"Expected a Pattern Enum Element to have a period (i.e. `MyEnum.myEnumCase`)",
				ast: simplePatternEnumElement)
		}

		let range = getRangeRecursively(ofNode: simplePatternEnumElement)
		let lastExpression = DeclarationReferenceExpression(
			range: range,
			identifier: String(lastEnumElement),
			typeName: typeName,
			isStandardLibrary: false,
			isImplicit: false)

		enumElements.removeLast()
		if !enumElements.isEmpty {
			return DotExpression(
				range: getRangeRecursively(ofNode: simplePatternEnumElement),
				leftExpression: TypeExpression(
					range: getRangeRecursively(ofNode: simplePatternEnumElement),
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
					ast: ifStatement), ])
		}

		let conditionsResult: MutableList<IfStatement.IfCondition> = []
		let statementsResult: MutableList<Statement> = []

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
							ast: ifStatement), ])
				}

				guard let rawType = optionalSomeElement["type"] else {
					return try IfConditionsTranslation(
						conditions: [],
						statements: [unexpectedASTStructureError(
							"Unable to detect type in let declaration",
							ast: ifStatement), ])
				}

				let typeName = cleanUpType(rawType)

				guard let name = patternNamed.standaloneAttributes.first,
					let lastCondition = condition.subtrees.last else
				{
					return try IfConditionsTranslation(
						conditions: [],
						statements: [unexpectedASTStructureError(
							"Unable to get expression in let declaration",
							ast: ifStatement), ])
				}

				let expression = try translateExpression(lastCondition)

				conditionsResult.append(.declaration(variableDeclaration: VariableDeclaration(
					range: getRangeRecursively(ofNode: lastCondition),
					identifier: name,
					typeName: typeName,
					expression: expression,
					getter: nil,
					setter: nil,
					access: nil,
					isOpen: false,
					isLet: isLet,
					isImplicit: false,
					isStatic: false,
					extendsType: nil,
					annotations: [])))
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
							ast: ifStatement), ])
				}

				let enumType = patternLetResult.enumType
				let enumCase = patternLetResult.enumCase
				let declarations = patternLetResult.declarations
				let comparisons = patternLetResult.comparisons
				let enumClassName = enumType + "." + enumCase.capitalizedAsCamelCase()

				let declarationReference = try translateExpression(declarationReferenceAST)

				conditionsResult.append(.condition(expression: BinaryOperatorExpression(
					range: getRangeRecursively(ofNode: declarationReferenceAST),
					leftExpression: declarationReference,
					rightExpression: TypeExpression(
						range: getRangeRecursively(ofNode: declarationReferenceAST),
						typeName: enumClassName),
					operatorSymbol: "is",
					typeName: "Bool")))

				// TODO: test
				for comparison in comparisons {
					let range = comparison.comparedExpression.range
					conditionsResult.append(.condition(expression: BinaryOperatorExpression(
						range: range,
						leftExpression: DotExpression(
							range: range,
							leftExpression: declarationReference,
							rightExpression: DeclarationReferenceExpression(
								range: range,
								identifier: comparison.associatedValueName,
								typeName: comparison.associatedValueType,
								isStandardLibrary: false,
								isImplicit: false)),
						rightExpression: comparison.comparedExpression,
						operatorSymbol: "==",
						typeName: "Bool")))
				}

				for declaration in declarations {
					let range = getRangeRecursively(ofNode: patternLet)

					statementsResult.append(VariableDeclaration(
						range: range,
						identifier: declaration.newVariable,
						typeName: declaration.associatedValueType,
						expression: DotExpression(
							range: range,
							leftExpression: declarationReference,
							rightExpression: DeclarationReferenceExpression(
								range: range,
								identifier: String(declaration.associatedValueName),
								typeName: declaration.associatedValueType,
								isStandardLibrary: false,
								isImplicit: false)),
						getter: nil,
						setter: nil,
						access: nil,
						isOpen: false,
						isLet: true,
						isImplicit: false,
						isStatic: false,
						extendsType: nil,
						annotations: []))
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
					range: getRangeRecursively(ofNode: condition),
					leftExpression: translatedExpression,
					rightExpression: TypeExpression(
						range: getRangeRecursively(ofNode: condition),
						typeName: enumTypeComponents),
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

		let associatedValuesInfo = zip(associatedValueNames, patternTuple.subtrees)

		let declarations: MutableList<AssociatedValueDeclaration> = []
		let comparisons: MutableList<AssociatedValueComparison> = []
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
				ast: functionDeclaration)
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
					ast: functionDeclaration)
			}
		}
		else {
			functionName = functionDeclaration.standaloneAttributes.first ?? ""
		}

		let access = functionDeclaration["access"]

		// Find out if it's static and if it's mutating
		let maybeInterfaceType = functionDeclaration["interface type"] ??
			functionDeclaration["type"]
		let maybeInterfaceTypeComponents = maybeInterfaceType?.split(withStringSeparator: " -> ")
		let maybeFirstInterfaceTypeComponent = maybeInterfaceTypeComponents?.first

		guard let interfaceType = maybeInterfaceType,
			let interfaceTypeComponents = maybeInterfaceTypeComponents,
			let firstInterfaceTypeComponent = maybeFirstInterfaceTypeComponent else
		{
			return try unexpectedASTStructureError(
				"Unable to find out if function is static",
				ast: functionDeclaration)
		}
		let isStatic = firstInterfaceTypeComponent.contains(".Type")
		let isMutating = firstInterfaceTypeComponent.contains("inout")

		let genericTypes: MutableList<String>
		if let firstGenericString = functionDeclaration.standaloneAttributes
			.first(where: { $0.hasPrefix("<") })
		{
			genericTypes = MutableList<String>(
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
				"(" // gryphon value: '('
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
		let parameters: MutableList<FunctionParameter> = []
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
						ast: functionDeclaration)
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
				"Unable to get return type", ast: functionDeclaration)
		}

		// Translate the function body
		let statements: MutableList<Statement>
		if let braceStatement = functionDeclaration.subtree(named: "Brace Statement") {
			statements = try translateBraceStatement(braceStatement)
		}
		else if hasSingleStatement(functionDeclaration) {
			statements = try translateSingleStatementFunction(functionDeclaration)
		}
		else {
			statements = []
		}

		// TODO: test annotations in functions
		let annotations = getTranslationCommentValue(
			forNode: functionDeclaration,
			key: .annotation)?
			.split(withStringSeparator: " ")
			?? []

		if isSubscript {
			annotations.append("operator")
		}

		let isPure = nodeHasTranslationComment(functionDeclaration, withKey: .pure)

		let isOpen: Bool
		if functionDeclaration.standaloneAttributes.contains("final") {
			isOpen = false
		}
		else if let access = access, access == "open" {
			isOpen = true
		}
		else {
			isOpen = !context.defaultFinal
		}

		let prefix = String(functionNamePrefix)
		if prefix == "init" {
			return InitializerDeclaration(
				range: getRangeRecursively(ofNode: functionDeclaration),
				parameters: parameters,
				returnType: returnType,
				functionType: interfaceType,
				genericTypes: genericTypes,
				isOpen: isOpen,
				isImplicit: isImplicit,
				isStatic: isStatic,
				isMutating: isMutating,
				isPure: isPure,
				extendsType: nil,
				statements: statements,
				access: access,
				annotations: annotations,
				superCall: nil)
		}
		else {
			return FunctionDeclaration(
				range: getRangeRecursively(ofNode: functionDeclaration),
				prefix: prefix,
				parameters: parameters,
				returnType: returnType,
				functionType: interfaceType,
				genericTypes: genericTypes,
				isOpen: isOpen,
				isImplicit: isImplicit,
				isStatic: isStatic,
				isMutating: isMutating,
				isPure: isPure,
				extendsType: nil,
				statements: statements,
				access: access,
				annotations: annotations)
		}
	}

	internal func translateTopLevelCode(_ topLevelCodeDeclaration: SwiftAST) throws
		-> MutableList<Statement?>
	{
		guard topLevelCodeDeclaration.name == "Top Level Code Declaration" else {
			return try [unexpectedASTStructureError(
				"Trying to translate \(topLevelCodeDeclaration.name) as " +
				"'Top Level Code Declaration'",
				ast: topLevelCodeDeclaration), ]
		}

		guard let braceStatement = topLevelCodeDeclaration.subtree(named: "Brace Statement") else {
			return try [unexpectedASTStructureError(
				"Unrecognized structure", ast: topLevelCodeDeclaration), ]
		}

		let subtrees = try translateBraceStatement(braceStatement)

		return MutableList<Statement?>(subtrees)
	}

	internal func translateVariableDeclaration(
		_ variableDeclaration: SwiftAST)
		throws -> Statement
	{
		guard variableDeclaration.name == "Variable Declaration" else {
			return try unexpectedASTStructureError(
				"Trying to translate \(variableDeclaration.name) as 'Variable Declaration'",
				ast: variableDeclaration)
		}

		let isImplicit = variableDeclaration.standaloneAttributes.contains("implicit")
		let access = variableDeclaration["access"]

		let annotations =
			getTranslationCommentValue(forNode: variableDeclaration, key: .annotation)?
			.split(withStringSeparator: " ") ?? []

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
				"Failed to get identifier and type", ast: variableDeclaration)
		}

		let isLet = variableDeclaration.standaloneAttributes.contains("let")
		let typeName = cleanUpType(rawType)

		let isOpen: Bool
		if variableDeclaration.standaloneAttributes.contains("final") {
			isOpen = false
		}
		else if let access = access, access == "open" {
			isOpen = true
		}
		else {
			isOpen = !context.defaultFinal
		}

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

		if let valueReplacement =
				getTranslationCommentValue(forNode: variableDeclaration, key: .value),
			expression == nil
		{
			expression = LiteralCodeExpression(
				range: getRangeRecursively(ofNode: variableDeclaration),
				string: valueReplacement,
				shouldGoToMainFunction: true)
		}

		var getter: FunctionDeclaration?
		var setter: FunctionDeclaration?
		for subtree in variableDeclaration.subtrees {
			let functionAccess = subtree["access"]

			let statements: MutableList<Statement>
			if let braceStatement = subtree.subtree(named: "Brace Statement") {
				statements = try translateBraceStatement(braceStatement)
			}
			else if hasSingleStatement(subtree) {
				statements = try translateSingleStatementFunction(subtree)
			}
			else {
				statements = []
			}

			let isImplicit = subtree.standaloneAttributes.contains("implicit")
			let isPure = nodeHasTranslationComment(subtree, withKey: .pure)
			let annotations = getTranslationCommentValue(forNode: subtree, key: .annotation)?
				.split(withStringSeparator: " ")
				?? []

			if subtree["get_for"] != nil {
				getter = FunctionDeclaration(
					range: getRangeRecursively(ofNode: subtree),
					prefix: "get",
					parameters: [],
					returnType: typeName,
					functionType: "() -> (\(typeName))",
					genericTypes: [],
					isOpen: false,
					isImplicit: isImplicit,
					isStatic: false,
					isMutating: false,
					isPure: isPure,
					extendsType: nil,
					statements: statements,
					access: functionAccess,
					annotations: annotations)
			}
			else if subtree["materializeForSet_for"] != nil || subtree["set_for"] != nil {
				setter = FunctionDeclaration(
					range: getRangeRecursively(ofNode: subtree),
					prefix: "set",
					parameters: [FunctionParameter(
						label: "newValue", apiLabel: nil, typeName: typeName, value: nil), ],
					returnType: "()",
					functionType: "(\(typeName)) -> ()",
					genericTypes: [],
					isOpen: false,
					isImplicit: isImplicit,
					isStatic: false,
					isMutating: false,
					isPure: isPure,
					extendsType: nil,
					statements: statements,
					access: functionAccess,
					annotations: annotations)
			}
		}

		return VariableDeclaration(
			range: getRangeRecursively(ofNode: variableDeclaration),
			identifier: identifier,
			typeName: typeName,
			expression: expression,
			getter: getter,
			setter: setter,
			access: access,
			isOpen: isOpen,
			isLet: isLet,
			isImplicit: isImplicit,
			isStatic: isStatic,
			extendsType: nil,
			annotations: annotations)
	}

	// MARK: - Expression translations

	internal func translateExpression(_ expression: SwiftAST) throws -> Expression {

		if let valueReplacement = getTranslationCommentValue(forNode: expression, key: .value) {
			return LiteralCodeExpression(
				range: getRangeRecursively(ofNode: expression),
				string: valueReplacement,
				shouldGoToMainFunction: true)
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
					ast: expression)
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
			result = NilLiteralExpression(range: getRangeRecursively(ofNode: expression))
		case "Open Existential Expression":
			let processedExpression = try processOpenExistentialExpression(expression)
			result = try translateExpression(processedExpression)
		// TODO: Remove new dead code from 5.1 AST adaptations
		case "Boolean Literal Expression":
			let value = (expression["value"]! == "true")
			result = LiteralBoolExpression(
				range: getRangeRecursively(ofNode: expression),
				value: value)
		case "Integer Literal Expression", "Float Literal Expression":
			result = try translateAsNumericLiteral(expression)
		case "Parentheses Expression":
			if let innerExpression = expression.subtree(at: 0) {
				// Swift 5: Compiler-created parentheses expressions may be marked with "implicit"
				if expression.standaloneAttributes.contains("implicit") {
					result = try translateExpression(innerExpression)
				}
				else {
					result = ParenthesesExpression(
						range: getRangeRecursively(ofNode: expression),
						expression: try translateExpression(innerExpression))
				}
			}
			else {
				result = try unexpectedExpressionStructureError(
					"Expected parentheses expression to have at least one subtree",
					ast: expression)
			}
		case "Force Value Expression":
			if let firstExpression = expression.subtree(at: 0) {
				let subExpression = try translateExpression(firstExpression)
				result = ForceValueExpression(
					range: getRangeRecursively(ofNode: expression),
					expression: subExpression)
			}
			else {
				result = try unexpectedExpressionStructureError(
					"Expected force value expression to have at least one subtree",
					ast: expression)
			}
		case "Bind Optional Expression":
			if let firstExpression = expression.subtree(at: 0) {
				let subExpression = try translateExpression(firstExpression)
				result = OptionalExpression(
					range: getRangeRecursively(ofNode: expression),
					expression: subExpression)
			}
			else {
				result = try unexpectedExpressionStructureError(
					"Expected optional expression to have at least one subtree",
					ast: expression)
			}
		case "Conditional Checked Cast Expression":
			let subExpression = expression.subtrees.first
			let typeName = expression["writtenType"]

			if let typeName = typeName, let subExpression = subExpression {
				result = BinaryOperatorExpression(
					range: getRangeRecursively(ofNode: expression),
					leftExpression: try translateExpression(subExpression),
					rightExpression: TypeExpression(
						range: getRangeRecursively(ofNode: expression),
						typeName: typeName),
					operatorSymbol: "as?",
					typeName: typeName)
			}
			else {
				result = try unexpectedExpressionStructureError(
					"Expected Conditional Checked Cast Expression to have a type and " +
					"an expression as a subtree",
					ast: expression)
			}
		case "Is Subtype Expression":
			let subExpression = expression.subtrees.first
			let typeName = expression["writtenType"]

			if let typeName = typeName, let subExpression = subExpression {
				result = BinaryOperatorExpression(
					range: getRangeRecursively(ofNode: expression),
					leftExpression: try translateExpression(subExpression),
					rightExpression: TypeExpression(
						range: getRangeRecursively(ofNode: expression),
						typeName: typeName),
					operatorSymbol: "is",
					typeName: "Bool")
			}
			else {
				result = try unexpectedExpressionStructureError(
					"Expected Is Subtype Expression to have a type and an expression as a subtree",
					ast: expression)
			}
		case "Super Reference Expression":
			if let typeName = expression["type"] {
				result = DeclarationReferenceExpression(
					range: getRange(ofNode: expression),
					identifier: "super",
					typeName: typeName,
					isStandardLibrary: false,
					isImplicit: false)
			}
			else {
				result = try unexpectedExpressionStructureError(
					"Unable to get type from Super Reference Expression",
					ast: expression)
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
			 "Rebind Self In Constructor Expression",
			 "Metatype Conversion Expression":

			if let lastExpression = expression.subtrees.last {
				result = try translateExpression(lastExpression)
			}
			else {
				result = try unexpectedExpressionStructureError(
					"Unrecognized structure in automatic expression",
					ast: expression)
			}
		case "Collection Upcast Expression":
			if let firstExpression = expression.subtrees.first {
				result = try translateExpression(firstExpression)
			}
			else {
				result = try unexpectedExpressionStructureError(
					"Unrecognized structure in automatic expression",
					ast: expression)
			}
		case "Other Constructor Reference Expression":
			result = DeclarationReferenceExpression(
				range: getRangeRecursively(ofNode: expression),
				identifier: "init",
				typeName: expression["type"]!,
				isStandardLibrary: false,
				isImplicit: false)

		default:
			result = try unexpectedExpressionStructureError(
				"Unknown expression", ast: expression)
		}

		let shouldInspect = nodeHasTranslationComment(expression, withKey: .inspect)
		if shouldInspect {
			print("===\nInspecting:")
			print(expression)
			result.prettyPrint()
		}

		return result
	}

	internal func translateTypeExpression(_ typeExpression: SwiftAST) throws -> Expression {
		guard typeExpression.name == "Type Expression" else {
			return try unexpectedExpressionStructureError(
				"Trying to translate \(typeExpression.name) as 'Type Expression'",
				ast: typeExpression)
		}

		guard let typeName = typeExpression["typerepr"] else {
			return try unexpectedExpressionStructureError(
				"Unrecognized structure",
				ast: typeExpression)
		}

		return TypeExpression(
			range: getRangeRecursively(ofNode: typeExpression),
			typeName: cleanUpType(typeName))
	}

	internal func translateCallExpression(_ callExpression: SwiftAST) throws -> Expression {
		guard callExpression.name == "Call Expression" else {
			return try unexpectedExpressionStructureError(
				"Trying to translate \(callExpression.name) as 'Call Expression'",
				ast: callExpression)
		}

		// If the call expression corresponds to an integer literal
		if let argumentLabels = callExpression["arg_labels"] {
			if argumentLabels == "_builtinIntegerLiteral:" ||
				argumentLabels == "_builtinFloatLiteral:"
			{
				return try translateAsNumericLiteral(callExpression)
			}
			else if argumentLabels == "_builtinBooleanLiteral:" {
				return try translateAsBooleanLiteral(callExpression)
			}
			else if argumentLabels == "nilLiteral:" {
				return NilLiteralExpression(range: getRangeRecursively(ofNode: callExpression))
			}
		}

		let function: Expression

		// If it's an empty expression used in an "if" condition
		let dotSyntaxSubtrees = callExpression
			.subtree(named: "Dot Syntax Call Expression")?.subtrees
		let containedExpression = dotSyntaxSubtrees?.last

		if let containedExpression = containedExpression,
			callExpression.standaloneAttributes.contains("implicit"),
			callExpression["arg_labels"] == "",
			callExpression["type"] == "Int1"
		{
			return try translateExpression(containedExpression)
		}

		guard let rawType = callExpression["type"] else {
			return try unexpectedExpressionStructureError(
				"Failed to recognize type", ast: callExpression)
		}
		let typeName = cleanUpType(rawType)

		let dotSyntaxCallExpression = callExpression
			.subtree(named: "Dot Syntax Call Expression")
		let methodName = dotSyntaxCallExpression?
			.subtree(at: 0, named: "Declaration Reference Expression")
		let methodOwner = dotSyntaxCallExpression?.subtree(at: 1)

		if let methodName = methodName, let methodOwner = methodOwner {
			let methodName = try translateDeclarationReferenceExpression(methodName)
			let methodOwner = try translateExpression(methodOwner)
			function = DotExpression(
				range: getRangeRecursively(ofNode: callExpression),
				leftExpression: methodOwner,
				rightExpression: methodName)
		}
		else if let declarationReferenceExpression = callExpression
			.subtree(named: "Declaration Reference Expression")
		{
			function = try translateDeclarationReferenceExpression(
				declarationReferenceExpression)
		}
		else if let typeExpression = callExpression
			.subtree(named: "Constructor Reference Call Expression")?
			.subtree(named: "Type Expression")
		{
			function = try translateTypeExpression(typeExpression)
		}
		else {
			function = try translateExpression(callExpression.subtrees[0])
		}

		let parameters = try translateCallExpressionParameters(callExpression)

		let range = getRange(ofNode: callExpression)

		return CallExpression(
			range: range,
			function: function,
			parameters: parameters,
			typeName: typeName)
	}

	internal func translateClosureExpression(
		_ closureExpression: SwiftAST)
		throws -> Expression
	{
		guard closureExpression.name == "Closure Expression" else {
			return try unexpectedExpressionStructureError(
				"Trying to translate \(closureExpression.name) as 'Closure Expression'",
				ast: closureExpression)
		}

		// Get the parameters.
		let parameterList: SwiftAST?

		if let unwrapped = closureExpression.subtree(named: "Parameter List") {
			parameterList = unwrapped
		}
		else {
			parameterList = nil
		}

		// Translate the parameters
		let parameters: MutableList<LabeledType> = []
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
						ast: closureExpression)
				}
			}
		}

		// Translate the return type
		// FIXME: Doesn't allow to return function types
		guard let typeName = closureExpression["type"] else {
			return try unexpectedExpressionStructureError(
				"Unable to get type or return type", ast: closureExpression)
		}

		// Translate the closure body
		guard let lastSubtree = closureExpression.subtrees.last else {
			return try unexpectedExpressionStructureError(
				"Unable to get closure body", ast: closureExpression)
		}

		let statements: MutableList<Statement>
		if lastSubtree.name == "Brace Statement" {
			statements = try translateBraceStatement(lastSubtree)
		}
		else {
			let expression = try translateExpression(lastSubtree)
			statements = [ExpressionStatement(
				range: expression.range,
				expression: expression), ]
		}

		return ClosureExpression(
			range: getRangeRecursively(ofNode: closureExpression),
			parameters: parameters,
			statements: statements,
			typeName: cleanUpType(typeName))
	}

	internal func translateCallExpressionParameters(
		_ callExpression: SwiftAST)
		throws -> Expression
	{
		guard callExpression.name == "Call Expression" else {
			return try unexpectedExpressionStructureError(
				"Trying to translate \(callExpression.name) as 'Call Expression'",
				ast: callExpression)
		}

		let parameters: Expression
		if let parenthesesExpression = callExpression.subtree(named: "Parentheses Expression") {
			let expression = try translateExpression(parenthesesExpression)
			parameters = TupleExpression(
				range: getRangeRecursively(ofNode: parenthesesExpression),
				pairs: [LabeledExpression(label: nil, expression: expression)])
		}
		else if let tupleExpression = callExpression.subtree(named: "Tuple Expression") {
			parameters = try translateTupleExpression(tupleExpression)
		}
		else if let tupleShuffleExpression = callExpression
			.subtree(named: "Argument Shuffle Expression")
		{
			let parenthesesExpression = tupleShuffleExpression
				.subtree(named: "Parentheses Expression")

			let tupleExpression = tupleShuffleExpression.subtree(named: "Tuple Expression")
			let typeName = tupleShuffleExpression["type"]
			let elements = tupleShuffleExpression["elements"]
			let rawIndicesStrings = elements?.split(withStringSeparator: ", ")
			let rawIndices = rawIndicesStrings.map({ $0.map { Int($0) } })

			if let parenthesesExpression = parenthesesExpression {
				let expression = try translateExpression(parenthesesExpression)
				parameters = TupleExpression(
					range: getRangeRecursively(ofNode: parenthesesExpression),
					pairs: [LabeledExpression(label: nil, expression: expression)])
			}
			else if let tupleExpression = tupleExpression,
				let typeName = typeName,
				let rawIndices = rawIndices
			{
				let indices: MutableList<TupleShuffleIndex> = []
				for rawIndex in rawIndices {

					guard let rawIndex = rawIndex else {
						return try unexpectedExpressionStructureError(
							"Expected Tuple shuffle index to be an integer",
							ast: callExpression)
					}

					if rawIndex == -2 {
						let variadicSources = tupleShuffleExpression["variadic_sources"]?
							.split(withStringSeparator: ", ")
						guard let variadicCount = variadicSources?.count else {
							return try unexpectedExpressionStructureError(
								"Failed to read variadic sources",
								ast: callExpression)
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
							ast: callExpression)
					}
				}

				let tupleComponents =
					String(typeName.dropFirst().dropLast()).split(withStringSeparator: ", ")
				let labels = tupleComponents.map { getLabelFromTupleComponent($0) }

				let expressions = try tupleExpression.subtrees.map {
					try translateExpression($0)
				}
				parameters = TupleShuffleExpression(
					range: getRangeRecursively(ofNode: tupleShuffleExpression),
					labels: labels.toMutableList(),
					indices: indices,
					expressions: expressions.toMutableList())
			}
			else {
				return try unexpectedExpressionStructureError(
					"Unrecognized structure in parameters", ast: callExpression)
			}
		}
		else {
			return try unexpectedExpressionStructureError(
				"Unrecognized structure in parameters", ast: callExpression)
		}

		return parameters
	}

	/// Tuples here can be either "(Int, Int)" or "(a: Int, b: Int)". This function is called for
	/// each component in the tuple and returns either `nil` or "a" accordingly.
	private func getLabelFromTupleComponent(_ component: String) -> String? {
		if component.contains(":") {
			let label = component.prefix(while: {
					$0 !=
						":" // gryphon value: ':'
				})
			return String(label)
		}
		else {
			return nil
		}
	}

	internal func translateTupleExpression(_ tupleExpression: SwiftAST) throws -> Expression {
		guard tupleExpression.name == "Tuple Expression" else {
			return try unexpectedExpressionStructureError(
				"Trying to translate \(tupleExpression.name) as 'Tuple Expression'",
				ast: tupleExpression)
		}

		let namesArray: MutableList<String>
		if let names = tupleExpression["names"] {
			namesArray = MutableList<Substring>(names.split(separator: ","))
				.map { String($0) }
				.toMutableList()
		}
		else {
			// If there are no names create a list of enough length with all empty names
			namesArray = tupleExpression.subtrees.map { _ in "_" }.toMutableList()
		}

		let tuplePairs: MutableList<LabeledExpression> = []

		for (name, expression) in zip(namesArray, tupleExpression.subtrees) {
			let expression = try translateExpression(expression)

			if name == "_" {
				tuplePairs.append(LabeledExpression(label: nil, expression: expression))
			}
			else {
				tuplePairs.append(
					LabeledExpression(label: String(name), expression: expression))
			}
		}

		return TupleExpression(
			range: getRangeRecursively(ofNode: tupleExpression),
			pairs: tuplePairs)
	}

	internal func translateInterpolatedStringLiteralExpression(
		_ interpolatedStringLiteralExpression: SwiftAST)
		throws -> Expression
	{
		guard interpolatedStringLiteralExpression.name ==
			"Interpolated String Literal Expression" else
		{
			return try unexpectedExpressionStructureError(
				"Trying to translate \(interpolatedStringLiteralExpression.name) as " +
				"'Interpolated String Literal Expression'",
				ast: interpolatedStringLiteralExpression)
		}

		guard let braceStatement = interpolatedStringLiteralExpression
			.subtree(named: "Tap Expression")?
			.subtree(named: "Brace Statement") else
		{
			return try unexpectedExpressionStructureError(
				"Expected the Interpolated String Literal Expression to contain a Tap" +
					"Expression containing a Brace Statement containing the String " +
				"interpolation contents",
				ast: interpolatedStringLiteralExpression)
		}

		let expressions: MutableList<Expression> = []

		for callExpression in braceStatement.subtrees.dropFirst() {
			let maybeSubtrees = callExpression.subtree(named: "Parentheses Expression")?.subtrees
			let maybeExpression = maybeSubtrees?.first
			guard callExpression.name == "Call Expression",
				let expression = maybeExpression else
			{
				return try unexpectedExpressionStructureError(
					"Expected the brace statement to contain only Call Expressions containing " +
					"Parentheses Expressions containing the relevant expressions.",
					ast: interpolatedStringLiteralExpression)
			}

			let translatedExpression = try translateExpression(expression)
			expressions.append(translatedExpression)
		}

		return InterpolatedStringLiteralExpression(
			range: getRangeRecursively(ofNode: interpolatedStringLiteralExpression),
			expressions: expressions)
	}

	internal func translateSubscriptExpression(
		_ subscriptExpression: SwiftAST)
		throws -> Expression
	{
		guard subscriptExpression.name == "Subscript Expression" else {
			return try unexpectedExpressionStructureError(
				"Trying to translate \(subscriptExpression.name) as 'Subscript Expression'",
				ast: subscriptExpression)
		}

		let rawType = subscriptExpression["type"]
		let subscriptContents = subscriptExpression.subtree(
			at: 1,
			named: "Parentheses Expression") ??
			subscriptExpression.subtree(
				at: 1, named: "Tuple Expression")
		let subscriptedExpression = subscriptExpression.subtree(at: 0)

		if let rawType = rawType,
			let subscriptContents = subscriptContents,
			let subscriptedExpression = subscriptedExpression
		{
			let typeName = cleanUpType(rawType)
			let subscriptContentsTranslation = try translateExpression(subscriptContents)
			let subscriptedExpressionTranslation = try translateExpression(subscriptedExpression)

			return SubscriptExpression(
				range: getRangeRecursively(ofNode: subscriptExpression),
				subscriptedExpression: subscriptedExpressionTranslation,
				indexExpression: subscriptContentsTranslation,
				typeName: typeName)
		}
		else {
			return try unexpectedExpressionStructureError(
				"Unrecognized structure", ast: subscriptExpression)
		}
	}

	internal func translateArrayExpression(_ arrayExpression: SwiftAST) throws -> Expression {
		guard arrayExpression.name == "Array Expression" else {
			return try unexpectedExpressionStructureError(
				"Trying to translate \(arrayExpression.name) as 'Array Expression'",
				ast: arrayExpression)
		}

		// Drop the "Semantic Expression" at the end
		let expressionsToTranslate = MutableList<SwiftAST>(arrayExpression.subtrees.dropLast())

		let expressionsArray = try expressionsToTranslate
			.map { try translateExpression($0) }
			.toMutableList()

		guard let rawType = arrayExpression["type"] else {
			return try unexpectedExpressionStructureError(
				"Failed to get type", ast: arrayExpression)
		}
		let typeName = cleanUpType(rawType)

		return ArrayExpression(
			range: getRangeRecursively(ofNode: arrayExpression),
			elements: expressionsArray,
			typeName: typeName)
	}

	internal func translateDictionaryExpression(
		_ dictionaryExpression: SwiftAST)
		throws -> Expression
	{
		guard dictionaryExpression.name == "Dictionary Expression" else {
			return try unexpectedExpressionStructureError(
				"Trying to translate \(dictionaryExpression.name) as 'Dictionary Expression'",
				ast: dictionaryExpression)
		}

		let keys: MutableList<Expression> = []
		let values: MutableList<Expression> = []
		for tupleExpression in dictionaryExpression.subtrees {
			guard tupleExpression.name == "Tuple Expression" else {
				continue
			}
			guard let keyAST = tupleExpression.subtree(at: 0),
				let valueAST = tupleExpression.subtree(at: 1) else
			{
				return try unexpectedExpressionStructureError(
					"Unable to get either key or value for one of the tuple expressions",
					ast: dictionaryExpression)
			}

			let keyTranslation = try translateExpression(keyAST)
			let valueTranslation = try translateExpression(valueAST)
			keys.append(keyTranslation)
			values.append(valueTranslation)
		}

		guard let typeName = dictionaryExpression["type"] else {
			return try unexpectedExpressionStructureError(
				"Unable to get type",
				ast: dictionaryExpression)
		}

		return DictionaryExpression(
			range: getRangeRecursively(ofNode: dictionaryExpression),
			keys: keys,
			values: values,
			typeName: typeName)
	}

	internal func translateAsNumericLiteral(
		_ numericLiteralExpression: SwiftAST)
		throws -> Expression
	{
		// FIXME: Negative float literals are translated as positive becuase the AST dump doesn't
		// seemd to include any info showing they're negative.
		// Bug filed at https://bugs.swift.org/browse/SR-10131

		let literalExpression: SwiftAST?
		let rawType: String?

		if numericLiteralExpression.name == "Call Expression" {
			let tupleExpression = numericLiteralExpression.subtree(named: "Tuple Expression")
			literalExpression = tupleExpression?.subtree(named: "Integer Literal Expression") ??
				tupleExpression?.subtree(named: "Float Literal Expression")

			let constructorReferenceCallExpression = numericLiteralExpression
				.subtree(named: "Constructor Reference Call Expression")
			let typeExpression = constructorReferenceCallExpression?.subtree(named: "Type Expression")
			rawType = typeExpression?["typerepr"]
		}
		else if numericLiteralExpression.name == "Integer Literal Expression" ||
			numericLiteralExpression.name == "Float Literal Expression"
		{
			literalExpression = numericLiteralExpression
			rawType = numericLiteralExpression["type"]
		}
		else {
			return try unexpectedExpressionStructureError(
                "Unrecognized structure for numeric literal",
                ast: numericLiteralExpression)
		}

		let value = literalExpression?["value"]

		if let value = value, let literalExpression = literalExpression, let rawType = rawType {
			if value.hasPrefix("0b") || value.hasPrefix("0o") || value.hasPrefix("0x") {
				// Fixable
				return try unexpectedExpressionStructureError(
					"No support yet for alternative integer formats",
					ast: numericLiteralExpression)
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
				return LiteralDoubleExpression(
					range: getRangeRecursively(ofNode: literalExpression),
					value: Double(signedValue)!)
			}
			else if typeName == "Float" || typeName == "Float32" {
				return LiteralFloatExpression(
					range: getRangeRecursively(ofNode: literalExpression),
					value: Float(signedValue)!)
			}
			else if typeName == "Float80" {
				return try unexpectedExpressionStructureError(
					"No support for 80-bit Floats", ast: numericLiteralExpression)
			}
			else if typeName.hasPrefix("U") {
				return LiteralUIntExpression(
					range: getRangeRecursively(ofNode: literalExpression),
					value: UInt64(signedValue)!)
			}
			else {
				if signedValue == "-9223372036854775808" {
					return try unexpectedExpressionStructureError(
						"Kotlin's Long (equivalent to Int64) only goes down to " +
						"-9223372036854775807", ast: numericLiteralExpression)
				}
				else {
					return LiteralIntExpression(
						range: getRangeRecursively(ofNode: literalExpression),
						value: Int64(signedValue)!)
				}
			}
		}
		else {
			return try unexpectedExpressionStructureError(
				"Unrecognized structure for numeric literal",
				ast: numericLiteralExpression)
		}
	}

	internal func translateAsBooleanLiteral(
		_ callExpression: SwiftAST)
		throws -> Expression
	{
		guard callExpression.name == "Call Expression" else {
			return try unexpectedExpressionStructureError(
				"Trying to translate \(callExpression.name) as 'Call Expression'",
				ast: callExpression)
		}

		if let value = callExpression
			.subtree(named: "Tuple Expression")?
			.subtree(named: "Boolean Literal Expression")?["value"]
		{
			return LiteralBoolExpression(
				range: getRangeRecursively(ofNode: callExpression),
				value: (value == "true"))
		}
		else {
			return try unexpectedExpressionStructureError(
				"Unrecognized structure for boolean literal", ast: callExpression)
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
				ast: stringLiteralExpression)
		}

		if let value = stringLiteralExpression["value"],
			let typeName = stringLiteralExpression["type"]
		{
			if Utilities.getTypeMapping(for: typeName) == "Char" {
				if value == "\'" {
					return LiteralCharacterExpression(
						range: getRangeRecursively(ofNode: stringLiteralExpression),
						value: "\\\'")
				}
				else {
					return LiteralCharacterExpression(
						range: getRangeRecursively(ofNode: stringLiteralExpression),
						value: value)
				}
			}
			else {
				// Check if there's a `// gryphon multiline` comment just before the string
				// literal, since we can't put a comment in the same line as a multiline string.
				var isMultiline = false
				if let lineNumber = getRange(ofNode: stringLiteralExpression)?.lineStart {
					if let translationComment =
							sourceFile?.getTranslationCommentFromLine(lineNumber - 1)
					{
						isMultiline = (translationComment.key == .multiline)
					}
				}

				return LiteralStringExpression(
					range: getRangeRecursively(ofNode: stringLiteralExpression),
					value: value,
					isMultiline: isMultiline)
			}
		}
		else {
			return try unexpectedExpressionStructureError(
				"Unrecognized structure", ast: stringLiteralExpression)
		}
	}

	internal func translateDeclarationReferenceExpression(
		_ declarationReferenceExpression: SwiftAST)
		throws -> Expression
	{
		guard declarationReferenceExpression.name == "Declaration Reference Expression" else {
			return try unexpectedExpressionStructureError(
				"Trying to translate \(declarationReferenceExpression.name) as " +
				"'Declaration Reference Expression'",
				ast: declarationReferenceExpression)
		}

		guard let rawType = declarationReferenceExpression["type"] else {
			return try unexpectedExpressionStructureError(
				"Failed to recognize type", ast: declarationReferenceExpression)
		}
		let typeName = cleanUpType(rawType)

		let isImplicit = declarationReferenceExpression.standaloneAttributes.contains("implicit")

		let range = getRange(ofNode: declarationReferenceExpression)

		if let discriminator = declarationReferenceExpression["discriminator"] {
			let declarationInformation = getInformationFromDeclaration(discriminator)

			return DeclarationReferenceExpression(
					range: range,
					identifier: declarationInformation.identifier,
					typeName: typeName,
					isStandardLibrary: declarationInformation.isStandardLibrary,
					isImplicit: isImplicit)
		}
		else if let codeDeclaration = declarationReferenceExpression.standaloneAttributes.first,
			codeDeclaration.hasPrefix("code.")
		{
			let declarationInformation = getInformationFromDeclaration(codeDeclaration)
			return DeclarationReferenceExpression(
				range: range,
				identifier: declarationInformation.identifier,
				typeName: typeName,
				isStandardLibrary: declarationInformation.isStandardLibrary,
				isImplicit: isImplicit)
		}
		else if let declaration = declarationReferenceExpression["decl"] {
			let declarationInformation = getInformationFromDeclaration(declaration)
			return DeclarationReferenceExpression(
				range: range,
				identifier: declarationInformation.identifier,
				typeName: typeName,
				isStandardLibrary: declarationInformation.isStandardLibrary,
				isImplicit: isImplicit)
		}
		else {
			return try unexpectedExpressionStructureError(
				"Unrecognized structure", ast: declarationReferenceExpression)
		}
	}

	// MARK: - Source file interactions

	internal func insertedCode(inRange range: Range<Int>) -> MutableList<Statement> {
		let result: MutableList<Statement> = []
		for lineNumber in range {
			let astRange = SourceFileRange(
				lineStart: lineNumber, lineEnd: lineNumber, columnStart: 0, columnEnd: 0)

			let insertComment = sourceFile?.getTranslationCommentFromLine(lineNumber)
			let commentValue = insertComment?.value
			if let insertComment = insertComment,
				let commentValue = commentValue
			{
				if insertComment.key == .insertInMain {
					result.append(ExpressionStatement(
						range: astRange,
						expression: LiteralCodeExpression(
							range: astRange,
							string: commentValue,
							shouldGoToMainFunction: true)))
				}
				else if insertComment.key == .insert {
					result.append(ExpressionStatement(
						range: astRange,
						expression: LiteralCodeExpression(
							range: astRange,
							string: commentValue,
							shouldGoToMainFunction: false)))
				}
				else if insertComment.key == .output,
					let fileExtension = Utilities.getExtension(of: commentValue)
				{
					outputFileMap[fileExtension] = insertComment.value
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

	internal func getTranslationCommentValue(
		forNode ast: SwiftAST,
		key: SourceFile.CommentKey)
		-> String?
	{
		if let comment = getTranslationComment(forNode: ast), comment.key == key {
			return comment.value
		}
		return nil
	}

	/// Returns true if the given node has a translation comment with the given key (i.e.
	/// `// gryphon <key>`). Returns false otherwise.
	internal func nodeHasTranslationComment(
		_ ast: SwiftAST,
		withKey key: SourceFile.CommentKey)
		-> Bool
	{
		if let comment = getTranslationComment(forNode: ast), comment.key == key {
			return true
		}
		return false
	}

	internal func getTranslationComment(forNode ast: SwiftAST) -> SourceFile.TranslationComment? {
		if let lineNumber = getRange(ofNode: ast)?.lineStart {
			return sourceFile?.getTranslationCommentFromLine(lineNumber)
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
				ast: patternBindingDeclaration)
			danglingPatternBindings = [errorDanglingPatternDeclaration]
			return
		}

		let result: MutableList<PatternBindingDeclaration?> = []

		let subtreesCopy = patternBindingDeclaration.subtrees.toMutableList()
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
						"Type not recognized", ast: patternBindingDeclaration)
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
				ast: openExistentialExpression)
			return SwiftAST("Error", [], [:], [])
		}

		guard let replacementSubtree = openExistentialExpression.subtree(at: 1),
			let resultSubtree = openExistentialExpression.subtrees.last else
		{
			_ = try unexpectedExpressionStructureError(
				"Expected the AST to contain 3 subtrees: an Opaque Value Expression, an " +
					"expression to replace the opaque value, and an expression containing " +
				"opaque values to be replaced.",
				ast: openExistentialExpression)
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

		let newSubtrees: MutableList<SwiftAST> = []
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
	@discardableResult
	private func unexpectedASTStructureError(
		_ errorMessage: String,
		ast: SwiftAST)
		throws -> Statement
	{
		var nodeDescription = ""
		ast.prettyPrint(horizontalLimit: 100) {
			nodeDescription += $0
		}

		let message = "failed to turn Swift AST into Gryphon AST: " + errorMessage + "."
		let astDetails = "Thrown when translating the following AST node:\n\(nodeDescription)"

		try Compiler.handleError(
			message: message,
			astDetails: astDetails,
			sourceFile: sourceFile,
			sourceFileRange: getRangeRecursively(ofNode: ast))
		return ErrorStatement(range: getRangeRecursively(ofNode: ast))
	}

	@discardableResult
	private func unexpectedExpressionStructureError(
		_ errorMessage: String,
		ast: SwiftAST)
		throws -> Expression
	{
		var nodeDescription = ""
		ast.prettyPrint(horizontalLimit: 100) {
			nodeDescription += $0
		}

		let message = "failed to turn Swift AST into Gryphon AST: " + errorMessage + "."
		let astDetails = "Thrown when translating the following AST node:\n\(nodeDescription)"

		try Compiler.handleError(
			message: message,
			astDetails: astDetails,
			sourceFile: sourceFile,
			sourceFileRange: getRangeRecursively(ofNode: ast))
		return ErrorExpression(range: getRangeRecursively(ofNode: ast))
	}

	@discardableResult
	private func unexpectedIfStructureError(
		_ errorMessage: String,
		ast: SwiftAST)
		throws -> IfStatement
	{
		var nodeDescription = ""
		ast.prettyPrint(horizontalLimit: 100) {
			nodeDescription += $0
		}

		let message = "failed to turn Swift AST into Gryphon AST: " + errorMessage + "."
		let astDetails = "Thrown when translating the following AST node:\n\(nodeDescription)"

		try Compiler.handleError(
			message: message,
			astDetails: astDetails,
			sourceFile: sourceFile,
			sourceFileRange: getRangeRecursively(ofNode: ast))
		return IfStatement(
			range: nil,
			conditions: [IfStatement.IfCondition.condition(expression:
				ErrorExpression(range: getRangeRecursively(ofNode: ast))), ],
			declarations: [],
			statements: [],
			elseStatement: nil,
			isGuard: false)
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
	let conditions: MutableList<IfStatement.IfCondition>
	let statements: MutableList<Statement>
}

private struct EnumPatternTranslation {
	let enumType: String
	let enumCase: String
	let declarations: MutableList<AssociatedValueDeclaration>
	let comparisons: MutableList<AssociatedValueComparison>
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
