protocol SExpressionParseable {
	init(parser: SExpressionParser)
}

extension SExpressionParseable {
	init(fileContents: String) {
		let parser = SExpressionParser(fileContents: fileContents)
		self.init(parser: parser)
	}
}

class SExpressionParser {
	var contents: String
	var parenthesesLevel: Int = 0
	
	init(fileContents contents: String) {
		self.contents = contents
	}
	
	func canReadOpenParentheses() -> Bool {
		contents =~ "^\\s+" => ""
		return contents.prefix(1) == "("
	}
	
	func canReadCloseParentheses() -> Bool {
		contents =~ "^\\s+" => ""
		return contents.prefix(1) == ")"
	}
	
	func canReadIdentifier() -> Bool {
		contents =~ "^\\s+" => ""
		var matchIterator = contents =~ "^[^\\s\\)\\(\"']+"
		return matchIterator.next() != nil
	}
	
	func canReadDoubleQuotedString() -> Bool {
		contents =~ "^\\s+" => ""
		var matchIterator = contents =~ "^\"[^\"]+\""
		return matchIterator.next() != nil
	}
	
	func canReadSingleQuotedString() -> Bool {
		contents =~ "^\\s+" => ""
		var matchIterator = contents =~ "^'[^']+'"
		return matchIterator.next() != nil
	}
	
	//
	func readOpenParentheses() {
		contents =~ "^\\s+" => ""
		
		guard canReadOpenParentheses() else { fatalError("Parsing error") }
		
		contents.removeFirst()
		parenthesesLevel += 1

		parserLog?("-- Open parenthesis: level \(parenthesesLevel)")
	}
	
	func readCloseParentheses() {
		contents =~ "^\\s+" => ""
		
		guard canReadCloseParentheses() else { fatalError("Parsing error") }
		
		contents.removeFirst()
		parenthesesLevel -= 1
		
		parserLog?("-- Close parenthesis: level \(parenthesesLevel)")
	}
	
	func readIdentifierOrString() -> String {
		if canReadIdentifier() {
			return readIdentifier()
		}
		else if canReadDoubleQuotedString() {
			let string = readDoubleQuotedString()
			return "\"\(string)\""
		}
		else if canReadSingleQuotedString() {
			let string = readSingleQuotedString()
			return "'\(string)'"
		}
		
		fatalError("Parsing error")
	}
	
	@discardableResult
	func readIdentifier() -> String {
		contents =~ "^\\s+" => ""
		var matchIterator = contents =~ "^[^\\s\\)\\(\"']+"
		guard let match = matchIterator.next() else { fatalError("Parsing error") }
		let matchedString = match.matchedString
		parserLog?("-- Read some string: \"\(matchedString)\"")
		contents.removeFirst(matchedString.count)
		return matchedString
	}
	
	func readIdentifier(_ string: String) {
		contents =~ "^\\s+" => ""
		
		guard contents.hasPrefix(string) else { fatalError("Parsing error") }
		
		contents.removeFirst(string.count)
		
		parserLog?("-- Read string \(string)")
	}
	
	func readIdentifier(oneOf strings: [String]) -> String {
		guard let result = attemptToReadIdentifier(oneOf: strings) else { fatalError("Parsing error") }
		return result
	}
	
	func attemptToReadIdentifier(oneOf strings: [String]) -> String? {
		contents =~ "^\\s+" => ""
		
		for string in strings {
			if contents.hasPrefix(string) {
				contents.removeFirst(string.count)
				parserLog?("-- Read from array \(string)")
				return string
			}
		}
		return nil
	}

	@discardableResult
	func readDoubleQuotedString() -> String {
		contents =~ "^\\s+" => ""
		var matchIterator = contents =~ "^\"[^\"]+\""
		guard let match = matchIterator.next() else { fatalError("Parsing error") }
		let matchedString = match.matchedString
		parserLog?("-- String: \"\(matchedString)\"")
		contents.removeFirst(matchedString.count)
		let result = matchedString.dropFirst().dropLast()
		return String(result)
	}
	
	@discardableResult
	func readSingleQuotedString() -> String {
		contents =~ "^\\s+" => ""
		var matchIterator = contents =~ "^'[^']+'"
		guard let match = matchIterator.next() else { fatalError("Parsing error") }
		let matchedString = match.matchedString
		parserLog?("-- String: \"\(matchedString)\"")
		contents.removeFirst(matchedString.count)
		let result = matchedString.dropFirst().dropLast()
		return String(result)
	}
}
