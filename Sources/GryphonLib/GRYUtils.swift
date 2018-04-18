import Foundation

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

extension Utils {
	private static func fileNameAndEscapedFilePath(from filePath: String) -> (fileName: String, escapedFilePath: String) {
		// Get the only file name from the path and drop the ".swift" extension
		let fileName = String(URL(fileURLWithPath: filePath).lastPathComponent.dropLast(6))
		// JSON escapes '/'s in file paths
		let escapedFilePath = filePath.replacingOccurrences(of: "/", with: "\\/")
		return (fileName, escapedFilePath)
	}
	
	internal static func insertPlaceholders(in string: String, forFilePath filePath: String) -> String {
		let (fileName, escapedFilePath) = fileNameAndEscapedFilePath(from: filePath)
		
		let processedString = string
			.replacingOccurrences(of: escapedFilePath, with: "##testPath##")
			.replacingOccurrences(of: fileName, with: "##testFileName##")
		return processedString
	}
	
	internal static func replacePlaceholders(in string: String, withFilePath filePath: String) -> String {
		let (fileName, escapedFilePath) = fileNameAndEscapedFilePath(from: filePath)
		
		let processedString = string
			.replacingOccurrences(of: "##testPath##", with: escapedFilePath)
			.replacingOccurrences(of: "##testFileName##", with: fileName)
		return processedString
	}
}

/////////////////////////////////////////////

extension Utils {
	static var rng: RandomGenerator = Xoroshiro()
}

extension RandomGenerator {
	mutating func random(_ range: Range<Int>) -> Int {
		let rangeSize = range.upperBound - range.lowerBound
		let randomNumber = Int(random32()) % rangeSize
		return range.lowerBound + randomNumber
	}
	
	mutating func random(_ range: ClosedRange<Int>) -> Int {
		let rangeSize = range.upperBound - range.lowerBound + 1
		let randomNumber = Int(random32()) % rangeSize
		return range.lowerBound + randomNumber
	}
	
	mutating func randomBool() -> Bool {
		return random(0...1) == 0
	}
}

/////////////////////////////////////////////
extension RandomAccessCollection where Index == Int {
	func randomElement() -> Element {
		let index = Utils.rng.random(0..<count)
		return self[index]
	}
}

extension RandomAccessCollection where Element: Equatable, Index == Int {
	func distinctRandomElements() -> (Element, Element) {
		precondition(count > 1)
		let first = randomElement()
		while true {
			let second = randomElement()
			if second != first {
				return (first, second)
			}
		}
	}
}
