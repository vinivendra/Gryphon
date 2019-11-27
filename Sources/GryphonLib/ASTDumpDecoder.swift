//
// Copyright 2018 Vinícius Jorge Vendramini
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
// http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.
//

// gryphon output: Sources/GryphonLib/ASTDumpDecoder.swiftAST
// gryphon output: Sources/GryphonLib/ASTDumpDecoder.gryphonASTRaw
// gryphon output: Sources/GryphonLib/ASTDumpDecoder.gryphonAST
// gryphon output: Bootstrap/ASTDumpDecoder.kt

internal class ASTDumpDecoder {
	let buffer: String
	var currentIndex: String.Index

	var remainingBuffer: Substring {
		return buffer[currentIndex...]
	}

	func remainingBuffer(upTo limit: Int = 30) -> Substring {
		let remainingBuffer = buffer[currentIndex...]
		if remainingBuffer.count > limit {
			return buffer[currentIndex...].prefix(limit) + "…"
		}
		else {
			return remainingBuffer
		}
	}

	//
	enum DecodingError: Error, CustomStringConvertible {
		case unexpectedContent(decoder: ASTDumpDecoder, errorMessage: String)

		var description: String {
			switch self {
			case let .unexpectedContent(decoder, errorMessage):
				return "Decoding error: \(errorMessage)\n" +
				"Remaining buffer in decoder: \"\(decoder.remainingBuffer(upTo: 1_000))\""
			}
		}
	}

	//
	init(encodedString: String) {
		self.buffer = encodedString
		self.currentIndex = buffer.startIndex
	}

	//
	func nextIndex() -> String.Index {
		return buffer.index(after: currentIndex)
	}

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

	// MARK: Can read information
	func canReadOpeningParenthesis() -> Bool {
		return buffer[currentIndex] == "("
	}

	func canReadClosingParenthesis() -> Bool {
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

	func canReadStringInAngleBrackets() -> Bool {
		return buffer[currentIndex] == "<"
	}

	// MARK: Read information
	func readOpeningParenthesis() throws {
		guard canReadOpeningParenthesis() else {
			throw DecodingError.unexpectedContent(decoder: self, errorMessage: "Expected '('.")
		}
		currentIndex = nextIndex()
	}

	func readClosingParenthesis() throws {
		guard canReadClosingParenthesis() else {
			throw DecodingError.unexpectedContent(decoder: self, errorMessage: "Expected ')'.")
		}
		currentIndex = nextIndex()
		cleanLeadingWhitespace()
	}

	func readStandaloneAttribute() -> String {
		if canReadOpeningParenthesis() {
			return ""
		}
		if canReadDoubleQuotedString() {
			let string = readDoubleQuotedString()
			return string
		}
		if canReadSingleQuotedString() {
			let string = readSingleQuotedString()
			return string
		}
		if canReadStringInBrackets() {
			let string = readStringInBrackets()
			return string
		}
		if canReadStringInAngleBrackets() {
			let string = readStringInAngleBrackets()
			return string
		}
		if let declarationLocation = readDeclarationLocation() {
			return declarationLocation
		}
		if let declaration = readDeclaration() {
			return declaration
		}
		else {
			return readIdentifier()
		}
	}

	///
	/// Reads an identifier. An identifier may have parentheses (or angle brackets) in it, so this
	/// function also checks to see if they're balanced and only exits when the last open parethesis
	/// has been closed.
	///
	/// For some reason (a bug in the compiler) the identifier can sometimes be split in two by a
	/// newline. Newlines that seem to occur normally are followed by a series of spaces, but these
	/// buggy newlines are just followed by the rest of the identifier. So if the character
	/// following newline is not a space, we assume that's what happened and keep reading the rest.
	///
	func readIdentifier() -> String {
		var parenthesesLevel = 0

		var index = currentIndex

		while true {
			let character = buffer[index]

			if character == "(" || character == "<" {
				parenthesesLevel += 1
			}
			else if character == ")" || character == ">" {
				parenthesesLevel -= 1
				if parenthesesLevel < 0 {
					break
				}
			}
			else if character == "\n" {
				let nextCharacter = buffer[buffer.index(after: index)]
				if nextCharacter == " " {
					break
				}
			}
			else if character == "-" {
				// Allow "->" to be read without counting for the parentheses level
				let nextCharacter = buffer[buffer.index(after: index)]
				if nextCharacter == ">" {
					index = buffer.index(after: index)
				}
			}
			else if character == " ", parenthesesLevel <= 0 {
				break
			}

			index = buffer.index(after: index)
		}

		let string = String(buffer[currentIndex..<index])
		let cleanString = string.replacingOccurrences(of: "\n", with: "")

		currentIndex = index

		cleanLeadingWhitespace()

		return cleanString
	}

	///
	/// Reads a list of identifiers. This is used to read a list of classes and/or protocols in
	/// inheritance clauses, as in `class MyClass: A, B, C, D, E { }`.
	/// This algorithm assumes an identifier list is always the last attribute in a subtree, and
	/// thus always ends in whitespace. This may well not be true, and in that case this will have
	/// to change.
	///
	/// Also prevents the newline bug (see the documentation for readIdentifier).
	///
	func readIdentifierList() -> String {
		defer { cleanLeadingWhitespace() }

		var index = currentIndex
		while true {
			let character = buffer[index]

			if character == ")" {
				break
			}

			if character == "\n" {
				let nextCharacter = buffer[buffer.index(after: index)]
				if nextCharacter == " " {
					break
				}
			}

			index = buffer.index(after: index)
		}

		let string = String(buffer[currentIndex..<index])
		let cleanString = string.replacingOccurrences(of: "\n", with: "")

		currentIndex = index

		return cleanString
	}

	///
	/// Reads a key. A key can't have parentheses, single or double quotes, or whitespace in it
	/// (expect for composed keys, as a special case below) and it must end with an '='. If the
	/// string in the beginning of the buffer isn't a key, this function returns nil.

	/// Also prevents the newline bug (see the documentation for readIdentifier).
	///
	func readKey() -> String? {
		defer { cleanLeadingWhitespace() }

		guard !canReadOpeningParenthesis(), !canReadClosingParenthesis() else {
			return nil
		}

		var index = currentIndex
		while true {
			let character = buffer[index]

			if character == "\n" {
				let nextCharacter = buffer[buffer.index(after: index)]
				if nextCharacter == " " {
					return nil
				}
			}

			guard character != "(",
				character != ")",
				character != "'",
				character != "\"" else
			{
				return nil
			}

			guard character != " " else {
				let composedKeyEndIndex =
					buffer.index(currentIndex, offsetBy: "interface type=".count)

				if buffer[currentIndex..<composedKeyEndIndex] == "interface type=" {
					currentIndex = composedKeyEndIndex
					return "interface type"
				}
				else {
					return nil
				}
			}

			if character == "=" || character == ":" {
				break
			}

			index = buffer.index(after: index)
		}

		let string = String(buffer[currentIndex..<index])
		let cleanString = string.replacingOccurrences(of: "\n", with: "")

		// Skip the =
		currentIndex = buffer.index(after: index)

		return cleanString
	}

	///
	/// Reads a location. A location is a series of characters that can't be colons or parentheses
	/// (usually it's a file path), followed by a colon, a number, another colon and another number.
	///
	/// Also prevents the newline bug (see the documentation for readIdentifier).
	///
	func readLocation() -> String {
		defer { cleanLeadingWhitespace() }

		// Expect normal characters until ':'.
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

		// Read at more numbers
		while true {
			let character = buffer[index]
			if !character.isNumber {
				break
			}
			index = buffer.index(after: index)
		}

		//
		let string = String(buffer[currentIndex..<index])
		let cleanString = string.replacingOccurrences(of: "\n", with: "")

		currentIndex = index
		return cleanString
	}

	///
	/// Reads a declaration location. A declaration location is a series of characters defining a
	/// swift declaration, up to an '@'. After that comes a location, read by the `readLocation`
	/// function.
	///
	/// Also prevents the newline bug (see the documentation for readIdentifier).
	///
	func readDeclarationLocation() -> String? {
		defer { cleanLeadingWhitespace() }

		guard buffer[currentIndex] != "(" else {
			return nil
		}

		// Expect no whitespace until '@'.
		// If whitespace is found, return nil early.
		var index = buffer.index(after: currentIndex)

		while index != buffer.endIndex {
			let character = buffer[index]

			if character == "\n" {
				let nextCharacter = buffer[buffer.index(after: index)]
				if nextCharacter == " " {
					// Unexpected, this isn't a declaration location
					return nil
				}
			}

			guard character != " " else {
				// Unexpected, this isn't a declaration location
				return nil
			}
			if character == "@" {
				// Ok, it's a declaration location
				break
			}
			index = buffer.index(after: index)
		}

		guard index != buffer.endIndex else {
			return nil
		}

		// Skip the @ sign
		index = buffer.index(after: index)

		// Ensure a location comes after
		guard buffer[index] != " ", buffer[index] != "\n", buffer[index] != ")" else {
			return nil
		}

		//
		let string = buffer[currentIndex..<index]
		let cleanString = string.replacingOccurrences(of: "\n", with: "")

		currentIndex = index

		let location = readLocation()

		return cleanString + location
	}

	///
	/// Reads a declaration without a location after. A declaration normally contains periods
	/// indicating the parts of the declaration. We use this fact to try to distinguish declarations 
	/// from normal identifiers.
	///
	/// A declaration may also contain a type followed by " extension.", as in
	/// "Swift.(file).Int extension.+". In that case, the space before extension is included in the
	/// declaration.
	///
	/// Also prevents the newline bug (see the documentation for readIdentifier).
	///
	func readDeclaration() -> String? {
		defer { cleanLeadingWhitespace() }

		var parenthesesLevel = 0

		var hasPeriod = false

		var index = currentIndex
		while true {
			let character = buffer[index]

			if character == "." {
				hasPeriod = true
			}
			else if character == "(" {
				parenthesesLevel += 1
			}
			else if character == ")" {
				parenthesesLevel -= 1
				if parenthesesLevel < 0 {
					break
				}
			}
			else if character == " " {
				let endIndex = buffer.index(index, offsetBy: " extension.".count + 1)

				let nextPart = buffer[index..<endIndex].replacingOccurrences(of: "\n", with: "")

				if nextPart.hasPrefix(" extension.") {
					index = buffer.index(after: index)
					continue
				}
				else {
					break
				}
			}
			else if character == "\n" {
				let nextCharacter = buffer[buffer.index(after: index)]
				if nextCharacter == " " {
					break
				}
			}

			index = buffer.index(after: index)
		}

		guard hasPeriod else {
			return nil
		}

		let string = String(buffer[currentIndex..<index])
		let cleanString = string.replacingOccurrences(of: "\n", with: "")

		currentIndex = index

		return cleanString
	}

	///
	/// Reads a double quoted string, taking care not to count double quotes that have been escaped
	/// by a backslash.

	/// Also prevents the newline bug (see the documentation for readIdentifier).
	///
	func readDoubleQuotedString() -> String {
		defer { cleanLeadingWhitespace() }

		var isEscaping = false

		// Skip the opening "
		let firstContentsIndex = buffer.index(after: currentIndex)

		var index = firstContentsIndex
		while true {
			let character = buffer[index]

			if character == "\\" {
				if isEscaping {
					isEscaping = false
				}
				else {
					isEscaping = true
				}
			}
			else if character == "\"" {
				if isEscaping {
					isEscaping = false
				}
				else {
					break
				}
			}
			else {
				isEscaping = false
			}

			index = buffer.index(after: index)
		}

		let string = String(buffer[firstContentsIndex..<index])
		let cleanString = string.replacingOccurrences(of: "\n", with: "")

		// Skip the closing "
		index = buffer.index(after: index)
		currentIndex = index

		return cleanString
	}

	///
	/// Reads a single quoted string. These often show up in lists of names, which may be in a form
	/// such as `'',foo,'','',bar`. In this case, we want to parse the whole thing, not just the
	/// initial empty single-quoted string, so this function calls `readStandaloneAttribute` if it
	/// finds a comma in order to parse the rest of the list.
	///
	/// Also prevents the newline bug (see the documentation for readIdentifier).
	///
	func readSingleQuotedString() -> String {
		defer { cleanLeadingWhitespace() }

		// Skip the opening '
		let firstContentsIndex = buffer.index(after: currentIndex)

		var index = firstContentsIndex
		while true {
			let character = buffer[index]
			if character == "'" {
				break
			}
			index = buffer.index(after: index)
		}

		let string: String
		if firstContentsIndex == index {
			string = "_"
		}
		else {
			string = String(buffer[firstContentsIndex..<index])
		}
		let cleanString = string.replacingOccurrences(of: "\n", with: "")

		// Skip the closing '
		index = buffer.index(after: index)

		currentIndex = index

		// Check if it's a list of identifiers
		let otherString: String
		if buffer[currentIndex] == "," {
			currentIndex = nextIndex()
			otherString = readStandaloneAttribute()
			return cleanString + "," + otherString
		}
		else {
			return cleanString
		}
	}

	///
	/// Reads a string inside brackets and returns the string (without the brackets).
	///
	/// Also prevents the newline bug (see the documentation for readIdentifier).
	///
	func readStringInBrackets() -> String {
		defer { cleanLeadingWhitespace() }

		// Skip the opening [
		let firstContentsIndex = buffer.index(after: currentIndex)
		var index = firstContentsIndex

		var bracketLevel = 1

		while true {
			let character = buffer[index]

			if character == "]" {
				bracketLevel -= 1
				if bracketLevel == 0 {
					break
				}
			}
			else if character == "[" {
				bracketLevel += 1
			}

			index = buffer.index(after: index)
		}

		let string = String(buffer[firstContentsIndex..<index])
		let cleanString = string.replacingOccurrences(of: "\n", with: "")

		// Skip the closing ]
		index = buffer.index(after: index)
		currentIndex = index

		return cleanString
	}

	///
	/// Reads a string inside angle brackets and returns the string (without the brackets).
	///
	/// Also prevents the newline bug (see the documentation for readIdentifier).
	///
	func readStringInAngleBrackets() -> String {
		defer { cleanLeadingWhitespace() }

		// Skip the opening <
		var index = buffer.index(after: currentIndex)

		var bracketLevel = 1

		while true {
			let character = buffer[index]

			if character == ">" {
				bracketLevel -= 1
				if bracketLevel == 0 {
					break
				}
			}
			else if character == "<" {
				bracketLevel += 1
			}

			index = buffer.index(after: index)
		}

		// Skip the closing >
		index = buffer.index(after: index)

		let string = String(buffer[currentIndex..<index])
		let cleanString = string.replacingOccurrences(of: "\n", with: "")

		currentIndex = index

		return cleanString
	}
}

// MARK: - Creating a SwiftAST
extension ASTDumpDecoder {
	public func decode() throws -> SwiftAST {
		let standaloneAttributes: MutableArray<String> = []
		let keyValueAttributes: MutableDictionary<String, String> = [:]
		let subtrees: MutableArray<SwiftAST> = []

		try readOpeningParenthesis()
		let rawName = readIdentifier()
		let name = Utilities.expandSwiftAbbreviation(rawName)

		// The loop stops: all branches tell the decoder to read, therefore the input string must
		// end eventually
		while true {
			// Add key-value attributes
			if let key = readKey() {
				if key == "location" {
					keyValueAttributes[key] = readLocation()
				}
				else if key == "decl" {
					let string = (readDeclarationLocation() ?? readDeclaration())!
					keyValueAttributes[key] = string
				}
				else if key == "bind"
				{
					let string = readDeclarationLocation() ?? readIdentifier()
					keyValueAttributes[key] = string
				}
				else if key == "inherits" {
					let string = readIdentifierList()
					keyValueAttributes[key] = string
				}
				// Capture lists are enclosed in parentheses
				else if key == "captures" {
					let string = readIdentifier()
					keyValueAttributes[key] = string
				}
				else {
					keyValueAttributes[key] = readStandaloneAttribute()
				}
			}
			// Add subtree
			else if canReadOpeningParenthesis() {
				// Parse subtrees
				let subtree = try decode()
				subtrees.append(subtree)
			}
			// Finish this branch
			else if canReadClosingParenthesis() {
				try readClosingParenthesis()
				break
			}
			// Add standalone attributes
			else {
				let attribute = readStandaloneAttribute()
				standaloneAttributes.append(attribute)
			}
		}

		return SwiftAST(name, standaloneAttributes, keyValueAttributes, subtrees)
	}
}
