// TODO: Clean regex comments

internal class GRYSExpressionParser {
	let buffer: String
	var currentIndex: String.Index
	
	var remainingBuffer: Substring {
		return buffer[currentIndex...]
	}
	
	init(sExpression: String) {
		self.buffer = sExpression
		self.currentIndex = buffer.startIndex
	}
	
	func nextIndex() -> String.Index {
		return buffer.index(after: currentIndex)
	}
	
	//
	func cleanLeadingWhitespace() {
		while true {
			guard currentIndex != buffer.endIndex else {
				return
			}
			
			let character = buffer[currentIndex]
			
			if character != " " && character != "\n" {
				return
			}
			
			currentIndex = nextIndex()
		}
	}
	
	// MARK: - Can read information
	func canReadOpenParentheses() -> Bool {
		return buffer[currentIndex] == "("
	}
	
	func canReadCloseParentheses() -> Bool {
		return buffer[currentIndex] == ")"
	}
	
	func canReadDoubleQuotedString() -> Bool {
		return buffer[currentIndex] == "\""
	}
	
	func canReadSingleQuotedString() -> Bool {
		return buffer[currentIndex] == "'"
	}
	
	func canReadStringInBrackets() -> Bool {
		return buffer[currentIndex] == "["
	}
	
	func canReadLocation() -> Bool {
		return buffer[currentIndex] == "/"
	}
	
	// MARK: - Read information
	func readOpenParentheses() {
		guard canReadOpenParentheses() else { fatalError("Parsing error") }
		currentIndex = nextIndex()
	}
	
	func readCloseParentheses() {
		guard canReadCloseParentheses() else { fatalError("Parsing error") }
		currentIndex = nextIndex()
		cleanLeadingWhitespace()
	}
	
	func readStandaloneAttribute() -> String {
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
		else if let string = readDeclarationLocation() {
			return "\(string)"
		}
		else {
			return readIdentifier()
		}
	}
	
	func readIdentifier() -> String {
		defer { cleanLeadingWhitespace() }

		var parenthesesLevel = 0
		
		var index = currentIndex
		loop: while true {
			let character = buffer[index]
			
			switch character {
			case "(":
				parenthesesLevel += 1
			case ")":
				parenthesesLevel -= 1
				if parenthesesLevel < 0 {
					break loop
				}
			case " ", "\n":
				if parenthesesLevel == 0 {
					break loop
				}
			default: break
			}
			
			index = buffer.index(after: index)
		}
		
		let string = String(buffer[currentIndex..<index])
		
		currentIndex = index
		
		return string
	}
	
	func readKey() -> String? {
		defer { cleanLeadingWhitespace() }
		
		var index = currentIndex
		while true {
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
				let composedKeyEndIndex = buffer.index(currentIndex, offsetBy: 15)
				
				if buffer[currentIndex..<composedKeyEndIndex] == "interface type=" {
					currentIndex = composedKeyEndIndex
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
		
		let string = String(buffer[currentIndex..<index])
		
		// Skip the =
		currentIndex = buffer.index(after: index)
		
		return string
	}
	
	// TODO: Update regex comments
	func readLocation() -> String {
		defer { cleanLeadingWhitespace() }
		
		// Regex: ^([^:\\(\\)]*?):(\\d+):(\\d+)
		//   String start,
		//   many characters but no :, ( or ) (not greedy so it won't go past this specific location),
		//   then :, a number, :, and another number
		
		// Expect other ok characters until ':'.
		// If '(' or ')' is found, return false early.
		var index = currentIndex
		while true {
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
		while true {
			let character = buffer[index]
			if character == ":" {
				break
			}
			index = buffer.index(after: index)
		}
		
		// Skip another ':'
		index = buffer.index(after: index)
		
		// Read at least one number
		while true {
			let character = buffer[index]
			if !character.isNumber {
				break
			}
			index = buffer.index(after: index)
		}
		 
		//
		let string = String(buffer[currentIndex..<index])
		currentIndex = index
		return string
	}
	
	func readDeclarationLocation() -> String? {
		defer { cleanLeadingWhitespace() }
		
		// Regex: String start,
		//   many characters but no @ or whitespace (not greedy so it won't go past this specific declaration location),
		//   then @
		
		guard buffer[currentIndex] != "(" else {
			return nil
		}
		
		// Expect no whitespace until '@'.
		// If whitespace is found, return nil early.
		var index = buffer.index(after: currentIndex)

		while true {
			let character = buffer[index]
			guard character != " " &&
				character != "\n" else
			{
				// Unexpected, this isn't a declaration location
				return nil
			}
			if character == "@" {
				// Ok, it's a declaration location
				break
			}
			index = buffer.index(after: index)
		}
		
		// Skip the @ sign
		index = buffer.index(after: index)
		
		// Ensure a location comes after
		guard buffer[index] == "/" else { return nil }
		
		//
		let string = buffer[currentIndex..<index]
		currentIndex = index
		
		let location = readLocation()
		
		return string + location
	}
	
	func readDoubleQuotedString() -> String {
		defer { cleanLeadingWhitespace() }
		
		// TODO: Optimize this result building too
		var result = "\""
		
		var isEscaping = false
		
		var index = buffer.index(after: currentIndex)
		loop: while true {
			let character = buffer[index]
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
			
			index = buffer.index(after: index)
		}
		
		// Skip the closing "
		index = buffer.index(after: index)
		
		currentIndex = index

		let unquotedResult = String(result.dropFirst().dropLast())
		return unquotedResult
	}
	
	func readSingleQuotedString() -> String {
		defer { cleanLeadingWhitespace() }
		
		var index = buffer.index(after: currentIndex)
		while true {
			let character = buffer[index]
			if character == "'" {
				break
			}
			index = buffer.index(after: index)
		}
		
		// Skip the closing '
		index = buffer.index(after: index)
		
		let string = buffer[currentIndex..<index]
		currentIndex = index
		let unquotedResult = String(string.dropFirst().dropLast()) // TODO: Optimize this
		let result = unquotedResult.isEmpty ? "_" : unquotedResult
		
		// Check if it's a list of identifiers
		let otherString: String
		if buffer[currentIndex] == "," {
			currentIndex = nextIndex()
			otherString = readStandaloneAttribute()
			return result + "," + otherString
		}
		else {
			return result
		}
	}
	
	func readStringInBrackets() -> String {
		defer { cleanLeadingWhitespace() }
		
		var index = buffer.index(after: currentIndex)
		while true {
			let character = buffer[index]
			if character == "]" {
				break
			}
			index = buffer.index(after: index)
		}
		
		// Skip the closing ]
		index = buffer.index(after: index)
		
		let string = buffer[currentIndex..<index]
		currentIndex = index
		let result = string.dropFirst().dropLast() // TODO: Optimize this.
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
