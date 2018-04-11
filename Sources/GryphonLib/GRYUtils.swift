#if DEBUG
    let log: ((Any) -> Void)? = { (item: Any) in print(item) }
#else
    let log: ((Any) -> Void)? = nil
#endif

//
private let gryShouldLogParser = false

//
let gryParserLog = gryShouldLogParser ? log : nil

/////////////////////////////////////////////

internal enum Utils {
	internal static func expandSwiftAbbreviation(_ name: String) -> String {
		// Separate snake case and capitalize
		var nameComponents = name.split(withStringSeparator: "_").map { $0.capitalized }
		
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
}
