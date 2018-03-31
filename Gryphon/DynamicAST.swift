class DynamicAST: SExpressionParseable {
    var name = ""
    var attributes = ""
    var subTrees = [DynamicAST]()
	
	required init(parser: SExpressionParser) {
		parser.readOpenParentheses()
		self.name = parser.readIdentifier()
		
		for _ in 0..<1_000 { // To avoid infinite loops
			
			if parser.canReadOpenParentheses() {
				let subTree = DynamicAST(parser: parser)
				subTrees.append(subTree)
			}
			else if parser.canReadCloseParentheses() {
				parser.readCloseParentheses()
				return
			}
			else {
				let string = parser.readIdentifierOrString()
				attributes += string
				attributes += " "
			}
		}
		
		fatalError("Error creating dynamic AST") // If the loop was infinite
	}
}

extension DynamicAST: PrintableAsTree {
    private func improveNameDescription(_ name: String) -> String {
        // Separate snake case and capitalize
        var nameComponents = name.split(separator: "_").map { $0.capitalized }
        
        // Expand swift abbreviations
        nameComponents = nameComponents.map { (word: String) -> String in
            switch word {
            case "Var": return "Variable"
            case "Ref": return "Reference"
            case "Func": return "Function"
            case "Stmt": return "Statement"
            case "Expr": return "Expression"
            case "Decl": return "Declaration"
            case "Ident": return "Identity"
            default: return word
            }
        }
        
        // Join words into a single string
        return nameComponents.joined(separator: " ")
    }
    
    var treeDescription: String {
		let improvedName = improveNameDescription(name)
		
		if attributes.isEmpty {
			return " \(improvedName)"
		}
		else {
			return " \(improvedName): \(attributes)"
		}
    }
    
    var printableSubTrees: [PrintableAsTree] {
        return subTrees
    }
}
