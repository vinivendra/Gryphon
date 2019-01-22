/*
* Copyright 2018 Vinícius Jorge Vendramini
*
* Licensed under the Apache License, Version 2.0 (the "License");
* you may not use this file except in compliance with the License.
* You may obtain a copy of the License at
*
* http://www.apache.org/licenses/LICENSE-2.0
*
* Unless required by applicable law or agreed to in writing, software
* distributed under the License is distributed on an "AS IS" BASIS,
* WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
* See the License for the specific language governing permissions and
* limitations under the License.
*/

//
enum GRYDecodingError: CustomStringConvertible, Error {
	case conversionFailure(GRYDecoder, String)

	var description: String {
		switch self {
		case let .conversionFailure(decoder, message):
			return "Decoding error: \(message)\n" +
				"Remaining buffer in decoder: \"\(decoder.remainingBuffer(upTo: 30))\""
		}
	}
}

protocol GRYDecodable {
	static func decode(from: GRYDecoder) throws -> Self
}

protocol GRYEncodable {
	func encode(into encoder: GRYEncoder) throws
}

typealias GRYCodable = GRYEncodable & GRYDecodable

// MARK: - Decoder
internal class GRYDecoder {
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
	// TODO: Change this init
	init(sExpression: String) {
		self.buffer = sExpression
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

	// TODO: test
	func canReadOpenBrackets() -> Bool {
		return buffer[currentIndex] == "["
	}

	// TODO: test
	func canReadCloseBrackets() -> Bool {
		return buffer[currentIndex] == "]"
	}

	// TODO: test
	func canReadOpenCurlyBrackets() -> Bool {
		return buffer[currentIndex] == "{"
	}

	// TODO: test
	func canReadCloseCurlyBrackets() -> Bool {
		return buffer[currentIndex] == "}"
	}

	func canReadStringInAngleBrackets() -> Bool {
		return buffer[currentIndex] == "<"
	}

	func canReadLocation() -> Bool {
		return buffer[currentIndex] == "/"
	}

	// MARK: Read information
	func readOpenParentheses() {
		guard canReadOpenParentheses() else { fatalError("Parsing error") }
		currentIndex = nextIndex()
	}

	// TODO: Replace these fatal errors with something more testable
	func readCloseParentheses() {
		guard canReadCloseParentheses() else { fatalError("Parsing error") }
		currentIndex = nextIndex()
		cleanLeadingWhitespace()
	}

	func readOpenBrackets() {
		guard canReadOpenBrackets() else { fatalError("Parsing error") }
		currentIndex = nextIndex()
		cleanLeadingWhitespace()
	}

	func readCloseBrackets() {
		guard canReadCloseBrackets() else { fatalError("Parsing error") }
		currentIndex = nextIndex()
		cleanLeadingWhitespace()
	}

	func readOpenCurlyBrackets() {
		guard canReadOpenCurlyBrackets() else { fatalError("Parsing error") }
		currentIndex = nextIndex()
		cleanLeadingWhitespace()
	}

	func readCloseCurlyBrackets() {
		guard canReadCloseCurlyBrackets() else { fatalError("Parsing error") }
		currentIndex = nextIndex()
		cleanLeadingWhitespace()
	}

	// TODO: Can't this just be `return string`?
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
		else if canReadStringInAngleBrackets() {
			let string = readStringInAngleBrackets()
			return "\(string)"
		}
		else if let string = readDeclarationLocation() {
			return "\(string)"
		}
		else {
			return readIdentifier()
		}
	}

	/**
	Reads an identifier. An identifier may have parentheses in it, so this function also
	checks to see if they're balanced and only exits when the last open parethesis has been closed.
	*/
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
				break loop
			default: break
			}

			index = buffer.index(after: index)
		}

		let string = String(buffer[currentIndex..<index])

		currentIndex = index

		return string
	}

	/**
	Reads a list of identifiers. This is used to read a list of classes and/or protocols in
	inheritance clauses, as in `class MyClass: A, B, C, D, E { }`.
	This algorithm assumes an identifier list is always the last attribute in a subtree, and thus
	always ends in whitespace. This may well not be true, and in that case this will have to change.
	*/
	func readIdentifierList() -> String {
		defer { cleanLeadingWhitespace() }

		var index = currentIndex
		while true {
			let character = buffer[index]

			if character == "\n" || character == ")" {
				break
			}

			index = buffer.index(after: index)
		}

		let string = String(buffer[currentIndex..<index])

		currentIndex = index

		return string
	}

	/**
	Reads a key. A key can't have parentheses, single or double quotes, or whitespace in it
	(expect for composed keys, as a special case below) and it must end with an '='. If the
	string in the beginning of the buffer isn't a key, this function returns nil.
	*/
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

			if character == "=" ||
				character == ":"
			{
				break
			}

			index = buffer.index(after: index)
		}

		let string = String(buffer[currentIndex..<index])

		// Skip the =
		currentIndex = buffer.index(after: index)

		return string
	}

	/**
	Reads a location. A location is a series of characters that can't be colons or parentheses
	(usually it's a file path), followed by a colon, a number, another colon and another number.
	*/
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
		currentIndex = index
		return string
	}

	/**
	Reads a declaration location. A declaration location is a series of characters defining a swift
	declaration, up to an '@'. After that comes a location, read by the `readLocation` function.
	*/
	func readDeclarationLocation() -> String? {
		defer { cleanLeadingWhitespace() }

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
		guard buffer[index] == "/" else {
			return nil
		}

		//
		let string = buffer[currentIndex..<index]
		currentIndex = index

		let location = readLocation()

		return string + location
	}

	/**
	Reads a double quoted string, taking care not to count double quotes that have been escaped by a
	backslash.
	*/
	func readDoubleQuotedString() -> String {
		defer { cleanLeadingWhitespace() }

		var isEscaping = false

		// Skip the opening "
		let firstContentsIndex = buffer.index(after: currentIndex)

		var index = firstContentsIndex
		loop: while true {
			let character = buffer[index]

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

		let string = String(buffer[firstContentsIndex..<index])

		// Skip the closing "
		index = buffer.index(after: index)
		currentIndex = index

		return string
	}

	/**
	Reads a single quoted string. These often show up in lists of names, which may be in a form
	such as `'',foo,'','',bar`. In this case, we want to parse the whole thing, not just the initial
	empty single-quoted string, so this function calls `readStandaloneAttribute` if it finds a comma
	in order to parse the rest of the list.
	*/
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

		let string = (firstContentsIndex == index) ?
			"_" :
			String(buffer[firstContentsIndex..<index])

		// Skip the closing '
		index = buffer.index(after: index)

		currentIndex = index

		// Check if it's a list of identifiers
		let otherString: String
		if buffer[currentIndex] == "," {
			currentIndex = nextIndex()
			otherString = readStandaloneAttribute()
			return string + "," + otherString
		}
		else {
			return string
		}
	}

	func readStringInBrackets() -> String {
		defer { cleanLeadingWhitespace() }

		// Skip the opening [
		let firstContentsIndex = buffer.index(after: currentIndex)

		var index = firstContentsIndex
		while true {
			let character = buffer[index]
			if character == "]" {
				break
			}
			index = buffer.index(after: index)
		}

		let string = String(buffer[firstContentsIndex..<index])

		// Skip the closing ]
		index = buffer.index(after: index)
		currentIndex = index

		return string
	}

	func readStringInAngleBrackets() -> String {
		defer { cleanLeadingWhitespace() }

		// Skip the opening <
		var index = buffer.index(after: currentIndex)
		while true {
			let character = buffer[index]
			if character == ">" {
				break
			}
			index = buffer.index(after: index)
		}

		// Skip the closing >
		index = buffer.index(after: index)

		let string = String(buffer[currentIndex..<index])

		currentIndex = index

		return string
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

// TODO: test
public class GRYEncoder {
	private var indentation = ""
	public var result = ""

	public init() { }

	public func startNewObject(named name: String) {
		let name = "\"\(name)\""

		if result.isEmpty {
			result += "(" + name
			increaseIndentation()
		}
		else {
			result += "\n" + indentation + "(" + name
			increaseIndentation()
		}
	}

	public func endObject() {
		result += ")"
		decreaseIndentation()
	}

	public func addKey(_ key: String) {
		result += " " + key + "="
	}

	public func add(_ literal: String) {
		let lastCharacter = result.last
		if lastCharacter != "(", lastCharacter != "[", lastCharacter != "{", lastCharacter != "=" {
			result += " "
		}
		result += literal
	}

	public func increaseIndentation() {
		indentation += "  "
	}

	public func decreaseIndentation() {
		indentation = String(indentation.dropLast(2))
	}
}

// MARK: - Common type conformances
extension Array: GRYCodable where Element: GRYCodable {
	func encode(into encoder: GRYEncoder) throws {
		encoder.add("[")
		for element in self {
			try element.encode(into: encoder)
		}
		encoder.add("]")
	}

	static func decode(from decoder: GRYDecoder) throws -> [Element] {
		var result = [Element]()
		decoder.readOpenBrackets()
		while !decoder.canReadCloseBrackets() {
			let newElement = try Element.decode(from: decoder)
			result.append(newElement)
		}
		decoder.readCloseBrackets()
		return result
	}
}

extension Dictionary: GRYCodable where
	Key: GRYCodable, Value: GRYCodable
{
	func encode(into encoder: GRYEncoder) throws {
		encoder.add("{")
		for (key, value) in self {
			try key.encode(into: encoder)
			try value.encode(into: encoder)
		}
		encoder.add("}")
	}

	static func decode(from decoder: GRYDecoder) throws -> [Key: Value] {
		var result = [Key: Value]()
		decoder.readOpenCurlyBrackets()
		defer { decoder.readCloseCurlyBrackets() }
		while !decoder.canReadCloseCurlyBrackets() {
			let newKey = try Key.decode(from: decoder)
			let newValue = try Value.decode(from: decoder)
			result[newKey] = newValue
		}
		return result
	}
}

extension String: GRYCodable {
	func encode(into encoder: GRYEncoder) throws {
		encoder.add("\"\(self)\"")
	}

	static func decode(from decoder: GRYDecoder) throws -> String {
		return decoder.readDoubleQuotedString()
	}
}

extension Int: GRYCodable {
	func encode(into encoder: GRYEncoder) throws {
		encoder.add(String(self))
	}

	static func decode(from decoder: GRYDecoder) throws -> Int {
		let expectedInt = decoder.readIdentifier()
		guard let result = Int(expectedInt) else {
			throw GRYDecodingError.conversionFailure(
				decoder, "Failed to convert \(expectedInt) to Int.")
		}
		return result
	}
}

extension Double: GRYCodable {
	func encode(into encoder: GRYEncoder) throws {
		encoder.add(String(self))
	}

	static func decode(from decoder: GRYDecoder) throws -> Double {
		let expectedDouble = decoder.readIdentifier()
		guard let result = Double(expectedDouble) else {
			throw GRYDecodingError.conversionFailure(
				decoder, "Failed to convert \(expectedDouble) to Double.")
		}
		return result
	}
}

extension Bool: GRYCodable {
	func encode(into encoder: GRYEncoder) throws {
		if self {
			encoder.add("true")
		}
		else {
			encoder.add("false")
		}
	}

	static func decode(from decoder: GRYDecoder) throws -> Bool {
		let expectedBool = decoder.readIdentifier()
		guard let result = Bool(expectedBool) else {
			throw GRYDecodingError.conversionFailure(
				decoder, "Failed to convert \(expectedBool) to Bool.")
		}
		return result
	}
}

extension Optional: GRYCodable where Wrapped: GRYCodable {
	func encode(into encoder: GRYEncoder) throws {
		if let unwrapped = self {
			try unwrapped.encode(into: encoder)
		}
		else {
			encoder.add("nil")
		}
	}

	static func decode(from decoder: GRYDecoder) throws -> Wrapped? {
		if decoder.buffer[decoder.currentIndex...].hasPrefix("nil") {
			_ = decoder.readIdentifier()
			return nil
		}
		return try Wrapped.decode(from: decoder)
	}
}
