internal class GRYSExpressionParser {
	var contents: String
	var parenthesesLevel: Int = 0
	
	static let knownComposedKeys = ["interface type="]
	
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
	
	func canReadIdentifierOrString() -> Bool {
		return canReadIdentifier() ||
			canReadDoubleQuotedString() ||
			canReadSingleQuotedString() ||
			canReadStringInBrackets()
	}
	
	func canReadKey() -> Bool {
		contents =~ "^\\s+" => ""
		
		// Try finding known composed keys before trying for any non-composed keys
		for composedKey in GRYSExpressionParser.knownComposedKeys {
			if contents.hasPrefix(composedKey) {
				return true
			}
		}
		
		// If no known composed keys were found
		var matchIterator = contents =~ "^[^\\s\\)\\(\"'=]+="
		return matchIterator.next() != nil
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
	
	func canReadStringInBrackets() -> Bool {
		contents =~ "^\\s+" => ""
		var matchIterator = contents =~ "^\\[[^\\]]+\\]"
		return matchIterator.next() != nil
	}
	
	//
	func readOpenParentheses() {
		contents =~ "^\\s+" => ""
		
		guard canReadOpenParentheses() else { fatalError("Parsing error") }
		
		contents.removeFirst()
		parenthesesLevel += 1

		gryParserLog?("-- Open parenthesis: level \(parenthesesLevel)")
	}
	
	func readCloseParentheses() {
		contents =~ "^\\s+" => ""
		
		guard canReadCloseParentheses() else { fatalError("Parsing error") }
		
		contents.removeFirst()
		parenthesesLevel -= 1
		
		gryParserLog?("-- Close parenthesis: level \(parenthesesLevel)")
	}
	
	func readIdentifierOrString() -> String {
		if canReadDoubleQuotedString() {
			let string = readDoubleQuotedString()
			return "\(string)"
		}
		else if canReadSingleQuotedString() {
			let string = readSingleQuotedString()
			return "\(string)"
		}
		else if canReadStringInBrackets() {
			let string = readStringInBrackets()
			return "\(string)"
		}
		else if canReadIdentifier() {
			return readIdentifier()
		}
		
		fatalError("Parsing error")
	}
	
	func readIdentifier() -> String {
		contents =~ "^\\s+" => ""
		
		var result = ""
		
		var parenthesesLevel = 0
		loop: for character in contents {
			switch character {
			case "(":
				parenthesesLevel += 1
				result.append(character)
			case ")":
				parenthesesLevel -= 1
				if parenthesesLevel < 0 {
					break loop
				}
				else {
					result.append(character)
				}
			case " ", "\n", "\"", "'": break loop
			default:
				result.append(character)
			}
		}

		gryParserLog?("-- Read identifier: \"\(result)\"")
		contents.removeFirst(result.count)
		return result
	}

	func readKey() -> String {
		contents =~ "^\\s+" => ""
		
		// Try finding known composed keys before trying for any non-composed keys
		for composedKey in GRYSExpressionParser.knownComposedKeys {
			if contents.hasPrefix(composedKey) {
				gryParserLog?("-- Read composed key: \"\(composedKey)\"")
				contents.removeFirst(composedKey.count)
				let result = composedKey.dropLast()
				return String(result)
			}
		}
		
		// If no known composed keys were found
		var matchIterator = contents =~ "^[^\\s\\)\\(\"'=]+="
		guard let match = matchIterator.next() else { fatalError("Parsing error") }
		let matchedString = match.matchedString
		gryParserLog?("-- Read key: \"\(matchedString)\"")
		contents.removeFirst(matchedString.count)
		let result = matchedString.dropLast()
		return String(result)
	}

	func readDoubleQuotedString() -> String {
		contents =~ "^\\s+" => ""
		var matchIterator = contents =~ "^\"[^\"]+\""
		guard let match = matchIterator.next() else { fatalError("Parsing error") }
		let matchedString = match.matchedString
		gryParserLog?("-- String: \"\(matchedString)\"")
		contents.removeFirst(matchedString.count)
		let result = matchedString.dropFirst().dropLast()
		return String(result)
	}
	
	func readSingleQuotedString() -> String {
		contents =~ "^\\s+" => ""
		var matchIterator = contents =~ "^'[^']+'"
		guard let match = matchIterator.next() else { fatalError("Parsing error") }
		let matchedString = match.matchedString
		gryParserLog?("-- String: \"\(matchedString)\"")
		contents.removeFirst(matchedString.count)
		let result = matchedString.dropFirst().dropLast()
		return String(result)
	}
	
	func readStringInBrackets() -> String {
		contents =~ "^\\s+" => ""
		var matchIterator = contents =~ "^\\[[^\\]]+\\]"
		guard let match = matchIterator.next() else { fatalError("Parsing error") }
		let matchedString = match.matchedString
		gryParserLog?("-- String: \"\(matchedString)\"")
		contents.removeFirst(matchedString.count)
		let result = matchedString.dropFirst().dropLast()
		return String(result)
	}
}
