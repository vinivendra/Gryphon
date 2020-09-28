import SwiftSyntax

extension SyntaxProtocol {
	func toPrintableTree() -> PrintableTree {
		return SwiftSyntaxToPrintableTreeVisitor().convertToPrintableTree(self)
	}

	func prettyPrint() {
		self.toPrintableTree().prettyPrint()
	}

	func prettyDescription() -> String {
		return self.toPrintableTree().prettyDescription()
	}
}

open class SwiftSyntaxToPrintableTreeVisitor: SyntaxVisitor {
	let root = PrintableTree("Root")
	var nodeStack: MutableList<PrintableTree> = []

	override init() {
		nodeStack.append(root)
		super.init()
	}

	func convertToPrintableTree<SyntaxType: SyntaxProtocol>(_ node: SyntaxType) -> PrintableTree {
		let logInfo = Log.startLog(name: "Converting SS for printing")
		defer { Log.endLog(info: logInfo) }
		self.walk(node)
		return root
	}

	open func visitAny(_ node: Syntax, _ name: String) -> SyntaxVisitorContinueKind {
		let properties: MutableList<PrintableAsTree?> = []
		for property in node.customMirror.children {
			let valueString = "\(property.value)"
			let index100After = valueString.index(
				valueString.startIndex,
				offsetBy: 100,
				limitedBy: valueString.endIndex)
				?? valueString.endIndex
			let limitedValue = String(valueString[..<index100After])
			let escapedValue = limitedValue
				.replacingOccurrences(of: "\n", with: "\\n")
				.replacingOccurrences(of: "\t", with: "\\t")
			
			properties.append(PrintableTree("\(property.label ?? "_") -> \(escapedValue)"))
		}
		let newNode = PrintableTree(name, properties)
		
		nodeStack.append(newNode)
		return .visitChildren
	}

	open func visitAnyPost(_ node: Syntax) {
		let topMostNode = nodeStack.last!
		nodeStack.removeLast()
		let parent = nodeStack.last!
		parent.printableSubtrees = parent.printableSubtrees.appending(topMostNode)
	}

	// MARK: Override type specific visit methods

	override open func visit(_ token: TokenSyntax) -> SyntaxVisitorContinueKind {
		return visitAny(token._syntaxNode, "Token")
	}

	override open func visitPost(_ node: TokenSyntax) {
		visitAnyPost(node._syntaxNode)
	}

	override open func visit(_ node: UnknownSyntax) -> SyntaxVisitorContinueKind {
		return visitAny(node._syntaxNode, "Unknown")
	}

	override open func visitPost(_ node: UnknownSyntax) {
		visitAnyPost(node._syntaxNode)
	}

	override open func visit(_ node: UnknownDeclSyntax) -> SyntaxVisitorContinueKind {
		return visitAny(node._syntaxNode, "UnknownDecl")
	}

	override open func visitPost(_ node: UnknownDeclSyntax) {
		visitAnyPost(node._syntaxNode)
	}
	override open func visit(_ node: UnknownExprSyntax) -> SyntaxVisitorContinueKind {
		return visitAny(node._syntaxNode, "UnknownExpr")
	}

	override open func visitPost(_ node: UnknownExprSyntax) {
		visitAnyPost(node._syntaxNode)
	}
	override open func visit(_ node: UnknownStmtSyntax) -> SyntaxVisitorContinueKind {
		return visitAny(node._syntaxNode, "UnknownStmt")
	}

	override open func visitPost(_ node: UnknownStmtSyntax) {
		visitAnyPost(node._syntaxNode)
	}
	override open func visit(_ node: UnknownTypeSyntax) -> SyntaxVisitorContinueKind {
		return visitAny(node._syntaxNode, "UnknownType")
	}

	override open func visitPost(_ node: UnknownTypeSyntax) {
		visitAnyPost(node._syntaxNode)
	}
	override open func visit(_ node: UnknownPatternSyntax) -> SyntaxVisitorContinueKind {
		return visitAny(node._syntaxNode, "UnknownPattern")
	}

	override open func visitPost(_ node: UnknownPatternSyntax) {
		visitAnyPost(node._syntaxNode)
	}
	override open func visit(_ node: CodeBlockItemSyntax) -> SyntaxVisitorContinueKind {
		return visitAny(node._syntaxNode, "CodeBlockItem")
	}

	override open func visitPost(_ node: CodeBlockItemSyntax) {
		visitAnyPost(node._syntaxNode)
	}
	override open func visit(_ node: CodeBlockItemListSyntax) -> SyntaxVisitorContinueKind {
		return visitAny(node._syntaxNode, "CodeBlockItemList")
	}

	override open func visitPost(_ node: CodeBlockItemListSyntax) {
		visitAnyPost(node._syntaxNode)
	}
	override open func visit(_ node: CodeBlockSyntax) -> SyntaxVisitorContinueKind {
		return visitAny(node._syntaxNode, "CodeBlock")
	}

	override open func visitPost(_ node: CodeBlockSyntax) {
		visitAnyPost(node._syntaxNode)
	}
	override open func visit(_ node: InOutExprSyntax) -> SyntaxVisitorContinueKind {
		return visitAny(node._syntaxNode, "InOutExpr")
	}

	override open func visitPost(_ node: InOutExprSyntax) {
		visitAnyPost(node._syntaxNode)
	}
	override open func visit(_ node: PoundColumnExprSyntax) -> SyntaxVisitorContinueKind {
		return visitAny(node._syntaxNode, "PoundColumnExpr")
	}

	override open func visitPost(_ node: PoundColumnExprSyntax) {
		visitAnyPost(node._syntaxNode)
	}
	override open func visit(_ node: TupleExprElementListSyntax) -> SyntaxVisitorContinueKind {
		return visitAny(node._syntaxNode, "TupleExprElementList")
	}

	override open func visitPost(_ node: TupleExprElementListSyntax) {
		visitAnyPost(node._syntaxNode)
	}
	override open func visit(_ node: ArrayElementListSyntax) -> SyntaxVisitorContinueKind {
		return visitAny(node._syntaxNode, "ArrayElementList")
	}

	override open func visitPost(_ node: ArrayElementListSyntax) {
		visitAnyPost(node._syntaxNode)
	}
	override open func visit(_ node: DictionaryElementListSyntax) -> SyntaxVisitorContinueKind {
		return visitAny(node._syntaxNode, "DictionaryElementList")
	}

	override open func visitPost(_ node: DictionaryElementListSyntax) {
		visitAnyPost(node._syntaxNode)
	}
	override open func visit(_ node: StringLiteralSegmentsSyntax) -> SyntaxVisitorContinueKind {
		return visitAny(node._syntaxNode, "StringLiteralSegments")
	}

	override open func visitPost(_ node: StringLiteralSegmentsSyntax) {
		visitAnyPost(node._syntaxNode)
	}
	override open func visit(_ node: TryExprSyntax) -> SyntaxVisitorContinueKind {
		return visitAny(node._syntaxNode, "TryExpr")
	}

	override open func visitPost(_ node: TryExprSyntax) {
		visitAnyPost(node._syntaxNode)
	}
	override open func visit(_ node: DeclNameArgumentSyntax) -> SyntaxVisitorContinueKind {
		return visitAny(node._syntaxNode, "DeclNameArgument")
	}

	override open func visitPost(_ node: DeclNameArgumentSyntax) {
		visitAnyPost(node._syntaxNode)
	}
	override open func visit(_ node: DeclNameArgumentListSyntax) -> SyntaxVisitorContinueKind {
		return visitAny(node._syntaxNode, "DeclNameArgumentList")
	}

	override open func visitPost(_ node: DeclNameArgumentListSyntax) {
		visitAnyPost(node._syntaxNode)
	}
	override open func visit(_ node: DeclNameArgumentsSyntax) -> SyntaxVisitorContinueKind {
		return visitAny(node._syntaxNode, "DeclNameArguments")
	}

	override open func visitPost(_ node: DeclNameArgumentsSyntax) {
		visitAnyPost(node._syntaxNode)
	}
	override open func visit(_ node: IdentifierExprSyntax) -> SyntaxVisitorContinueKind {
		return visitAny(node._syntaxNode, "IdentifierExpr")
	}

	override open func visitPost(_ node: IdentifierExprSyntax) {
		visitAnyPost(node._syntaxNode)
	}
	override open func visit(_ node: SuperRefExprSyntax) -> SyntaxVisitorContinueKind {
		return visitAny(node._syntaxNode, "SuperRefExpr")
	}

	override open func visitPost(_ node: SuperRefExprSyntax) {
		visitAnyPost(node._syntaxNode)
	}
	override open func visit(_ node: NilLiteralExprSyntax) -> SyntaxVisitorContinueKind {
		return visitAny(node._syntaxNode, "NilLiteralExpr")
	}

	override open func visitPost(_ node: NilLiteralExprSyntax) {
		visitAnyPost(node._syntaxNode)
	}
	override open func visit(_ node: DiscardAssignmentExprSyntax) -> SyntaxVisitorContinueKind {
		return visitAny(node._syntaxNode, "DiscardAssignmentExpr")
	}

	override open func visitPost(_ node: DiscardAssignmentExprSyntax) {
		visitAnyPost(node._syntaxNode)
	}
	override open func visit(_ node: AssignmentExprSyntax) -> SyntaxVisitorContinueKind {
		return visitAny(node._syntaxNode, "AssignmentExpr")
	}

	override open func visitPost(_ node: AssignmentExprSyntax) {
		visitAnyPost(node._syntaxNode)
	}
	override open func visit(_ node: SequenceExprSyntax) -> SyntaxVisitorContinueKind {
		return visitAny(node._syntaxNode, "SequenceExpr")
	}

	override open func visitPost(_ node: SequenceExprSyntax) {
		visitAnyPost(node._syntaxNode)
	}
	override open func visit(_ node: ExprListSyntax) -> SyntaxVisitorContinueKind {
		return visitAny(node._syntaxNode, "ExprList")
	}

	override open func visitPost(_ node: ExprListSyntax) {
		visitAnyPost(node._syntaxNode)
	}
	override open func visit(_ node: PoundLineExprSyntax) -> SyntaxVisitorContinueKind {
		return visitAny(node._syntaxNode, "PoundLineExpr")
	}

	override open func visitPost(_ node: PoundLineExprSyntax) {
		visitAnyPost(node._syntaxNode)
	}
	override open func visit(_ node: PoundFileExprSyntax) -> SyntaxVisitorContinueKind {
		return visitAny(node._syntaxNode, "PoundFileExpr")
	}

	override open func visitPost(_ node: PoundFileExprSyntax) {
		visitAnyPost(node._syntaxNode)
	}
	override open func visit(_ node: PoundFilePathExprSyntax) -> SyntaxVisitorContinueKind {
		return visitAny(node._syntaxNode, "PoundFilePathExpr")
	}

	override open func visitPost(_ node: PoundFilePathExprSyntax) {
		visitAnyPost(node._syntaxNode)
	}
	override open func visit(_ node: PoundFunctionExprSyntax) -> SyntaxVisitorContinueKind {
		return visitAny(node._syntaxNode, "PoundFunctionExpr")
	}

	override open func visitPost(_ node: PoundFunctionExprSyntax) {
		visitAnyPost(node._syntaxNode)
	}
	override open func visit(_ node: PoundDsohandleExprSyntax) -> SyntaxVisitorContinueKind {
		return visitAny(node._syntaxNode, "PoundDsohandleExpr")
	}

	override open func visitPost(_ node: PoundDsohandleExprSyntax) {
		visitAnyPost(node._syntaxNode)
	}
	override open func visit(_ node: SymbolicReferenceExprSyntax) -> SyntaxVisitorContinueKind {
		return visitAny(node._syntaxNode, "SymbolicReferenceExpr")
	}

	override open func visitPost(_ node: SymbolicReferenceExprSyntax) {
		visitAnyPost(node._syntaxNode)
	}
	override open func visit(_ node: PrefixOperatorExprSyntax) -> SyntaxVisitorContinueKind {
		return visitAny(node._syntaxNode, "PrefixOperatorExpr")
	}

	override open func visitPost(_ node: PrefixOperatorExprSyntax) {
		visitAnyPost(node._syntaxNode)
	}
	override open func visit(_ node: BinaryOperatorExprSyntax) -> SyntaxVisitorContinueKind {
		return visitAny(node._syntaxNode, "BinaryOperatorExpr")
	}

	override open func visitPost(_ node: BinaryOperatorExprSyntax) {
		visitAnyPost(node._syntaxNode)
	}
	override open func visit(_ node: ArrowExprSyntax) -> SyntaxVisitorContinueKind {
		return visitAny(node._syntaxNode, "ArrowExpr")
	}

	override open func visitPost(_ node: ArrowExprSyntax) {
		visitAnyPost(node._syntaxNode)
	}
	override open func visit(_ node: FloatLiteralExprSyntax) -> SyntaxVisitorContinueKind {
		return visitAny(node._syntaxNode, "FloatLiteralExpr")
	}

	override open func visitPost(_ node: FloatLiteralExprSyntax) {
		visitAnyPost(node._syntaxNode)
	}
	override open func visit(_ node: TupleExprSyntax) -> SyntaxVisitorContinueKind {
		return visitAny(node._syntaxNode, "TupleExpr")
	}

	override open func visitPost(_ node: TupleExprSyntax) {
		visitAnyPost(node._syntaxNode)
	}
	override open func visit(_ node: ArrayExprSyntax) -> SyntaxVisitorContinueKind {
		return visitAny(node._syntaxNode, "ArrayExpr")
	}

	override open func visitPost(_ node: ArrayExprSyntax) {
		visitAnyPost(node._syntaxNode)
	}
	override open func visit(_ node: DictionaryExprSyntax) -> SyntaxVisitorContinueKind {
		return visitAny(node._syntaxNode, "DictionaryExpr")
	}

	override open func visitPost(_ node: DictionaryExprSyntax) {
		visitAnyPost(node._syntaxNode)
	}
	override open func visit(_ node: TupleExprElementSyntax) -> SyntaxVisitorContinueKind {
		return visitAny(node._syntaxNode, "TupleExprElement")
	}

	override open func visitPost(_ node: TupleExprElementSyntax) {
		visitAnyPost(node._syntaxNode)
	}
	override open func visit(_ node: ArrayElementSyntax) -> SyntaxVisitorContinueKind {
		return visitAny(node._syntaxNode, "ArrayElement")
	}

	override open func visitPost(_ node: ArrayElementSyntax) {
		visitAnyPost(node._syntaxNode)
	}
	override open func visit(_ node: DictionaryElementSyntax) -> SyntaxVisitorContinueKind {
		return visitAny(node._syntaxNode, "DictionaryElement")
	}

	override open func visitPost(_ node: DictionaryElementSyntax) {
		visitAnyPost(node._syntaxNode)
	}
	override open func visit(_ node: IntegerLiteralExprSyntax) -> SyntaxVisitorContinueKind {
		return visitAny(node._syntaxNode, "IntegerLiteralExpr")
	}

	override open func visitPost(_ node: IntegerLiteralExprSyntax) {
		visitAnyPost(node._syntaxNode)
	}
	override open func visit(_ node: BooleanLiteralExprSyntax) -> SyntaxVisitorContinueKind {
		return visitAny(node._syntaxNode, "BooleanLiteralExpr")
	}

	override open func visitPost(_ node: BooleanLiteralExprSyntax) {
		visitAnyPost(node._syntaxNode)
	}
	override open func visit(_ node: TernaryExprSyntax) -> SyntaxVisitorContinueKind {
		return visitAny(node._syntaxNode, "TernaryExpr")
	}

	override open func visitPost(_ node: TernaryExprSyntax) {
		visitAnyPost(node._syntaxNode)
	}
	override open func visit(_ node: MemberAccessExprSyntax) -> SyntaxVisitorContinueKind {
		return visitAny(node._syntaxNode, "MemberAccessExpr")
	}

	override open func visitPost(_ node: MemberAccessExprSyntax) {
		visitAnyPost(node._syntaxNode)
	}
	override open func visit(_ node: IsExprSyntax) -> SyntaxVisitorContinueKind {
		return visitAny(node._syntaxNode, "IsExpr")
	}

	override open func visitPost(_ node: IsExprSyntax) {
		visitAnyPost(node._syntaxNode)
	}
	override open func visit(_ node: AsExprSyntax) -> SyntaxVisitorContinueKind {
		return visitAny(node._syntaxNode, "AsExpr")
	}

	override open func visitPost(_ node: AsExprSyntax) {
		visitAnyPost(node._syntaxNode)
	}
	override open func visit(_ node: TypeExprSyntax) -> SyntaxVisitorContinueKind {
		return visitAny(node._syntaxNode, "TypeExpr")
	}

	override open func visitPost(_ node: TypeExprSyntax) {
		visitAnyPost(node._syntaxNode)
	}
	override open func visit(_ node: ClosureCaptureItemSyntax) -> SyntaxVisitorContinueKind {
		return visitAny(node._syntaxNode, "ClosureCaptureItem")
	}

	override open func visitPost(_ node: ClosureCaptureItemSyntax) {
		visitAnyPost(node._syntaxNode)
	}
	override open func visit(_ node: ClosureCaptureItemListSyntax) -> SyntaxVisitorContinueKind {
		return visitAny(node._syntaxNode, "ClosureCaptureItemList")
	}

	override open func visitPost(_ node: ClosureCaptureItemListSyntax) {
		visitAnyPost(node._syntaxNode)
	}
	override open func visit(_ node: ClosureCaptureSignatureSyntax) -> SyntaxVisitorContinueKind {
		return visitAny(node._syntaxNode, "ClosureCaptureSignature")
	}

	override open func visitPost(_ node: ClosureCaptureSignatureSyntax) {
		visitAnyPost(node._syntaxNode)
	}
	override open func visit(_ node: ClosureParamSyntax) -> SyntaxVisitorContinueKind {
		return visitAny(node._syntaxNode, "ClosureParam")
	}

	override open func visitPost(_ node: ClosureParamSyntax) {
		visitAnyPost(node._syntaxNode)
	}
	override open func visit(_ node: ClosureParamListSyntax) -> SyntaxVisitorContinueKind {
		return visitAny(node._syntaxNode, "ClosureParamList")
	}

	override open func visitPost(_ node: ClosureParamListSyntax) {
		visitAnyPost(node._syntaxNode)
	}
	override open func visit(_ node: ClosureSignatureSyntax) -> SyntaxVisitorContinueKind {
		return visitAny(node._syntaxNode, "ClosureSignature")
	}

	override open func visitPost(_ node: ClosureSignatureSyntax) {
		visitAnyPost(node._syntaxNode)
	}
	override open func visit(_ node: ClosureExprSyntax) -> SyntaxVisitorContinueKind {
		return visitAny(node._syntaxNode, "ClosureExpr")
	}

	override open func visitPost(_ node: ClosureExprSyntax) {
		visitAnyPost(node._syntaxNode)
	}
	override open func visit(_ node: UnresolvedPatternExprSyntax) -> SyntaxVisitorContinueKind {
		return visitAny(node._syntaxNode, "UnresolvedPatternExpr")
	}

	override open func visitPost(_ node: UnresolvedPatternExprSyntax) {
		visitAnyPost(node._syntaxNode)
	}
	override open func visit(_ node: FunctionCallExprSyntax) -> SyntaxVisitorContinueKind {
		return visitAny(node._syntaxNode, "FunctionCallExpr")
	}

	override open func visitPost(_ node: FunctionCallExprSyntax) {
		visitAnyPost(node._syntaxNode)
	}
	override open func visit(_ node: SubscriptExprSyntax) -> SyntaxVisitorContinueKind {
		return visitAny(node._syntaxNode, "SubscriptExpr")
	}

	override open func visitPost(_ node: SubscriptExprSyntax) {
		visitAnyPost(node._syntaxNode)
	}
	override open func visit(_ node: OptionalChainingExprSyntax) -> SyntaxVisitorContinueKind {
		return visitAny(node._syntaxNode, "OptionalChainingExpr")
	}

	override open func visitPost(_ node: OptionalChainingExprSyntax) {
		visitAnyPost(node._syntaxNode)
	}
	override open func visit(_ node: ForcedValueExprSyntax) -> SyntaxVisitorContinueKind {
		return visitAny(node._syntaxNode, "ForcedValueExpr")
	}

	override open func visitPost(_ node: ForcedValueExprSyntax) {
		visitAnyPost(node._syntaxNode)
	}
	override open func visit(_ node: PostfixUnaryExprSyntax) -> SyntaxVisitorContinueKind {
		return visitAny(node._syntaxNode, "PostfixUnaryExpr")
	}

	override open func visitPost(_ node: PostfixUnaryExprSyntax) {
		visitAnyPost(node._syntaxNode)
	}
	override open func visit(_ node: SpecializeExprSyntax) -> SyntaxVisitorContinueKind {
		return visitAny(node._syntaxNode, "SpecializeExpr")
	}

	override open func visitPost(_ node: SpecializeExprSyntax) {
		visitAnyPost(node._syntaxNode)
	}
	override open func visit(_ node: StringSegmentSyntax) -> SyntaxVisitorContinueKind {
		return visitAny(node._syntaxNode, "StringSegment")
	}

	override open func visitPost(_ node: StringSegmentSyntax) {
		visitAnyPost(node._syntaxNode)
	}
	override open func visit(_ node: ExpressionSegmentSyntax) -> SyntaxVisitorContinueKind {
		return visitAny(node._syntaxNode, "ExpressionSegment")
	}

	override open func visitPost(_ node: ExpressionSegmentSyntax) {
		visitAnyPost(node._syntaxNode)
	}
	override open func visit(_ node: StringLiteralExprSyntax) -> SyntaxVisitorContinueKind {
		return visitAny(node._syntaxNode, "StringLiteralExpr")
	}

	override open func visitPost(_ node: StringLiteralExprSyntax) {
		visitAnyPost(node._syntaxNode)
	}
	override open func visit(_ node: KeyPathExprSyntax) -> SyntaxVisitorContinueKind {
		return visitAny(node._syntaxNode, "KeyPathExpr")
	}

	override open func visitPost(_ node: KeyPathExprSyntax) {
		visitAnyPost(node._syntaxNode)
	}
	override open func visit(_ node: KeyPathBaseExprSyntax) -> SyntaxVisitorContinueKind {
		return visitAny(node._syntaxNode, "KeyPathBaseExpr")
	}

	override open func visitPost(_ node: KeyPathBaseExprSyntax) {
		visitAnyPost(node._syntaxNode)
	}
	override open func visit(_ node: ObjcNamePieceSyntax) -> SyntaxVisitorContinueKind {
		return visitAny(node._syntaxNode, "ObjcNamePiece")
	}

	override open func visitPost(_ node: ObjcNamePieceSyntax) {
		visitAnyPost(node._syntaxNode)
	}
	override open func visit(_ node: ObjcNameSyntax) -> SyntaxVisitorContinueKind {
		return visitAny(node._syntaxNode, "ObjcName")
	}

	override open func visitPost(_ node: ObjcNameSyntax) {
		visitAnyPost(node._syntaxNode)
	}
	override open func visit(_ node: ObjcKeyPathExprSyntax) -> SyntaxVisitorContinueKind {
		return visitAny(node._syntaxNode, "ObjcKeyPathExpr")
	}

	override open func visitPost(_ node: ObjcKeyPathExprSyntax) {
		visitAnyPost(node._syntaxNode)
	}
	override open func visit(_ node: ObjcSelectorExprSyntax) -> SyntaxVisitorContinueKind {
		return visitAny(node._syntaxNode, "ObjcSelectorExpr")
	}

	override open func visitPost(_ node: ObjcSelectorExprSyntax) {
		visitAnyPost(node._syntaxNode)
	}
	override open func visit(_ node: EditorPlaceholderExprSyntax) -> SyntaxVisitorContinueKind {
		return visitAny(node._syntaxNode, "EditorPlaceholderExpr")
	}

	override open func visitPost(_ node: EditorPlaceholderExprSyntax) {
		visitAnyPost(node._syntaxNode)
	}
	override open func visit(_ node: ObjectLiteralExprSyntax) -> SyntaxVisitorContinueKind {
		return visitAny(node._syntaxNode, "ObjectLiteralExpr")
	}

	override open func visitPost(_ node: ObjectLiteralExprSyntax) {
		visitAnyPost(node._syntaxNode)
	}
	override open func visit(_ node: TypeInitializerClauseSyntax) -> SyntaxVisitorContinueKind {
		return visitAny(node._syntaxNode, "TypeInitializerClause")
	}

	override open func visitPost(_ node: TypeInitializerClauseSyntax) {
		visitAnyPost(node._syntaxNode)
	}
	override open func visit(_ node: TypealiasDeclSyntax) -> SyntaxVisitorContinueKind {
		return visitAny(node._syntaxNode, "TypealiasDecl")
	}

	override open func visitPost(_ node: TypealiasDeclSyntax) {
		visitAnyPost(node._syntaxNode)
	}
	override open func visit(_ node: AssociatedtypeDeclSyntax) -> SyntaxVisitorContinueKind {
		return visitAny(node._syntaxNode, "AssociatedtypeDecl")
	}

	override open func visitPost(_ node: AssociatedtypeDeclSyntax) {
		visitAnyPost(node._syntaxNode)
	}
	override open func visit(_ node: FunctionParameterListSyntax) -> SyntaxVisitorContinueKind {
		return visitAny(node._syntaxNode, "FunctionParameterList")
	}

	override open func visitPost(_ node: FunctionParameterListSyntax) {
		visitAnyPost(node._syntaxNode)
	}
	override open func visit(_ node: ParameterClauseSyntax) -> SyntaxVisitorContinueKind {
		return visitAny(node._syntaxNode, "ParameterClause")
	}

	override open func visitPost(_ node: ParameterClauseSyntax) {
		visitAnyPost(node._syntaxNode)
	}
	override open func visit(_ node: ReturnClauseSyntax) -> SyntaxVisitorContinueKind {
		return visitAny(node._syntaxNode, "ReturnClause")
	}

	override open func visitPost(_ node: ReturnClauseSyntax) {
		visitAnyPost(node._syntaxNode)
	}
	override open func visit(_ node: FunctionSignatureSyntax) -> SyntaxVisitorContinueKind {
		return visitAny(node._syntaxNode, "FunctionSignature")
	}

	override open func visitPost(_ node: FunctionSignatureSyntax) {
		visitAnyPost(node._syntaxNode)
	}
	override open func visit(_ node: IfConfigClauseSyntax) -> SyntaxVisitorContinueKind {
		return visitAny(node._syntaxNode, "IfConfigClause")
	}

	override open func visitPost(_ node: IfConfigClauseSyntax) {
		visitAnyPost(node._syntaxNode)
	}
	override open func visit(_ node: IfConfigClauseListSyntax) -> SyntaxVisitorContinueKind {
		return visitAny(node._syntaxNode, "IfConfigClauseList")
	}

	override open func visitPost(_ node: IfConfigClauseListSyntax) {
		visitAnyPost(node._syntaxNode)
	}
	override open func visit(_ node: IfConfigDeclSyntax) -> SyntaxVisitorContinueKind {
		return visitAny(node._syntaxNode, "IfConfigDecl")
	}

	override open func visitPost(_ node: IfConfigDeclSyntax) {
		visitAnyPost(node._syntaxNode)
	}
	override open func visit(_ node: PoundErrorDeclSyntax) -> SyntaxVisitorContinueKind {
		return visitAny(node._syntaxNode, "PoundErrorDecl")
	}

	override open func visitPost(_ node: PoundErrorDeclSyntax) {
		visitAnyPost(node._syntaxNode)
	}
	override open func visit(_ node: PoundWarningDeclSyntax) -> SyntaxVisitorContinueKind {
		return visitAny(node._syntaxNode, "PoundWarningDecl")
	}

	override open func visitPost(_ node: PoundWarningDeclSyntax) {
		visitAnyPost(node._syntaxNode)
	}
	override open func visit(_ node: PoundSourceLocationSyntax) -> SyntaxVisitorContinueKind {
		return visitAny(node._syntaxNode, "PoundSourceLocation")
	}

	override open func visitPost(_ node: PoundSourceLocationSyntax) {
		visitAnyPost(node._syntaxNode)
	}
	override open func visit(_ node: PoundSourceLocationArgsSyntax) -> SyntaxVisitorContinueKind {
		return visitAny(node._syntaxNode, "PoundSourceLocationArgs")
	}

	override open func visitPost(_ node: PoundSourceLocationArgsSyntax) {
		visitAnyPost(node._syntaxNode)
	}
	override open func visit(_ node: DeclModifierSyntax) -> SyntaxVisitorContinueKind {
		return visitAny(node._syntaxNode, "DeclModifier")
	}

	override open func visitPost(_ node: DeclModifierSyntax) {
		visitAnyPost(node._syntaxNode)
	}
	override open func visit(_ node: InheritedTypeSyntax) -> SyntaxVisitorContinueKind {
		return visitAny(node._syntaxNode, "InheritedType")
	}

	override open func visitPost(_ node: InheritedTypeSyntax) {
		visitAnyPost(node._syntaxNode)
	}
	override open func visit(_ node: InheritedTypeListSyntax) -> SyntaxVisitorContinueKind {
		return visitAny(node._syntaxNode, "InheritedTypeList")
	}

	override open func visitPost(_ node: InheritedTypeListSyntax) {
		visitAnyPost(node._syntaxNode)
	}
	override open func visit(_ node: TypeInheritanceClauseSyntax) -> SyntaxVisitorContinueKind {
		return visitAny(node._syntaxNode, "TypeInheritanceClause")
	}

	override open func visitPost(_ node: TypeInheritanceClauseSyntax) {
		visitAnyPost(node._syntaxNode)
	}
	override open func visit(_ node: ClassDeclSyntax) -> SyntaxVisitorContinueKind {
		return visitAny(node._syntaxNode, "ClassDecl")
	}

	override open func visitPost(_ node: ClassDeclSyntax) {
		visitAnyPost(node._syntaxNode)
	}
	override open func visit(_ node: StructDeclSyntax) -> SyntaxVisitorContinueKind {
		return visitAny(node._syntaxNode, "StructDecl")
	}

	override open func visitPost(_ node: StructDeclSyntax) {
		visitAnyPost(node._syntaxNode)
	}
	override open func visit(_ node: ProtocolDeclSyntax) -> SyntaxVisitorContinueKind {
		return visitAny(node._syntaxNode, "ProtocolDecl")
	}

	override open func visitPost(_ node: ProtocolDeclSyntax) {
		visitAnyPost(node._syntaxNode)
	}
	override open func visit(_ node: ExtensionDeclSyntax) -> SyntaxVisitorContinueKind {
		return visitAny(node._syntaxNode, "ExtensionDecl")
	}

	override open func visitPost(_ node: ExtensionDeclSyntax) {
		visitAnyPost(node._syntaxNode)
	}
	override open func visit(_ node: MemberDeclBlockSyntax) -> SyntaxVisitorContinueKind {
		return visitAny(node._syntaxNode, "MemberDeclBlock")
	}

	override open func visitPost(_ node: MemberDeclBlockSyntax) {
		visitAnyPost(node._syntaxNode)
	}
	override open func visit(_ node: MemberDeclListSyntax) -> SyntaxVisitorContinueKind {
		return visitAny(node._syntaxNode, "MemberDeclList")
	}

	override open func visitPost(_ node: MemberDeclListSyntax) {
		visitAnyPost(node._syntaxNode)
	}
	override open func visit(_ node: MemberDeclListItemSyntax) -> SyntaxVisitorContinueKind {
		return visitAny(node._syntaxNode, "MemberDeclListItem")
	}

	override open func visitPost(_ node: MemberDeclListItemSyntax) {
		visitAnyPost(node._syntaxNode)
	}
	override open func visit(_ node: SourceFileSyntax) -> SyntaxVisitorContinueKind {
		return visitAny(node._syntaxNode, "SourceFile")
	}

	override open func visitPost(_ node: SourceFileSyntax) {
		visitAnyPost(node._syntaxNode)
	}
	override open func visit(_ node: InitializerClauseSyntax) -> SyntaxVisitorContinueKind {
		return visitAny(node._syntaxNode, "InitializerClause")
	}

	override open func visitPost(_ node: InitializerClauseSyntax) {
		visitAnyPost(node._syntaxNode)
	}
	override open func visit(_ node: FunctionParameterSyntax) -> SyntaxVisitorContinueKind {
		return visitAny(node._syntaxNode, "FunctionParameter")
	}

	override open func visitPost(_ node: FunctionParameterSyntax) {
		visitAnyPost(node._syntaxNode)
	}
	override open func visit(_ node: ModifierListSyntax) -> SyntaxVisitorContinueKind {
		return visitAny(node._syntaxNode, "ModifierList")
	}

	override open func visitPost(_ node: ModifierListSyntax) {
		visitAnyPost(node._syntaxNode)
	}
	override open func visit(_ node: FunctionDeclSyntax) -> SyntaxVisitorContinueKind {
		return visitAny(node._syntaxNode, "FunctionDecl")
	}

	override open func visitPost(_ node: FunctionDeclSyntax) {
		visitAnyPost(node._syntaxNode)
	}
	override open func visit(_ node: InitializerDeclSyntax) -> SyntaxVisitorContinueKind {
		return visitAny(node._syntaxNode, "InitializerDecl")
	}

	override open func visitPost(_ node: InitializerDeclSyntax) {
		visitAnyPost(node._syntaxNode)
	}
	override open func visit(_ node: DeinitializerDeclSyntax) -> SyntaxVisitorContinueKind {
		return visitAny(node._syntaxNode, "DeinitializerDecl")
	}

	override open func visitPost(_ node: DeinitializerDeclSyntax) {
		visitAnyPost(node._syntaxNode)
	}
	override open func visit(_ node: SubscriptDeclSyntax) -> SyntaxVisitorContinueKind {
		return visitAny(node._syntaxNode, "SubscriptDecl")
	}

	override open func visitPost(_ node: SubscriptDeclSyntax) {
		visitAnyPost(node._syntaxNode)
	}
	override open func visit(_ node: AccessLevelModifierSyntax) -> SyntaxVisitorContinueKind {
		return visitAny(node._syntaxNode, "AccessLevelModifier")
	}

	override open func visitPost(_ node: AccessLevelModifierSyntax) {
		visitAnyPost(node._syntaxNode)
	}
	override open func visit(_ node: AccessPathComponentSyntax) -> SyntaxVisitorContinueKind {
		return visitAny(node._syntaxNode, "AccessPathComponent")
	}

	override open func visitPost(_ node: AccessPathComponentSyntax) {
		visitAnyPost(node._syntaxNode)
	}
	override open func visit(_ node: AccessPathSyntax) -> SyntaxVisitorContinueKind {
		return visitAny(node._syntaxNode, "AccessPath")
	}

	override open func visitPost(_ node: AccessPathSyntax) {
		visitAnyPost(node._syntaxNode)
	}
	override open func visit(_ node: ImportDeclSyntax) -> SyntaxVisitorContinueKind {
		return visitAny(node._syntaxNode, "ImportDecl")
	}

	override open func visitPost(_ node: ImportDeclSyntax) {
		visitAnyPost(node._syntaxNode)
	}
	override open func visit(_ node: AccessorParameterSyntax) -> SyntaxVisitorContinueKind {
		return visitAny(node._syntaxNode, "AccessorParameter")
	}

	override open func visitPost(_ node: AccessorParameterSyntax) {
		visitAnyPost(node._syntaxNode)
	}
	override open func visit(_ node: AccessorDeclSyntax) -> SyntaxVisitorContinueKind {
		return visitAny(node._syntaxNode, "AccessorDecl")
	}

	override open func visitPost(_ node: AccessorDeclSyntax) {
		visitAnyPost(node._syntaxNode)
	}
	override open func visit(_ node: AccessorListSyntax) -> SyntaxVisitorContinueKind {
		return visitAny(node._syntaxNode, "AccessorList")
	}

	override open func visitPost(_ node: AccessorListSyntax) {
		visitAnyPost(node._syntaxNode)
	}
	override open func visit(_ node: AccessorBlockSyntax) -> SyntaxVisitorContinueKind {
		return visitAny(node._syntaxNode, "AccessorBlock")
	}

	override open func visitPost(_ node: AccessorBlockSyntax) {
		visitAnyPost(node._syntaxNode)
	}
	override open func visit(_ node: PatternBindingSyntax) -> SyntaxVisitorContinueKind {
		return visitAny(node._syntaxNode, "PatternBinding")
	}

	override open func visitPost(_ node: PatternBindingSyntax) {
		visitAnyPost(node._syntaxNode)
	}
	override open func visit(_ node: PatternBindingListSyntax) -> SyntaxVisitorContinueKind {
		return visitAny(node._syntaxNode, "PatternBindingList")
	}

	override open func visitPost(_ node: PatternBindingListSyntax) {
		visitAnyPost(node._syntaxNode)
	}
	override open func visit(_ node: VariableDeclSyntax) -> SyntaxVisitorContinueKind {
		return visitAny(node._syntaxNode, "VariableDecl")
	}

	override open func visitPost(_ node: VariableDeclSyntax) {
		visitAnyPost(node._syntaxNode)
	}
	override open func visit(_ node: EnumCaseElementSyntax) -> SyntaxVisitorContinueKind {
		return visitAny(node._syntaxNode, "EnumCaseElement")
	}

	override open func visitPost(_ node: EnumCaseElementSyntax) {
		visitAnyPost(node._syntaxNode)
	}
	override open func visit(_ node: EnumCaseElementListSyntax) -> SyntaxVisitorContinueKind {
		return visitAny(node._syntaxNode, "EnumCaseElementList")
	}

	override open func visitPost(_ node: EnumCaseElementListSyntax) {
		visitAnyPost(node._syntaxNode)
	}
	override open func visit(_ node: EnumCaseDeclSyntax) -> SyntaxVisitorContinueKind {
		return visitAny(node._syntaxNode, "EnumCaseDecl")
	}

	override open func visitPost(_ node: EnumCaseDeclSyntax) {
		visitAnyPost(node._syntaxNode)
	}
	override open func visit(_ node: EnumDeclSyntax) -> SyntaxVisitorContinueKind {
		return visitAny(node._syntaxNode, "EnumDecl")
	}

	override open func visitPost(_ node: EnumDeclSyntax) {
		visitAnyPost(node._syntaxNode)
	}
	override open func visit(_ node: OperatorDeclSyntax) -> SyntaxVisitorContinueKind {
		return visitAny(node._syntaxNode, "OperatorDecl")
	}

	override open func visitPost(_ node: OperatorDeclSyntax) {
		visitAnyPost(node._syntaxNode)
	}
	override open func visit(_ node: IdentifierListSyntax) -> SyntaxVisitorContinueKind {
		return visitAny(node._syntaxNode, "IdentifierList")
	}

	override open func visitPost(_ node: IdentifierListSyntax) {
		visitAnyPost(node._syntaxNode)
	}
	override open func visit(_ node: OperatorPrecedenceAndTypesSyntax) -> SyntaxVisitorContinueKind {
		return visitAny(node._syntaxNode, "OperatorPrecedenceAndTypes")
	}

	override open func visitPost(_ node: OperatorPrecedenceAndTypesSyntax) {
		visitAnyPost(node._syntaxNode)
	}
	override open func visit(_ node: PrecedenceGroupDeclSyntax) -> SyntaxVisitorContinueKind {
		return visitAny(node._syntaxNode, "PrecedenceGroupDecl")
	}

	override open func visitPost(_ node: PrecedenceGroupDeclSyntax) {
		visitAnyPost(node._syntaxNode)
	}
	override open func visit(_ node: PrecedenceGroupAttributeListSyntax) -> SyntaxVisitorContinueKind {
		return visitAny(node._syntaxNode, "PrecedenceGroupAttributeList")
	}

	override open func visitPost(_ node: PrecedenceGroupAttributeListSyntax) {
		visitAnyPost(node._syntaxNode)
	}
	override open func visit(_ node: PrecedenceGroupRelationSyntax) -> SyntaxVisitorContinueKind {
		return visitAny(node._syntaxNode, "PrecedenceGroupRelation")
	}

	override open func visitPost(_ node: PrecedenceGroupRelationSyntax) {
		visitAnyPost(node._syntaxNode)
	}
	override open func visit(_ node: PrecedenceGroupNameListSyntax) -> SyntaxVisitorContinueKind {
		return visitAny(node._syntaxNode, "PrecedenceGroupNameList")
	}

	override open func visitPost(_ node: PrecedenceGroupNameListSyntax) {
		visitAnyPost(node._syntaxNode)
	}
	override open func visit(_ node: PrecedenceGroupNameElementSyntax) -> SyntaxVisitorContinueKind {
		return visitAny(node._syntaxNode, "PrecedenceGroupNameElement")
	}

	override open func visitPost(_ node: PrecedenceGroupNameElementSyntax) {
		visitAnyPost(node._syntaxNode)
	}
	override open func visit(_ node: PrecedenceGroupAssignmentSyntax) -> SyntaxVisitorContinueKind {
		return visitAny(node._syntaxNode, "PrecedenceGroupAssignment")
	}

	override open func visitPost(_ node: PrecedenceGroupAssignmentSyntax) {
		visitAnyPost(node._syntaxNode)
	}
	override open func visit(_ node: PrecedenceGroupAssociativitySyntax) -> SyntaxVisitorContinueKind {
		return visitAny(node._syntaxNode, "PrecedenceGroupAssociativity")
	}

	override open func visitPost(_ node: PrecedenceGroupAssociativitySyntax) {
		visitAnyPost(node._syntaxNode)
	}
	override open func visit(_ node: TokenListSyntax) -> SyntaxVisitorContinueKind {
		return visitAny(node._syntaxNode, "TokenList")
	}

	override open func visitPost(_ node: TokenListSyntax) {
		visitAnyPost(node._syntaxNode)
	}
	override open func visit(_ node: NonEmptyTokenListSyntax) -> SyntaxVisitorContinueKind {
		return visitAny(node._syntaxNode, "NonEmptyTokenList")
	}

	override open func visitPost(_ node: NonEmptyTokenListSyntax) {
		visitAnyPost(node._syntaxNode)
	}
	override open func visit(_ node: CustomAttributeSyntax) -> SyntaxVisitorContinueKind {
		return visitAny(node._syntaxNode, "CustomAttribute")
	}

	override open func visitPost(_ node: CustomAttributeSyntax) {
		visitAnyPost(node._syntaxNode)
	}
	override open func visit(_ node: AttributeSyntax) -> SyntaxVisitorContinueKind {
		return visitAny(node._syntaxNode, "Attribute")
	}

	override open func visitPost(_ node: AttributeSyntax) {
		visitAnyPost(node._syntaxNode)
	}
	override open func visit(_ node: AttributeListSyntax) -> SyntaxVisitorContinueKind {
		return visitAny(node._syntaxNode, "AttributeList")
	}

	override open func visitPost(_ node: AttributeListSyntax) {
		visitAnyPost(node._syntaxNode)
	}
	override open func visit(_ node: SpecializeAttributeSpecListSyntax) -> SyntaxVisitorContinueKind {
		return visitAny(node._syntaxNode, "SpecializeAttributeSpecList")
	}

	override open func visitPost(_ node: SpecializeAttributeSpecListSyntax) {
		visitAnyPost(node._syntaxNode)
	}
	override open func visit(_ node: LabeledSpecializeEntrySyntax) -> SyntaxVisitorContinueKind {
		return visitAny(node._syntaxNode, "LabeledSpecializeEntry")
	}

	override open func visitPost(_ node: LabeledSpecializeEntrySyntax) {
		visitAnyPost(node._syntaxNode)
	}
	override open func visit(_ node: NamedAttributeStringArgumentSyntax) -> SyntaxVisitorContinueKind {
		return visitAny(node._syntaxNode, "NamedAttributeStringArgument")
	}

	override open func visitPost(_ node: NamedAttributeStringArgumentSyntax) {
		visitAnyPost(node._syntaxNode)
	}
	override open func visit(_ node: DeclNameSyntax) -> SyntaxVisitorContinueKind {
		return visitAny(node._syntaxNode, "DeclName")
	}

	override open func visitPost(_ node: DeclNameSyntax) {
		visitAnyPost(node._syntaxNode)
	}
	override open func visit(_ node: ImplementsAttributeArgumentsSyntax) -> SyntaxVisitorContinueKind {
		return visitAny(node._syntaxNode, "ImplementsAttributeArguments")
	}

	override open func visitPost(_ node: ImplementsAttributeArgumentsSyntax) {
		visitAnyPost(node._syntaxNode)
	}
	override open func visit(_ node: ObjCSelectorPieceSyntax) -> SyntaxVisitorContinueKind {
		return visitAny(node._syntaxNode, "ObjCSelectorPiece")
	}

	override open func visitPost(_ node: ObjCSelectorPieceSyntax) {
		visitAnyPost(node._syntaxNode)
	}
	override open func visit(_ node: ObjCSelectorSyntax) -> SyntaxVisitorContinueKind {
		return visitAny(node._syntaxNode, "ObjCSelector")
	}

	override open func visitPost(_ node: ObjCSelectorSyntax) {
		visitAnyPost(node._syntaxNode)
	}
	override open func visit(_ node: DifferentiableAttributeArgumentsSyntax) -> SyntaxVisitorContinueKind {
		return visitAny(node._syntaxNode, "DifferentiableAttributeArguments")
	}

	override open func visitPost(_ node: DifferentiableAttributeArgumentsSyntax) {
		visitAnyPost(node._syntaxNode)
	}
	override open func visit(_ node: DifferentiationParamsClauseSyntax) -> SyntaxVisitorContinueKind {
		return visitAny(node._syntaxNode, "DifferentiationParamsClause")
	}

	override open func visitPost(_ node: DifferentiationParamsClauseSyntax) {
		visitAnyPost(node._syntaxNode)
	}
	override open func visit(_ node: DifferentiationParamsSyntax) -> SyntaxVisitorContinueKind {
		return visitAny(node._syntaxNode, "DifferentiationParams")
	}

	override open func visitPost(_ node: DifferentiationParamsSyntax) {
		visitAnyPost(node._syntaxNode)
	}
	override open func visit(_ node: DifferentiationParamListSyntax) -> SyntaxVisitorContinueKind {
		return visitAny(node._syntaxNode, "DifferentiationParamList")
	}

	override open func visitPost(_ node: DifferentiationParamListSyntax) {
		visitAnyPost(node._syntaxNode)
	}
	override open func visit(_ node: DifferentiationParamSyntax) -> SyntaxVisitorContinueKind {
		return visitAny(node._syntaxNode, "DifferentiationParam")
	}

	override open func visitPost(_ node: DifferentiationParamSyntax) {
		visitAnyPost(node._syntaxNode)
	}
	override open func visit(_ node: DifferentiableAttributeFuncSpecifierSyntax) -> SyntaxVisitorContinueKind {
		return visitAny(node._syntaxNode, "DifferentiableAttributeFuncSpecifier")
	}

	override open func visitPost(_ node: DifferentiableAttributeFuncSpecifierSyntax) {
		visitAnyPost(node._syntaxNode)
	}
	override open func visit(_ node: FunctionDeclNameSyntax) -> SyntaxVisitorContinueKind {
		return visitAny(node._syntaxNode, "FunctionDeclName")
	}

	override open func visitPost(_ node: FunctionDeclNameSyntax) {
		visitAnyPost(node._syntaxNode)
	}
	override open func visit(_ node: ContinueStmtSyntax) -> SyntaxVisitorContinueKind {
		return visitAny(node._syntaxNode, "ContinueStmt")
	}

	override open func visitPost(_ node: ContinueStmtSyntax) {
		visitAnyPost(node._syntaxNode)
	}
	override open func visit(_ node: WhileStmtSyntax) -> SyntaxVisitorContinueKind {
		return visitAny(node._syntaxNode, "WhileStmt")
	}

	override open func visitPost(_ node: WhileStmtSyntax) {
		visitAnyPost(node._syntaxNode)
	}
	override open func visit(_ node: DeferStmtSyntax) -> SyntaxVisitorContinueKind {
		return visitAny(node._syntaxNode, "DeferStmt")
	}

	override open func visitPost(_ node: DeferStmtSyntax) {
		visitAnyPost(node._syntaxNode)
	}
	override open func visit(_ node: ExpressionStmtSyntax) -> SyntaxVisitorContinueKind {
		return visitAny(node._syntaxNode, "ExpressionStmt")
	}

	override open func visitPost(_ node: ExpressionStmtSyntax) {
		visitAnyPost(node._syntaxNode)
	}
	override open func visit(_ node: SwitchCaseListSyntax) -> SyntaxVisitorContinueKind {
		return visitAny(node._syntaxNode, "SwitchCaseList")
	}

	override open func visitPost(_ node: SwitchCaseListSyntax) {
		visitAnyPost(node._syntaxNode)
	}
	override open func visit(_ node: RepeatWhileStmtSyntax) -> SyntaxVisitorContinueKind {
		return visitAny(node._syntaxNode, "RepeatWhileStmt")
	}

	override open func visitPost(_ node: RepeatWhileStmtSyntax) {
		visitAnyPost(node._syntaxNode)
	}
	override open func visit(_ node: GuardStmtSyntax) -> SyntaxVisitorContinueKind {
		return visitAny(node._syntaxNode, "GuardStmt")
	}

	override open func visitPost(_ node: GuardStmtSyntax) {
		visitAnyPost(node._syntaxNode)
	}
	override open func visit(_ node: WhereClauseSyntax) -> SyntaxVisitorContinueKind {
		return visitAny(node._syntaxNode, "WhereClause")
	}

	override open func visitPost(_ node: WhereClauseSyntax) {
		visitAnyPost(node._syntaxNode)
	}
	override open func visit(_ node: ForInStmtSyntax) -> SyntaxVisitorContinueKind {
		return visitAny(node._syntaxNode, "ForInStmt")
	}

	override open func visitPost(_ node: ForInStmtSyntax) {
		visitAnyPost(node._syntaxNode)
	}
	override open func visit(_ node: SwitchStmtSyntax) -> SyntaxVisitorContinueKind {
		return visitAny(node._syntaxNode, "SwitchStmt")
	}

	override open func visitPost(_ node: SwitchStmtSyntax) {
		visitAnyPost(node._syntaxNode)
	}
	override open func visit(_ node: CatchClauseListSyntax) -> SyntaxVisitorContinueKind {
		return visitAny(node._syntaxNode, "CatchClauseList")
	}

	override open func visitPost(_ node: CatchClauseListSyntax) {
		visitAnyPost(node._syntaxNode)
	}
	override open func visit(_ node: DoStmtSyntax) -> SyntaxVisitorContinueKind {
		return visitAny(node._syntaxNode, "DoStmt")
	}

	override open func visitPost(_ node: DoStmtSyntax) {
		visitAnyPost(node._syntaxNode)
	}
	override open func visit(_ node: ReturnStmtSyntax) -> SyntaxVisitorContinueKind {
		return visitAny(node._syntaxNode, "ReturnStmt")
	}

	override open func visitPost(_ node: ReturnStmtSyntax) {
		visitAnyPost(node._syntaxNode)
	}
	override open func visit(_ node: YieldStmtSyntax) -> SyntaxVisitorContinueKind {
		return visitAny(node._syntaxNode, "YieldStmt")
	}

	override open func visitPost(_ node: YieldStmtSyntax) {
		visitAnyPost(node._syntaxNode)
	}
	override open func visit(_ node: YieldListSyntax) -> SyntaxVisitorContinueKind {
		return visitAny(node._syntaxNode, "YieldList")
	}

	override open func visitPost(_ node: YieldListSyntax) {
		visitAnyPost(node._syntaxNode)
	}
	override open func visit(_ node: FallthroughStmtSyntax) -> SyntaxVisitorContinueKind {
		return visitAny(node._syntaxNode, "FallthroughStmt")
	}

	override open func visitPost(_ node: FallthroughStmtSyntax) {
		visitAnyPost(node._syntaxNode)
	}
	override open func visit(_ node: BreakStmtSyntax) -> SyntaxVisitorContinueKind {
		return visitAny(node._syntaxNode, "BreakStmt")
	}

	override open func visitPost(_ node: BreakStmtSyntax) {
		visitAnyPost(node._syntaxNode)
	}
	override open func visit(_ node: CaseItemListSyntax) -> SyntaxVisitorContinueKind {
		return visitAny(node._syntaxNode, "CaseItemList")
	}

	override open func visitPost(_ node: CaseItemListSyntax) {
		visitAnyPost(node._syntaxNode)
	}
	override open func visit(_ node: ConditionElementSyntax) -> SyntaxVisitorContinueKind {
		return visitAny(node._syntaxNode, "ConditionElement")
	}

	override open func visitPost(_ node: ConditionElementSyntax) {
		visitAnyPost(node._syntaxNode)
	}
	override open func visit(_ node: AvailabilityConditionSyntax) -> SyntaxVisitorContinueKind {
		return visitAny(node._syntaxNode, "AvailabilityCondition")
	}

	override open func visitPost(_ node: AvailabilityConditionSyntax) {
		visitAnyPost(node._syntaxNode)
	}
	override open func visit(_ node: MatchingPatternConditionSyntax) -> SyntaxVisitorContinueKind {
		return visitAny(node._syntaxNode, "MatchingPatternCondition")
	}

	override open func visitPost(_ node: MatchingPatternConditionSyntax) {
		visitAnyPost(node._syntaxNode)
	}
	override open func visit(_ node: OptionalBindingConditionSyntax) -> SyntaxVisitorContinueKind {
		return visitAny(node._syntaxNode, "OptionalBindingCondition")
	}

	override open func visitPost(_ node: OptionalBindingConditionSyntax) {
		visitAnyPost(node._syntaxNode)
	}
	override open func visit(_ node: ConditionElementListSyntax) -> SyntaxVisitorContinueKind {
		return visitAny(node._syntaxNode, "ConditionElementList")
	}

	override open func visitPost(_ node: ConditionElementListSyntax) {
		visitAnyPost(node._syntaxNode)
	}
	override open func visit(_ node: DeclarationStmtSyntax) -> SyntaxVisitorContinueKind {
		return visitAny(node._syntaxNode, "DeclarationStmt")
	}

	override open func visitPost(_ node: DeclarationStmtSyntax) {
		visitAnyPost(node._syntaxNode)
	}
	override open func visit(_ node: ThrowStmtSyntax) -> SyntaxVisitorContinueKind {
		return visitAny(node._syntaxNode, "ThrowStmt")
	}

	override open func visitPost(_ node: ThrowStmtSyntax) {
		visitAnyPost(node._syntaxNode)
	}
	override open func visit(_ node: IfStmtSyntax) -> SyntaxVisitorContinueKind {
		return visitAny(node._syntaxNode, "IfStmt")
	}

	override open func visitPost(_ node: IfStmtSyntax) {
		visitAnyPost(node._syntaxNode)
	}
	override open func visit(_ node: ElseIfContinuationSyntax) -> SyntaxVisitorContinueKind {
		return visitAny(node._syntaxNode, "ElseIfContinuation")
	}

	override open func visitPost(_ node: ElseIfContinuationSyntax) {
		visitAnyPost(node._syntaxNode)
	}
	override open func visit(_ node: ElseBlockSyntax) -> SyntaxVisitorContinueKind {
		return visitAny(node._syntaxNode, "ElseBlock")
	}

	override open func visitPost(_ node: ElseBlockSyntax) {
		visitAnyPost(node._syntaxNode)
	}
	override open func visit(_ node: SwitchCaseSyntax) -> SyntaxVisitorContinueKind {
		return visitAny(node._syntaxNode, "SwitchCase")
	}

	override open func visitPost(_ node: SwitchCaseSyntax) {
		visitAnyPost(node._syntaxNode)
	}
	override open func visit(_ node: SwitchDefaultLabelSyntax) -> SyntaxVisitorContinueKind {
		return visitAny(node._syntaxNode, "SwitchDefaultLabel")
	}

	override open func visitPost(_ node: SwitchDefaultLabelSyntax) {
		visitAnyPost(node._syntaxNode)
	}
	override open func visit(_ node: CaseItemSyntax) -> SyntaxVisitorContinueKind {
		return visitAny(node._syntaxNode, "CaseItem")
	}

	override open func visitPost(_ node: CaseItemSyntax) {
		visitAnyPost(node._syntaxNode)
	}
	override open func visit(_ node: SwitchCaseLabelSyntax) -> SyntaxVisitorContinueKind {
		return visitAny(node._syntaxNode, "SwitchCaseLabel")
	}

	override open func visitPost(_ node: SwitchCaseLabelSyntax) {
		visitAnyPost(node._syntaxNode)
	}
	override open func visit(_ node: CatchClauseSyntax) -> SyntaxVisitorContinueKind {
		return visitAny(node._syntaxNode, "CatchClause")
	}

	override open func visitPost(_ node: CatchClauseSyntax) {
		visitAnyPost(node._syntaxNode)
	}
	override open func visit(_ node: PoundAssertStmtSyntax) -> SyntaxVisitorContinueKind {
		return visitAny(node._syntaxNode, "PoundAssertStmt")
	}

	override open func visitPost(_ node: PoundAssertStmtSyntax) {
		visitAnyPost(node._syntaxNode)
	}
	override open func visit(_ node: GenericWhereClauseSyntax) -> SyntaxVisitorContinueKind {
		return visitAny(node._syntaxNode, "GenericWhereClause")
	}

	override open func visitPost(_ node: GenericWhereClauseSyntax) {
		visitAnyPost(node._syntaxNode)
	}
	override open func visit(_ node: GenericRequirementListSyntax) -> SyntaxVisitorContinueKind {
		return visitAny(node._syntaxNode, "GenericRequirementList")
	}

	override open func visitPost(_ node: GenericRequirementListSyntax) {
		visitAnyPost(node._syntaxNode)
	}
	override open func visit(_ node: GenericRequirementSyntax) -> SyntaxVisitorContinueKind {
		return visitAny(node._syntaxNode, "GenericRequirement")
	}

	override open func visitPost(_ node: GenericRequirementSyntax) {
		visitAnyPost(node._syntaxNode)
	}
	override open func visit(_ node: SameTypeRequirementSyntax) -> SyntaxVisitorContinueKind {
		return visitAny(node._syntaxNode, "SameTypeRequirement")
	}

	override open func visitPost(_ node: SameTypeRequirementSyntax) {
		visitAnyPost(node._syntaxNode)
	}
	override open func visit(_ node: GenericParameterListSyntax) -> SyntaxVisitorContinueKind {
		return visitAny(node._syntaxNode, "GenericParameterList")
	}

	override open func visitPost(_ node: GenericParameterListSyntax) {
		visitAnyPost(node._syntaxNode)
	}
	override open func visit(_ node: GenericParameterSyntax) -> SyntaxVisitorContinueKind {
		return visitAny(node._syntaxNode, "GenericParameter")
	}

	override open func visitPost(_ node: GenericParameterSyntax) {
		visitAnyPost(node._syntaxNode)
	}
	override open func visit(_ node: GenericParameterClauseSyntax) -> SyntaxVisitorContinueKind {
		return visitAny(node._syntaxNode, "GenericParameterClause")
	}

	override open func visitPost(_ node: GenericParameterClauseSyntax) {
		visitAnyPost(node._syntaxNode)
	}
	override open func visit(_ node: ConformanceRequirementSyntax) -> SyntaxVisitorContinueKind {
		return visitAny(node._syntaxNode, "ConformanceRequirement")
	}

	override open func visitPost(_ node: ConformanceRequirementSyntax) {
		visitAnyPost(node._syntaxNode)
	}
	override open func visit(_ node: SimpleTypeIdentifierSyntax) -> SyntaxVisitorContinueKind {
		return visitAny(node._syntaxNode, "SimpleTypeIdentifier")
	}

	override open func visitPost(_ node: SimpleTypeIdentifierSyntax) {
		visitAnyPost(node._syntaxNode)
	}
	override open func visit(_ node: MemberTypeIdentifierSyntax) -> SyntaxVisitorContinueKind {
		return visitAny(node._syntaxNode, "MemberTypeIdentifier")
	}

	override open func visitPost(_ node: MemberTypeIdentifierSyntax) {
		visitAnyPost(node._syntaxNode)
	}
	override open func visit(_ node: ClassRestrictionTypeSyntax) -> SyntaxVisitorContinueKind {
		return visitAny(node._syntaxNode, "ClassRestrictionType")
	}

	override open func visitPost(_ node: ClassRestrictionTypeSyntax) {
		visitAnyPost(node._syntaxNode)
	}
	override open func visit(_ node: ArrayTypeSyntax) -> SyntaxVisitorContinueKind {
		return visitAny(node._syntaxNode, "ArrayType")
	}

	override open func visitPost(_ node: ArrayTypeSyntax) {
		visitAnyPost(node._syntaxNode)
	}
	override open func visit(_ node: DictionaryTypeSyntax) -> SyntaxVisitorContinueKind {
		return visitAny(node._syntaxNode, "DictionaryType")
	}

	override open func visitPost(_ node: DictionaryTypeSyntax) {
		visitAnyPost(node._syntaxNode)
	}
	override open func visit(_ node: MetatypeTypeSyntax) -> SyntaxVisitorContinueKind {
		return visitAny(node._syntaxNode, "MetatypeType")
	}

	override open func visitPost(_ node: MetatypeTypeSyntax) {
		visitAnyPost(node._syntaxNode)
	}
	override open func visit(_ node: OptionalTypeSyntax) -> SyntaxVisitorContinueKind {
		return visitAny(node._syntaxNode, "OptionalType")
	}

	override open func visitPost(_ node: OptionalTypeSyntax) {
		visitAnyPost(node._syntaxNode)
	}
	override open func visit(_ node: SomeTypeSyntax) -> SyntaxVisitorContinueKind {
		return visitAny(node._syntaxNode, "SomeType")
	}

	override open func visitPost(_ node: SomeTypeSyntax) {
		visitAnyPost(node._syntaxNode)
	}
	override open func visit(_ node: ImplicitlyUnwrappedOptionalTypeSyntax) -> SyntaxVisitorContinueKind {
		return visitAny(node._syntaxNode, "ImplicitlyUnwrappedOptionalType")
	}

	override open func visitPost(_ node: ImplicitlyUnwrappedOptionalTypeSyntax) {
		visitAnyPost(node._syntaxNode)
	}
	override open func visit(_ node: CompositionTypeElementSyntax) -> SyntaxVisitorContinueKind {
		return visitAny(node._syntaxNode, "CompositionTypeElement")
	}

	override open func visitPost(_ node: CompositionTypeElementSyntax) {
		visitAnyPost(node._syntaxNode)
	}
	override open func visit(_ node: CompositionTypeElementListSyntax) -> SyntaxVisitorContinueKind {
		return visitAny(node._syntaxNode, "CompositionTypeElementList")
	}

	override open func visitPost(_ node: CompositionTypeElementListSyntax) {
		visitAnyPost(node._syntaxNode)
	}
	override open func visit(_ node: CompositionTypeSyntax) -> SyntaxVisitorContinueKind {
		return visitAny(node._syntaxNode, "CompositionType")
	}

	override open func visitPost(_ node: CompositionTypeSyntax) {
		visitAnyPost(node._syntaxNode)
	}
	override open func visit(_ node: TupleTypeElementSyntax) -> SyntaxVisitorContinueKind {
		return visitAny(node._syntaxNode, "TupleTypeElement")
	}

	override open func visitPost(_ node: TupleTypeElementSyntax) {
		visitAnyPost(node._syntaxNode)
	}
	override open func visit(_ node: TupleTypeElementListSyntax) -> SyntaxVisitorContinueKind {
		return visitAny(node._syntaxNode, "TupleTypeElementList")
	}

	override open func visitPost(_ node: TupleTypeElementListSyntax) {
		visitAnyPost(node._syntaxNode)
	}
	override open func visit(_ node: TupleTypeSyntax) -> SyntaxVisitorContinueKind {
		return visitAny(node._syntaxNode, "TupleType")
	}

	override open func visitPost(_ node: TupleTypeSyntax) {
		visitAnyPost(node._syntaxNode)
	}
	override open func visit(_ node: FunctionTypeSyntax) -> SyntaxVisitorContinueKind {
		return visitAny(node._syntaxNode, "FunctionType")
	}

	override open func visitPost(_ node: FunctionTypeSyntax) {
		visitAnyPost(node._syntaxNode)
	}
	override open func visit(_ node: AttributedTypeSyntax) -> SyntaxVisitorContinueKind {
		return visitAny(node._syntaxNode, "AttributedType")
	}

	override open func visitPost(_ node: AttributedTypeSyntax) {
		visitAnyPost(node._syntaxNode)
	}
	override open func visit(_ node: GenericArgumentListSyntax) -> SyntaxVisitorContinueKind {
		return visitAny(node._syntaxNode, "GenericArgumentList")
	}

	override open func visitPost(_ node: GenericArgumentListSyntax) {
		visitAnyPost(node._syntaxNode)
	}
	override open func visit(_ node: GenericArgumentSyntax) -> SyntaxVisitorContinueKind {
		return visitAny(node._syntaxNode, "GenericArgument")
	}

	override open func visitPost(_ node: GenericArgumentSyntax) {
		visitAnyPost(node._syntaxNode)
	}
	override open func visit(_ node: GenericArgumentClauseSyntax) -> SyntaxVisitorContinueKind {
		return visitAny(node._syntaxNode, "GenericArgumentClause")
	}

	override open func visitPost(_ node: GenericArgumentClauseSyntax) {
		visitAnyPost(node._syntaxNode)
	}
	override open func visit(_ node: TypeAnnotationSyntax) -> SyntaxVisitorContinueKind {
		return visitAny(node._syntaxNode, "TypeAnnotation")
	}

	override open func visitPost(_ node: TypeAnnotationSyntax) {
		visitAnyPost(node._syntaxNode)
	}
	override open func visit(_ node: EnumCasePatternSyntax) -> SyntaxVisitorContinueKind {
		return visitAny(node._syntaxNode, "EnumCasePattern")
	}

	override open func visitPost(_ node: EnumCasePatternSyntax) {
		visitAnyPost(node._syntaxNode)
	}
	override open func visit(_ node: IsTypePatternSyntax) -> SyntaxVisitorContinueKind {
		return visitAny(node._syntaxNode, "IsTypePattern")
	}

	override open func visitPost(_ node: IsTypePatternSyntax) {
		visitAnyPost(node._syntaxNode)
	}
	override open func visit(_ node: OptionalPatternSyntax) -> SyntaxVisitorContinueKind {
		return visitAny(node._syntaxNode, "OptionalPattern")
	}

	override open func visitPost(_ node: OptionalPatternSyntax) {
		visitAnyPost(node._syntaxNode)
	}
	override open func visit(_ node: IdentifierPatternSyntax) -> SyntaxVisitorContinueKind {
		return visitAny(node._syntaxNode, "IdentifierPattern")
	}

	override open func visitPost(_ node: IdentifierPatternSyntax) {
		visitAnyPost(node._syntaxNode)
	}
	override open func visit(_ node: AsTypePatternSyntax) -> SyntaxVisitorContinueKind {
		return visitAny(node._syntaxNode, "AsTypePattern")
	}

	override open func visitPost(_ node: AsTypePatternSyntax) {
		visitAnyPost(node._syntaxNode)
	}
	override open func visit(_ node: TuplePatternSyntax) -> SyntaxVisitorContinueKind {
		return visitAny(node._syntaxNode, "TuplePattern")
	}

	override open func visitPost(_ node: TuplePatternSyntax) {
		visitAnyPost(node._syntaxNode)
	}
	override open func visit(_ node: WildcardPatternSyntax) -> SyntaxVisitorContinueKind {
		return visitAny(node._syntaxNode, "WildcardPattern")
	}

	override open func visitPost(_ node: WildcardPatternSyntax) {
		visitAnyPost(node._syntaxNode)
	}
	override open func visit(_ node: TuplePatternElementSyntax) -> SyntaxVisitorContinueKind {
		return visitAny(node._syntaxNode, "TuplePatternElement")
	}

	override open func visitPost(_ node: TuplePatternElementSyntax) {
		visitAnyPost(node._syntaxNode)
	}
	override open func visit(_ node: ExpressionPatternSyntax) -> SyntaxVisitorContinueKind {
		return visitAny(node._syntaxNode, "ExpressionPattern")
	}

	override open func visitPost(_ node: ExpressionPatternSyntax) {
		visitAnyPost(node._syntaxNode)
	}
	override open func visit(_ node: TuplePatternElementListSyntax) -> SyntaxVisitorContinueKind {
		return visitAny(node._syntaxNode, "TuplePatternElementList")
	}

	override open func visitPost(_ node: TuplePatternElementListSyntax) {
		visitAnyPost(node._syntaxNode)
	}
	override open func visit(_ node: ValueBindingPatternSyntax) -> SyntaxVisitorContinueKind {
		return visitAny(node._syntaxNode, "ValueBindingPattern")
	}

	override open func visitPost(_ node: ValueBindingPatternSyntax) {
		visitAnyPost(node._syntaxNode)
	}
	override open func visit(_ node: AvailabilitySpecListSyntax) -> SyntaxVisitorContinueKind {
		return visitAny(node._syntaxNode, "AvailabilitySpecList")
	}

	override open func visitPost(_ node: AvailabilitySpecListSyntax) {
		visitAnyPost(node._syntaxNode)
	}
	override open func visit(_ node: AvailabilityArgumentSyntax) -> SyntaxVisitorContinueKind {
		return visitAny(node._syntaxNode, "AvailabilityArgument")
	}

	override open func visitPost(_ node: AvailabilityArgumentSyntax) {
		visitAnyPost(node._syntaxNode)
	}
	override open func visit(_ node: AvailabilityLabeledArgumentSyntax) -> SyntaxVisitorContinueKind {
		return visitAny(node._syntaxNode, "AvailabilityLabeledArgument")
	}

	override open func visitPost(_ node: AvailabilityLabeledArgumentSyntax) {
		visitAnyPost(node._syntaxNode)
	}
	override open func visit(_ node: AvailabilityVersionRestrictionSyntax) -> SyntaxVisitorContinueKind {
		return visitAny(node._syntaxNode, "AvailabilityVersionRestriction")
	}

	override open func visitPost(_ node: AvailabilityVersionRestrictionSyntax) {
		visitAnyPost(node._syntaxNode)
	}
	override open func visit(_ node: VersionTupleSyntax) -> SyntaxVisitorContinueKind {
		return visitAny(node._syntaxNode, "VersionTuple")
	}

	override open func visitPost(_ node: VersionTupleSyntax) {
		visitAnyPost(node._syntaxNode)
	}
}
