// TODO: Test with more complex examples (at least one with a bracketed expression, as in (I think) location and range)
// TODO: Clean SExpressionParser and old GRYAst (and Dynamic AST too)


public class GRYAst: GRYPrintableAsTree {
	let name: String
	let standaloneAttributes: [String]
	let keyValueAttributes: [String: String]
	let subTrees: [GRYAst]
	
	public convenience init(fileContents: String) {
		let parser = GRYSExpressionParser(fileContents: fileContents)
		self.init(parser: parser)
	}
	
	internal init(parser: GRYSExpressionParser) {
		var standaloneAttributes = [String]()
		var keyValueAttributes = [String: String]()
		var subTrees = [GRYAst]()
		
		parser.readOpenParentheses()
		let name = parser.readIdentifier()
		self.name = Utils.expandSwiftAbbreviation(name)
		
		var maxIterations = 1_000
		
		while !parser.canReadCloseParentheses(), maxIterations > 0 {
			defer { maxIterations -= 1 }
			
			if parser.canReadKey() {
				let key = parser.readKey()
				let value = parser.readIdentifierOrString()
				keyValueAttributes[key] = value
			}
			else if parser.canReadIdentifierOrString() {
				let attribute = parser.readIdentifierOrString()
				standaloneAttributes.append(attribute)
			}
			else if parser.canReadOpenParentheses() {
				let subTree = GRYAst(parser: parser)
				subTrees.append(subTree)
			}
		}
		
		parser.readCloseParentheses()

		guard maxIterations > 0 else {
			fatalError("Entered infinite loop!")
		}
		
		self.standaloneAttributes = standaloneAttributes
		self.keyValueAttributes = keyValueAttributes
		self.subTrees = subTrees
	}
	
	//
	public var treeDescription: String {
		return name
	}
	public var printableSubTrees: [GRYPrintableAsTree] {
		let keyValueStrings: [GRYPrintableAsTree] = keyValueAttributes.map {
			"\($0.key) → \($0.value)"
		}
		let result: [GRYPrintableAsTree] =
			(standaloneAttributes as [GRYPrintableAsTree]) +
			keyValueStrings + subTrees
		return result
	}
}
