internal class GRYSExpressionParser {
	private(set) var buffer: String
	private var needsCleaningWhitespace = true
	
	init(sExpression: String) {
		self.buffer = sExpression
	}
	
	//
	func cleanLeadingWhitespace() {
		if needsCleaningWhitespace {
			needsCleaningWhitespace = false
			
			let whitespacePrefix = buffer.prefix(while: { $0 == "\n" || $0 == " " })
			if !whitespacePrefix.isEmpty {
				buffer = String(buffer.suffix(from: whitespacePrefix.endIndex))
			}
		}
	}
	
	// MARK: - Can read information
	func canReadOpenParentheses() -> Bool {
		cleanLeadingWhitespace()
		return buffer.prefix(1) == "("
	}
	
	func canReadCloseParentheses() -> Bool {
		cleanLeadingWhitespace()
		return buffer.prefix(1) == ")"
	}
	
	func canReadDoubleQuotedString() -> Bool {
		cleanLeadingWhitespace()
		
		if let character = buffer.first,
			character == "\""
		{
			return true
		}
		else {
			return false
		}
	}
	
	func canReadSingleQuotedString() -> Bool {
		cleanLeadingWhitespace()
		
		if let character = buffer.first,
			character == "'"
		{
			return true
		}
		else {
			return false
		}
	}
	
	func canReadStringInBrackets() -> Bool {
		cleanLeadingWhitespace()
		
		if let character = buffer.first,
			character == "["
		{
			return true
		}
		else {
			return false
		}
	}
	
	func canReadLocation() -> Bool {
		cleanLeadingWhitespace()
		return buffer.hasPrefix("/")
	}
	
	func canReadDeclarationLocation() -> Bool {
		// Regex: ^([^\\(][^@\\s]*?)@
		//   String start,
		//   some character that's not a (,
		//   many characters but no @ or whitespace (not greedy so it won't go past this specific declaration location),
		//   then @
		
		cleanLeadingWhitespace()
		
		// At least the first character is not a '('
		guard let firstCharacter = buffer.first,
			firstCharacter != "(" else
		{
			return false
		}
		
		// Expect no whitespace until '@'.
		// If whitespace is found, return false early.
		
		var index = buffer.index(after: buffer.startIndex)
		
		while index != buffer.endIndex {
			let character = buffer[index]
			guard character != " " &&
				character != "\n" else
			{
				// Unexpected, this isn't a declaration location
				return false
			}
			if character == "@" {
				// Ok, it's a declaration location
				break
			}
			index = buffer.index(after: index)
		}
		
		index = buffer.index(after: index)
		guard buffer[index] == "/" else { return false }
		
		return true
	}
	
	// MARK: - Read information
	func readOpenParentheses() {
		guard canReadOpenParentheses() else { fatalError("Parsing error") }
		
		buffer.removeFirst()
	}
	
	func readCloseParentheses() {
		guard canReadCloseParentheses() else { fatalError("Parsing error") }
		defer { needsCleaningWhitespace = true }
		
		buffer.removeFirst()
	}
	
	func readStandaloneAttribute() -> String {
		defer { needsCleaningWhitespace = true }
		
		if canReadOpenParentheses() {
			return ""
		}
		else if canReadDoubleQuotedString() {
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
		else if canReadDeclarationLocation() {
			let string = readDeclarationLocation()
			return "\(string)"
		}
		else {
			return readIdentifier()
		}
	}
	
	func readIdentifier() -> String {
		cleanLeadingWhitespace()
		defer { needsCleaningWhitespace = true }
		
		var result = ""
		
		var parenthesesLevel = 0
		loop: for character in buffer {
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
			case " ", "\n": break loop
			default:
				result.append(character)
			}
		}
		
		buffer.removeFirst(result.count)
		return result
	}
	
	func readKey() -> String? {
		cleanLeadingWhitespace()
		defer { needsCleaningWhitespace = true }
		
		var index = buffer.startIndex
		while index != buffer.endIndex {
			let character = buffer[index]
			guard character != "\n",
				character != "(",
				character != ")",
				character != "'",
				character != "\"" else
			{
				return nil
			}
			
			guard character != " " else {
				if buffer.hasPrefix("interface type=") {
					buffer.removeFirst(15)
					return "interface type"
				}
				else {
					return nil
				}
			}
			
			if character == "=" {
				break
			}
			index = buffer.index(after: index)
		}
		
		let string = String(buffer[buffer.startIndex...index])
		buffer.removeFirst(string.count)
		let result = string.dropLast() // TODO: Optimize
		return String(result)
	}
	
	func readLocation() -> String {
		cleanLeadingWhitespace()
		defer { needsCleaningWhitespace = true }
		
		// Regex: ^([^:\\(\\)]*?):(\\d+):(\\d+)
		//   String start,
		//   many characters but no :, ( or ) (not greedy so it won't go past this specific location),
		//   then :, a number, :, and another number
		
		// Expect other ok characters until ':'.
		// If '(' or ')' is found, return false early.
		var index = buffer.startIndex
		while index != buffer.endIndex {
			let character = buffer[index]
			if character == ":" {
				// Ok, first part is done, check the next parts
				break
			}
			index = buffer.index(after: index)
		}
		
		// Skip the ':' we just found
		index = buffer.index(after: index)
		
		// Read a few numbers
		while index != buffer.endIndex {
			let character = buffer[index]
			if character == ":" {
				break
			}
			index = buffer.index(after: index)
		}
		
		// Skip another ':'
		index = buffer.index(after: index)
		
		// Read at least one number
		while index != buffer.endIndex {
			let character = buffer[index]
			if !character.isNumber {
				break
			}
			index = buffer.index(after: index)
		}
		 
		//
		let string = String(buffer[buffer.startIndex..<index])
		buffer.removeFirst(string.count)
		return string
	}
	
	func readDeclarationLocation() -> String {
		cleanLeadingWhitespace()
		defer { needsCleaningWhitespace = true }
		
		// Regex: String start,
		//   many characters but no @ or whitespace (not greedy so it won't go past this specific declaration location),
		//   then @
		
		// Expect no whitespace until '@'.
		// If whitespace is found, return false early.
		var index = buffer.startIndex
		while index != buffer.endIndex {
			let character = buffer[index]
			if character == "@" {
				break
			}
			index = buffer.index(after: index)
		}
		
		//
		let string = buffer[buffer.startIndex...index]
		buffer.removeFirst(string.count)
		
		let location = readLocation()
		
		return string + location
	}
	
	func readDoubleQuotedString() -> String {
		cleanLeadingWhitespace()
		defer { needsCleaningWhitespace = true }
		
		var result = "\""
		
		var isEscaping = false
		loop: for character in buffer.dropFirst() {
			result.append(character)
			
			switch character {
			case "\\":
				if isEscaping {
					isEscaping = false
				}
				else {
					isEscaping = true
				}
			case "\"":
				if isEscaping {
					isEscaping = false
				}
				else {
					break loop
				}
			default:
				isEscaping = false
			}
		}

		buffer.removeFirst(result.count)

		let unquotedResult = String(result.dropFirst().dropLast())
		return unquotedResult
	}
	
	func readSingleQuotedString() -> String {
		cleanLeadingWhitespace()
		defer { needsCleaningWhitespace = true }
		
		var index = buffer.index(after: buffer.startIndex)
		while index != buffer.endIndex {
			let character = buffer[index]
			if character == "'" {
				break
			}
			index = buffer.index(after: index)
		}
		
		//
		let string = buffer[buffer.startIndex...index]
		buffer.removeFirst(string.count)
		let unquotedResult = String(string.dropFirst().dropLast()) // TODO: Optimize this
		let result = unquotedResult.isEmpty ? "_" : unquotedResult
		
		// Check if it's a list of identifiers
		let otherString: String
		if buffer[buffer.startIndex] == "," {
			buffer.removeFirst()
			otherString = readStandaloneAttribute()
			return result + "," + otherString
		}
		else {
			return result
		}
	}
	
	func readStringInBrackets() -> String {
		cleanLeadingWhitespace()
		defer { needsCleaningWhitespace = true }
		
		var index = buffer.index(after: buffer.startIndex)
		while index != buffer.endIndex {
			let character = buffer[index]
			if character == "]" {
				break
			}
			index = buffer.index(after: index)
		}
		
		//
		let string = buffer[buffer.startIndex...index]
		buffer.removeFirst(string.count)
		let result = string.dropFirst().dropLast()
		return String(result)
	}
}

private extension Character {
	var isNumber: Bool {
		return self == "0" ||
			self == "1" ||
			self == "2" ||
			self == "3" ||
			self == "4" ||
			self == "5" ||
			self == "6" ||
			self == "7" ||
			self == "8" ||
			self == "9"
	}
}
