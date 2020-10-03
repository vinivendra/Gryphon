import SwiftSyntax

extension SyntaxProtocol {
	func toPrintableTree() -> PrintableTree {
		return SwiftSyntaxToPrintableTreeVisitor().convertToPrintableTree(Syntax(self))
	}

	func prettyPrint() {
		self.toPrintableTree().prettyPrint()
	}

	func prettyDescription() -> String {
		return self.toPrintableTree().prettyDescription()
	}
}

open class SwiftSyntaxToPrintableTreeVisitor: SyntaxVisitor {
	func convertToPrintableTree(_ node: Syntax) -> PrintableTree {
		let logInfo = Log.startLog(name: "Converting SS for printing")
		defer { Log.endLog(info: logInfo) }
		return self.visit(node)
	}

	open func visit(_ node: Syntax) -> PrintableTree {
		let subtrees: MutableList<PrintableAsTree?> = []
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
			subtrees.append(PrintableTree("\(property.label ?? "_") -> \(escapedValue)"))
		}

		let children = node.children.map { visit($0) }

		subtrees.append(contentsOf: children)

		let name = node.getName() ?? "Unknown Syntax"
		return PrintableTree(name, subtrees)
	}
}

extension Syntax {
	func getName() -> String? {
		if self.is(TokenSyntax.self)
			{ return "Token" }
		else if self.is(UnknownSyntax.self)
			{ return "Unknown" }
		else if self.is(UnknownDeclSyntax.self)
			{ return "Unknown Declaration" }
		else if self.is(UnknownExprSyntax.self)
			{ return "Unknown Expression" }
		else if self.is(UnknownStmtSyntax.self)
			{ return "Unknown Statement" }
		else if self.is(UnknownTypeSyntax.self)
			{ return "Unknown Type" }
		else if self.is(UnknownPatternSyntax.self)
			{ return "Unknown Pattern" }
		else if self.is(CodeBlockItemSyntax.self)
			{ return "Code Block Item" }
		else if self.is(CodeBlockItemListSyntax.self)
			{ return "Code Block Item List" }
		else if self.is(CodeBlockSyntax.self)
			{ return "Code Block" }
		else if self.is(InOutExprSyntax.self)
			{ return "In Out Expression" }
		else if self.is(PoundColumnExprSyntax.self)
			{ return "Pound Column Expression" }
		else if self.is(TupleExprElementListSyntax.self)
			{ return "Tuple Expr Element List" }
		else if self.is(ArrayElementListSyntax.self)
			{ return "Array Element List" }
		else if self.is(DictionaryElementListSyntax.self)
			{ return "Dictionary Element List" }
		else if self.is(StringLiteralSegmentsSyntax.self)
			{ return "String Literal Segments" }
		else if self.is(TryExprSyntax.self)
			{ return "Try Expression" }
		else if self.is(DeclNameArgumentSyntax.self)
			{ return "Decl Name Argument" }
		else if self.is(DeclNameArgumentListSyntax.self)
			{ return "Decl Name Argument List" }
		else if self.is(DeclNameArgumentsSyntax.self)
			{ return "Decl Name Arguments" }
		else if self.is(IdentifierExprSyntax.self)
			{ return "Identifier Expression" }
		else if self.is(SuperRefExprSyntax.self)
			{ return "Super Ref Expression" }
		else if self.is(NilLiteralExprSyntax.self)
			{ return "Nil Literal Expression" }
		else if self.is(DiscardAssignmentExprSyntax.self)
			{ return "Discard Assignment Expression" }
		else if self.is(AssignmentExprSyntax.self)
			{ return "Assignment Expression" }
		else if self.is(SequenceExprSyntax.self)
			{ return "Sequence Expression" }
		else if self.is(ExprListSyntax.self)
			{ return "Expr List" }
		else if self.is(PoundLineExprSyntax.self)
			{ return "Pound Line Expression" }
		else if self.is(PoundFileExprSyntax.self)
			{ return "Pound File Expression" }
		else if self.is(PoundFilePathExprSyntax.self)
			{ return "Pound File Path Expression" }
		else if self.is(PoundFunctionExprSyntax.self)
			{ return "Pound Function Expression" }
		else if self.is(PoundDsohandleExprSyntax.self)
			{ return "Pound Dsohandle Expression" }
		else if self.is(SymbolicReferenceExprSyntax.self)
			{ return "Symbolic Reference Expression" }
		else if self.is(PrefixOperatorExprSyntax.self)
			{ return "Prefix Operator Expression" }
		else if self.is(BinaryOperatorExprSyntax.self)
			{ return "Binary Operator Expression" }
		else if self.is(ArrowExprSyntax.self)
			{ return "Arrow Expression" }
		else if self.is(FloatLiteralExprSyntax.self)
			{ return "Float Literal Expression" }
		else if self.is(TupleExprSyntax.self)
			{ return "Tuple Expression" }
		else if self.is(ArrayExprSyntax.self)
			{ return "Array Expression" }
		else if self.is(DictionaryExprSyntax.self)
			{ return "Dictionary Expression" }
		else if self.is(TupleExprElementSyntax.self)
			{ return "Tuple Expr Element" }
		else if self.is(ArrayElementSyntax.self)
			{ return "Array Element" }
		else if self.is(DictionaryElementSyntax.self)
			{ return "Dictionary Element" }
		else if self.is(IntegerLiteralExprSyntax.self)
			{ return "Integer Literal Expression" }
		else if self.is(BooleanLiteralExprSyntax.self)
			{ return "Boolean Literal Expression" }
		else if self.is(TernaryExprSyntax.self)
			{ return "Ternary Expression" }
		else if self.is(MemberAccessExprSyntax.self)
			{ return "Member Access Expression" }
		else if self.is(IsExprSyntax.self)
			{ return "Is Expression" }
		else if self.is(AsExprSyntax.self)
			{ return "As Expression" }
		else if self.is(TypeExprSyntax.self)
			{ return "Type Expression" }
		else if self.is(ClosureCaptureItemSyntax.self)
			{ return "Closure Capture Item" }
		else if self.is(ClosureCaptureItemListSyntax.self)
			{ return "Closure Capture Item List" }
		else if self.is(ClosureCaptureSignatureSyntax.self)
			{ return "Closure Capture Signature" }
		else if self.is(ClosureParamSyntax.self)
			{ return "Closure Param" }
		else if self.is(ClosureParamListSyntax.self)
			{ return "Closure Param List" }
		else if self.is(ClosureSignatureSyntax.self)
			{ return "Closure Signature" }
		else if self.is(ClosureExprSyntax.self)
			{ return "Closure Expression" }
		else if self.is(UnresolvedPatternExprSyntax.self)
			{ return "Unresolved Pattern Expression" }
		else if self.is(FunctionCallExprSyntax.self)
			{ return "Function Call Expression" }
		else if self.is(SubscriptExprSyntax.self)
			{ return "Subscript Expression" }
		else if self.is(OptionalChainingExprSyntax.self)
			{ return "Optional Chaining Expression" }
		else if self.is(ForcedValueExprSyntax.self)
			{ return "Forced Value Expression" }
		else if self.is(PostfixUnaryExprSyntax.self)
			{ return "Postfix Unary Expression" }
		else if self.is(SpecializeExprSyntax.self)
			{ return "Specialize Expression" }
		else if self.is(StringSegmentSyntax.self)
			{ return "String Segment" }
		else if self.is(ExpressionSegmentSyntax.self)
			{ return "Expression Segment" }
		else if self.is(StringLiteralExprSyntax.self)
			{ return "String Literal Expression" }
		else if self.is(KeyPathExprSyntax.self)
			{ return "Key Path Expression" }
		else if self.is(KeyPathBaseExprSyntax.self)
			{ return "Key Path Base Expression" }
		else if self.is(ObjcNamePieceSyntax.self)
			{ return "Objc Name Piece" }
		else if self.is(ObjcNameSyntax.self)
			{ return "Objc Name" }
		else if self.is(ObjcKeyPathExprSyntax.self)
			{ return "Objc Key Path Expression" }
		else if self.is(ObjcSelectorExprSyntax.self)
			{ return "Objc Selector Expression" }
		else if self.is(EditorPlaceholderExprSyntax.self)
			{ return "Editor Placeholder Expression" }
		else if self.is(ObjectLiteralExprSyntax.self)
			{ return "Object Literal Expression" }
		else if self.is(TypeInitializerClauseSyntax.self)
			{ return "Type Initializer Clause" }
		else if self.is(TypealiasDeclSyntax.self)
			{ return "Typealias Declaration" }
		else if self.is(AssociatedtypeDeclSyntax.self)
			{ return "Associatedtype Declaration" }
		else if self.is(FunctionParameterListSyntax.self)
			{ return "Function Parameter List" }
		else if self.is(ParameterClauseSyntax.self)
			{ return "Parameter Clause" }
		else if self.is(ReturnClauseSyntax.self)
			{ return "Return Clause" }
		else if self.is(FunctionSignatureSyntax.self)
			{ return "Function Signature" }
		else if self.is(IfConfigClauseSyntax.self)
			{ return "If Config Clause" }
		else if self.is(IfConfigClauseListSyntax.self)
			{ return "If Config Clause List" }
		else if self.is(IfConfigDeclSyntax.self)
			{ return "If Config Declaration" }
		else if self.is(PoundErrorDeclSyntax.self)
			{ return "Pound Error Declaration" }
		else if self.is(PoundWarningDeclSyntax.self)
			{ return "Pound Warning Declaration" }
		else if self.is(PoundSourceLocationSyntax.self)
			{ return "Pound Source Location" }
		else if self.is(PoundSourceLocationArgsSyntax.self)
			{ return "Pound Source Location Args" }
		else if self.is(DeclModifierSyntax.self)
			{ return "Decl Modifier" }
		else if self.is(InheritedTypeSyntax.self)
			{ return "Inherited Type" }
		else if self.is(InheritedTypeListSyntax.self)
			{ return "Inherited Type List" }
		else if self.is(TypeInheritanceClauseSyntax.self)
			{ return "Type Inheritance Clause" }
		else if self.is(ClassDeclSyntax.self)
			{ return "Class Declaration" }
		else if self.is(StructDeclSyntax.self)
			{ return "Struct Declaration" }
		else if self.is(ProtocolDeclSyntax.self)
			{ return "Protocol Declaration" }
		else if self.is(ExtensionDeclSyntax.self)
			{ return "Extension Declaration" }
		else if self.is(MemberDeclBlockSyntax.self)
			{ return "Member Decl Block" }
		else if self.is(MemberDeclListSyntax.self)
			{ return "Member Decl List" }
		else if self.is(MemberDeclListItemSyntax.self)
			{ return "Member Decl List Item" }
		else if self.is(SourceFileSyntax.self)
			{ return "Source File" }
		else if self.is(InitializerClauseSyntax.self)
			{ return "Initializer Clause" }
		else if self.is(FunctionParameterSyntax.self)
			{ return "Function Parameter" }
		else if self.is(ModifierListSyntax.self)
			{ return "Modifier List" }
		else if self.is(FunctionDeclSyntax.self)
			{ return "Function Declaration" }
		else if self.is(InitializerDeclSyntax.self)
			{ return "Initializer Declaration" }
		else if self.is(DeinitializerDeclSyntax.self)
			{ return "Deinitializer Declaration" }
		else if self.is(SubscriptDeclSyntax.self)
			{ return "Subscript Declaration" }
		else if self.is(AccessLevelModifierSyntax.self)
			{ return "Access Level Modifier" }
		else if self.is(AccessPathComponentSyntax.self)
			{ return "Access Path Component" }
		else if self.is(AccessPathSyntax.self)
			{ return "Access Path" }
		else if self.is(ImportDeclSyntax.self)
			{ return "Import Declaration" }
		else if self.is(AccessorParameterSyntax.self)
			{ return "Accessor Parameter" }
		else if self.is(AccessorDeclSyntax.self)
			{ return "Accessor Declaration" }
		else if self.is(AccessorListSyntax.self)
			{ return "Accessor List" }
		else if self.is(AccessorBlockSyntax.self)
			{ return "Accessor Block" }
		else if self.is(PatternBindingSyntax.self)
			{ return "Pattern Binding" }
		else if self.is(PatternBindingListSyntax.self)
			{ return "Pattern Binding List" }
		else if self.is(VariableDeclSyntax.self)
			{ return "Variable Declaration" }
		else if self.is(EnumCaseElementSyntax.self)
			{ return "Enum Case Element" }
		else if self.is(EnumCaseElementListSyntax.self)
			{ return "Enum Case Element List" }
		else if self.is(EnumCaseDeclSyntax.self)
			{ return "Enum Case Declaration" }
		else if self.is(EnumDeclSyntax.self)
			{ return "Enum Declaration" }
		else if self.is(OperatorDeclSyntax.self)
			{ return "Operator Declaration" }
		else if self.is(IdentifierListSyntax.self)
			{ return "Identifier List" }
		else if self.is(OperatorPrecedenceAndTypesSyntax.self)
			{ return "Operator Precedence And Types" }
		else if self.is(PrecedenceGroupDeclSyntax.self)
			{ return "Precedence Group Declaration" }
		else if self.is(PrecedenceGroupAttributeListSyntax.self)
			{ return "Precedence Group Attribute List" }
		else if self.is(PrecedenceGroupRelationSyntax.self)
			{ return "Precedence Group Relation" }
		else if self.is(PrecedenceGroupNameListSyntax.self)
			{ return "Precedence Group Name List" }
		else if self.is(PrecedenceGroupNameElementSyntax.self)
			{ return "Precedence Group Name Element" }
		else if self.is(PrecedenceGroupAssignmentSyntax.self)
			{ return "Precedence Group Assignment" }
		else if self.is(PrecedenceGroupAssociativitySyntax.self)
			{ return "Precedence Group Associativity" }
		else if self.is(TokenListSyntax.self)
			{ return "Token List" }
		else if self.is(NonEmptyTokenListSyntax.self)
			{ return "Non Empty Token List" }
		else if self.is(CustomAttributeSyntax.self)
			{ return "Custom Attribute" }
		else if self.is(AttributeSyntax.self)
			{ return "Attribute" }
		else if self.is(AttributeListSyntax.self)
			{ return "Attribute List" }
		else if self.is(SpecializeAttributeSpecListSyntax.self)
			{ return "Specialize Attribute Spec List" }
		else if self.is(LabeledSpecializeEntrySyntax.self)
			{ return "Labeled Specialize Entry" }
		else if self.is(NamedAttributeStringArgumentSyntax.self)
			{ return "Named Attribute String Argument" }
		else if self.is(DeclNameSyntax.self)
			{ return "Decl Name" }
		else if self.is(ImplementsAttributeArgumentsSyntax.self)
			{ return "Implements Attribute Arguments" }
		else if self.is(ObjCSelectorPieceSyntax.self)
			{ return "Obj CSelector Piece" }
		else if self.is(ObjCSelectorSyntax.self)
			{ return "Obj CSelector" }
		else if self.is(DifferentiableAttributeArgumentsSyntax.self)
			{ return "Differentiable Attribute Arguments" }
		else if self.is(DifferentiationParamsClauseSyntax.self)
			{ return "Differentiation Params Clause" }
		else if self.is(DifferentiationParamsSyntax.self)
			{ return "Differentiation Params" }
		else if self.is(DifferentiationParamListSyntax.self)
			{ return "Differentiation Param List" }
		else if self.is(DifferentiationParamSyntax.self)
			{ return "Differentiation Param" }
		else if self.is(DifferentiableAttributeFuncSpecifierSyntax.self)
			{ return "Differentiable Attribute Func Specifier" }
		else if self.is(FunctionDeclNameSyntax.self)
			{ return "Function Decl Name" }
		else if self.is(ContinueStmtSyntax.self)
			{ return "Continue Statement" }
		else if self.is(WhileStmtSyntax.self)
			{ return "While Statement" }
		else if self.is(DeferStmtSyntax.self)
			{ return "Defer Statement" }
		else if self.is(ExpressionStmtSyntax.self)
			{ return "Expression Statement" }
		else if self.is(SwitchCaseListSyntax.self)
			{ return "Switch Case List" }
		else if self.is(RepeatWhileStmtSyntax.self)
			{ return "Repeat While Statement" }
		else if self.is(GuardStmtSyntax.self)
			{ return "Guard Statement" }
		else if self.is(WhereClauseSyntax.self)
			{ return "Where Clause" }
		else if self.is(ForInStmtSyntax.self)
			{ return "For In Statement" }
		else if self.is(SwitchStmtSyntax.self)
			{ return "Switch Statement" }
		else if self.is(CatchClauseListSyntax.self)
			{ return "Catch Clause List" }
		else if self.is(DoStmtSyntax.self)
			{ return "Do Statement" }
		else if self.is(ReturnStmtSyntax.self)
			{ return "Return Statement" }
		else if self.is(YieldStmtSyntax.self)
			{ return "Yield Statement" }
		else if self.is(YieldListSyntax.self)
			{ return "Yield List" }
		else if self.is(FallthroughStmtSyntax.self)
			{ return "Fallthrough Statement" }
		else if self.is(BreakStmtSyntax.self)
			{ return "Break Statement" }
		else if self.is(CaseItemListSyntax.self)
			{ return "Case Item List" }
		else if self.is(ConditionElementSyntax.self)
			{ return "Condition Element" }
		else if self.is(AvailabilityConditionSyntax.self)
			{ return "Availability Condition" }
		else if self.is(MatchingPatternConditionSyntax.self)
			{ return "Matching Pattern Condition" }
		else if self.is(OptionalBindingConditionSyntax.self)
			{ return "Optional Binding Condition" }
		else if self.is(ConditionElementListSyntax.self)
			{ return "Condition Element List" }
		else if self.is(DeclarationStmtSyntax.self)
			{ return "Declaration Statement" }
		else if self.is(ThrowStmtSyntax.self)
			{ return "Throw Statement" }
		else if self.is(IfStmtSyntax.self)
			{ return "If Statement" }
		else if self.is(ElseIfContinuationSyntax.self)
			{ return "Else If Continuation" }
		else if self.is(ElseBlockSyntax.self)
			{ return "Else Block" }
		else if self.is(SwitchCaseSyntax.self)
			{ return "Switch Case" }
		else if self.is(SwitchDefaultLabelSyntax.self)
			{ return "Switch Default Label" }
		else if self.is(CaseItemSyntax.self)
			{ return "Case Item" }
		else if self.is(SwitchCaseLabelSyntax.self)
			{ return "Switch Case Label" }
		else if self.is(CatchClauseSyntax.self)
			{ return "Catch Clause" }
		else if self.is(PoundAssertStmtSyntax.self)
			{ return "Pound Assert Statement" }
		else if self.is(GenericWhereClauseSyntax.self)
			{ return "Generic Where Clause" }
		else if self.is(GenericRequirementListSyntax.self)
			{ return "Generic Requirement List" }
		else if self.is(GenericRequirementSyntax.self)
			{ return "Generic Requirement" }
		else if self.is(SameTypeRequirementSyntax.self)
			{ return "Same Type Requirement" }
		else if self.is(GenericParameterListSyntax.self)
			{ return "Generic Parameter List" }
		else if self.is(GenericParameterSyntax.self)
			{ return "Generic Parameter" }
		else if self.is(GenericParameterClauseSyntax.self)
			{ return "Generic Parameter Clause" }
		else if self.is(ConformanceRequirementSyntax.self)
			{ return "Conformance Requirement" }
		else if self.is(SimpleTypeIdentifierSyntax.self)
			{ return "Simple Type Identifier" }
		else if self.is(MemberTypeIdentifierSyntax.self)
			{ return "Member Type Identifier" }
		else if self.is(ClassRestrictionTypeSyntax.self)
			{ return "Class Restriction Type" }
		else if self.is(ArrayTypeSyntax.self)
			{ return "Array Type" }
		else if self.is(DictionaryTypeSyntax.self)
			{ return "Dictionary Type" }
		else if self.is(MetatypeTypeSyntax.self)
			{ return "Metatype Type" }
		else if self.is(OptionalTypeSyntax.self)
			{ return "Optional Type" }
		else if self.is(SomeTypeSyntax.self)
			{ return "Some Type" }
		else if self.is(ImplicitlyUnwrappedOptionalTypeSyntax.self)
			{ return "Implicitly Unwrapped Optional Type" }
		else if self.is(CompositionTypeElementSyntax.self)
			{ return "Composition Type Element" }
		else if self.is(CompositionTypeElementListSyntax.self)
			{ return "Composition Type Element List" }
		else if self.is(CompositionTypeSyntax.self)
			{ return "Composition Type" }
		else if self.is(TupleTypeElementSyntax.self)
			{ return "Tuple Type Element" }
		else if self.is(TupleTypeElementListSyntax.self)
			{ return "Tuple Type Element List" }
		else if self.is(TupleTypeSyntax.self)
			{ return "Tuple Type" }
		else if self.is(FunctionTypeSyntax.self)
			{ return "Function Type" }
		else if self.is(AttributedTypeSyntax.self)
			{ return "Attributed Type" }
		else if self.is(GenericArgumentListSyntax.self)
			{ return "Generic Argument List" }
		else if self.is(GenericArgumentSyntax.self)
			{ return "Generic Argument" }
		else if self.is(GenericArgumentClauseSyntax.self)
			{ return "Generic Argument Clause" }
		else if self.is(TypeAnnotationSyntax.self)
			{ return "Type Annotation" }
		else if self.is(EnumCasePatternSyntax.self)
			{ return "Enum Case Pattern" }
		else if self.is(IsTypePatternSyntax.self)
			{ return "Is Type Pattern" }
		else if self.is(OptionalPatternSyntax.self)
			{ return "Optional Pattern" }
		else if self.is(IdentifierPatternSyntax.self)
			{ return "Identifier Pattern" }
		else if self.is(AsTypePatternSyntax.self)
			{ return "As Type Pattern" }
		else if self.is(TuplePatternSyntax.self)
			{ return "Tuple Pattern" }
		else if self.is(WildcardPatternSyntax.self)
			{ return "Wildcard Pattern" }
		else if self.is(TuplePatternElementSyntax.self)
			{ return "Tuple Pattern Element" }
		else if self.is(ExpressionPatternSyntax.self)
			{ return "Expression Pattern" }
		else if self.is(TuplePatternElementListSyntax.self)
			{ return "Tuple Pattern Element List" }
		else if self.is(ValueBindingPatternSyntax.self)
			{ return "Value Binding Pattern" }
		else if self.is(AvailabilitySpecListSyntax.self)
			{ return "Availability Spec List" }
		else if self.is(AvailabilityArgumentSyntax.self)
			{ return "Availability Argument" }
		else if self.is(AvailabilityLabeledArgumentSyntax.self)
			{ return "Availability Labeled Argument" }
		else if self.is(AvailabilityVersionRestrictionSyntax.self)
			{ return "Availability Version Restriction" }
		else if self.is(VersionTupleSyntax.self)
			{ return "Version Tuple" }
		else
			{ return nil }
	}
}
