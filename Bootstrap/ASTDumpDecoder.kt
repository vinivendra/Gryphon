class ASTDumpDecoder {
	companion object {
		public fun decode(astFilePath: String): SwiftAST {
			val astDump: String = Utilities.readFile(astFilePath)
			val decoder: ASTDumpDecoder = ASTDumpDecoder(encodedString = astDump)
			return decode(decoder = decoder)
		}
	}

	val buffer: String
	var currentIndex: Int
	val remainingBuffer: String
		get() {
			return buffer.substring(currentIndex)
		}

	internal fun remainingBuffer(limit: Int = 30): String {
		val remainingBuffer: String = buffer.substring(currentIndex)
		if (remainingBuffer.length > limit) {
			return buffer.substring(currentIndex).substring(0, limit) + "…"
		}
		else {
			return remainingBuffer
		}
	}

	internal sealed class DecodingError: Exception() {
		class UnexpectedContent(val decoder: ASTDumpDecoder, val errorMessage: String): DecodingError()

		override fun toString(): String {
			return when (this) {
				is DecodingError.UnexpectedContent -> {
					val decoder: ASTDumpDecoder = this.decoder
					val errorMessage: String = this.errorMessage
					"Decoding error: ${errorMessage}\n" + "Remaining buffer in decoder: \"${decoder.remainingBuffer(limit = 1000)}\""
				}
			}
		}
	}

	constructor(encodedString: String) {
		this.buffer = encodedString
		this.currentIndex = 0
	}

	internal fun nextIndex(): Int {
		return currentIndex + 1
	}

	internal fun cleanLeadingWhitespace() {
		while (true) {
			if (currentIndex == buffer.length) {
				return
			}

			val character: Char = buffer[currentIndex]

			if (character != ' ' && character != '\n') {
				return
			}

			currentIndex = nextIndex()
		}
	}

	internal fun canReadOpeningParenthesis(): Boolean {
		return buffer[currentIndex] == '('
	}

	internal fun canReadClosingParenthesis(): Boolean {
		return buffer[currentIndex] == ')'
	}

	internal fun canReadDoubleQuotedString(): Boolean {
		return buffer[currentIndex] == '\"'
	}

	internal fun canReadSingleQuotedString(): Boolean {
		return buffer[currentIndex] == '\''
	}

	internal fun canReadStringInBrackets(): Boolean {
		return buffer[currentIndex] == '['
	}

	internal fun canReadStringInAngleBrackets(): Boolean {
		return buffer[currentIndex] == '<'
	}

	internal fun readOpeningParenthesis() {
		if (!(canReadOpeningParenthesis())) {
			throw DecodingError.UnexpectedContent(decoder = this, errorMessage = "Expected '('.")
		}
		currentIndex = nextIndex()
	}

	internal fun readClosingParenthesis() {
		if (!(canReadClosingParenthesis())) {
			throw DecodingError.UnexpectedContent(decoder = this, errorMessage = "Expected ')'.")
		}
		currentIndex = nextIndex()
		cleanLeadingWhitespace()
	}

	internal fun readStandaloneAttribute(): String {
		if (canReadOpeningParenthesis()) {
			return ""
		}

		if (canReadDoubleQuotedString()) {
			val string: String = readDoubleQuotedString()
			return string
		}

		if (canReadSingleQuotedString()) {
			val string: String = readSingleQuotedString()
			return string
		}

		if (canReadStringInBrackets()) {
			val string: String = readStringInBrackets()
			return string
		}

		if (canReadStringInAngleBrackets()) {
			val string: String = readStringInAngleBrackets()
			return string
		}

		val declarationLocation: String? = readDeclarationLocation()

		if (declarationLocation != null) {
			return declarationLocation
		}

		val declaration: String? = readDeclaration()

		if (declaration != null) {
			return declaration
		}
		else {
			return readIdentifier()
		}
	}

	internal fun readIdentifier(): String {
		var parenthesesLevel: Int = 0
		var index: Int = currentIndex

		while (true) {
			val character: Char = buffer[index]
			if (character == '(' || character == '<') {
				parenthesesLevel += 1
			}
			else if (character == ')' || character == '>') {
				parenthesesLevel -= 1
				if (parenthesesLevel < 0) {
					break
				}
			}
			else if (character == '\n') {
				val nextCharacter: Char = buffer[index + 1]
				if (nextCharacter == ' ') {
					break
				}
			}
			else if (character == ' ' && parenthesesLevel <= 0) {
				break
			}
			index = index + 1
		}

		val string: String = buffer.substring(currentIndex, index)
		val cleanString: String = string.replace("\n", "")

		currentIndex = index

		cleanLeadingWhitespace()

		return cleanString
	}

	internal fun readIdentifierList(): String {
		try {
			var index: Int = currentIndex

			while (true) {
				val character: Char = buffer[index]

				if (character == ')') {
					break
				}

				if (character == '\n') {
					val nextCharacter: Char = buffer[index + 1]
					if (nextCharacter == ' ') {
						break
					}
				}

				index = index + 1
			}

			val string: String = buffer.substring(currentIndex, index)
			val cleanString: String = string.replace("\n", "")

			currentIndex = index

			return cleanString
		}
		finally {
			cleanLeadingWhitespace()
		}
	}

	internal fun readKey(): String? {
		try {
			var index: Int = currentIndex

			while (true) {
				val character: Char = buffer[index]

				if (character == '\n') {
					val nextCharacter: Char = buffer[index + 1]
					if (nextCharacter == ' ') {
						return null
					}
				}

				if (!(character != '(' && character != ')' && character != '\'' && character != '\"')) {
					return null
				}

				if (character == ' ') {
					val composedKeyEndIndex: Int = currentIndex + "interface type=".length
					if (buffer.substring(currentIndex, composedKeyEndIndex) == "interface type=") {
						currentIndex = composedKeyEndIndex
						return "interface type"
					}
					else {
						return null
					}
				}

				if (character == '=' || character == ':') {
					break
				}

				index = index + 1
			}

			val string: String = buffer.substring(currentIndex, index)
			val cleanString: String = string.replace("\n", "")

			currentIndex = index + 1

			return cleanString
		}
		finally {
			cleanLeadingWhitespace()
		}
	}

	internal fun readLocation(): String {
		try {
			var index: Int = currentIndex

			while (true) {
				val character: Char = buffer[index]
				if (character == ':') {
					break
				}
				index = index + 1
			}

			index = index + 1

			while (true) {
				val character: Char = buffer[index]
				if (character == ':') {
					break
				}
				index = index + 1
			}

			index = index + 1

			while (true) {
				val character: Char = buffer[index]
				if (!character.isNumber) {
					break
				}
				index = index + 1
			}

			val string: String = buffer.substring(currentIndex, index)
			val cleanString: String = string.replace("\n", "")

			currentIndex = index

			return cleanString
		}
		finally {
			cleanLeadingWhitespace()
		}
	}

	internal fun readDeclarationLocation(): String? {
		try {
			if (buffer[currentIndex] == '(') {
				return null
			}

			var index: Int = currentIndex + 1

			while (index != buffer.length) {
				val character: Char = buffer[index]

				if (character == '\n') {
					val nextCharacter: Char = buffer[index + 1]
					if (nextCharacter == ' ') {
						return null
					}
				}

				if (character == ' ') {
					return null
				}

				if (character == '@') {
					break
				}

				index = index + 1
			}

			if (index == buffer.length) {
				return null
			}

			index = index + 1

			if (!(buffer[index] != ' ' && buffer[index] != '\n' && buffer[index] != ')')) {
				return null
			}

			val string: String = buffer.substring(currentIndex, index)
			val cleanString: String = string.replace("\n", "")

			currentIndex = index

			val location: String = readLocation()

			return cleanString + location
		}
		finally {
			cleanLeadingWhitespace()
		}
	}

	internal fun readDeclaration(): String? {
		try {
			var parenthesesLevel: Int = 0
			var hasPeriod: Boolean = false
			var index: Int = currentIndex

			while (true) {
				val character: Char = buffer[index]
				if (character == '.') {
					hasPeriod = true
				}
				else if (character == '(') {
					parenthesesLevel += 1
				}
				else if (character == ')') {
					parenthesesLevel -= 1
					if (parenthesesLevel < 0) {
						break
					}
				}
				else if (character == ' ') {
					val nextPart: String = buffer.substring(index).substring(0, " extension.".length + 1).replace("\n", "")
					if (nextPart.startsWith(" extension.")) {
						index = index + 1
						continue
					}
					else {
						break
					}
				}
				else if (character == '\n') {
					val nextCharacter: Char = buffer[index + 1]
					if (nextCharacter == ' ') {
						break
					}
				}
				index = index + 1
			}

			if (!(hasPeriod)) {
				return null
			}

			val string: String = buffer.substring(currentIndex, index)
			val cleanString: String = string.replace("\n", "")

			currentIndex = index

			return cleanString
		}
		finally {
			cleanLeadingWhitespace()
		}
	}

	internal fun readDoubleQuotedString(): String {
		try {
			var isEscaping: Boolean = false
			val firstContentsIndex: Int = currentIndex + 1
			var index: Int = firstContentsIndex

			while (true) {
				val character: Char = buffer[index]
				if (character == '\\') {
					if (isEscaping) {
						isEscaping = false
					}
					else {
						isEscaping = true
					}
				}
				else if (character == '\"') {
					if (isEscaping) {
						isEscaping = false
					}
					else {
						break
					}
				}
				else {
					isEscaping = false
				}
				index = index + 1
			}

			val string: String = buffer.substring(firstContentsIndex, index)
			val cleanString: String = string.replace("\n", "")

			index = index + 1
			currentIndex = index

			return cleanString
		}
		finally {
			cleanLeadingWhitespace()
		}
	}

	internal fun readSingleQuotedString(): String {
		try {
			val firstContentsIndex: Int = currentIndex + 1
			var index: Int = firstContentsIndex

			while (true) {
				val character: Char = buffer[index]
				if (character == '\'') {
					break
				}
				index = index + 1
			}

			val string: String

			if (firstContentsIndex == index) {
				string = "_"
			}
			else {
				string = buffer.substring(firstContentsIndex, index)
			}

			val cleanString: String = string.replace("\n", "")

			index = index + 1
			currentIndex = index

			val otherString: String

			if (buffer[currentIndex] == ',') {
				currentIndex = nextIndex()
				otherString = readStandaloneAttribute()
				return cleanString + "," + otherString
			}
			else {
				return cleanString
			}
		}
		finally {
			cleanLeadingWhitespace()
		}
	}

	internal fun readStringInBrackets(): String {
		try {
			val firstContentsIndex: Int = currentIndex + 1
			var index: Int = firstContentsIndex
			var bracketLevel: Int = 1

			while (true) {
				val character: Char = buffer[index]
				if (character == ']') {
					bracketLevel -= 1
					if (bracketLevel == 0) {
						break
					}
				}
				else if (character == '[') {
					bracketLevel += 1
				}
				index = index + 1
			}

			val string: String = buffer.substring(firstContentsIndex, index)
			val cleanString: String = string.replace("\n", "")

			index = index + 1
			currentIndex = index

			return cleanString
		}
		finally {
			cleanLeadingWhitespace()
		}
	}

	internal fun readStringInAngleBrackets(): String {
		try {
			var index: Int = currentIndex + 1

			while (true) {
				val character: Char = buffer[index]
				if (character == '>') {
					break
				}
				index = index + 1
			}

			index = index + 1

			val string: String = buffer.substring(currentIndex, index)
			val cleanString: String = string.replace("\n", "")

			currentIndex = index

			return cleanString
		}
		finally {
			cleanLeadingWhitespace()
		}
	}
}

private fun ASTDumpDecoder.Companion.decode(decoder: ASTDumpDecoder): SwiftAST {
	val standaloneAttributes: MutableList<String> = mutableListOf()
	val keyValueAttributes: MutableMap<String, String> = mutableMapOf()
	val subtrees: MutableList<SwiftAST> = mutableListOf()

	decoder.readOpeningParenthesis()

	val rawName: String = decoder.readIdentifier()
	val name: String = Utilities.expandSwiftAbbreviation(rawName)

	while (true) {
		val key: String? = decoder.readKey()
		if (decoder.canReadOpeningParenthesis()) {
			val subtree: SwiftAST = decode(decoder = decoder)
			subtrees.add(subtree)
		}
		else if (decoder.canReadClosingParenthesis()) {
			decoder.readClosingParenthesis()
			break
		}
		else if (key != null) {
			val string: String? = decoder.readDeclarationLocation() ?: decoder.readDeclaration()
			if (key == "location") {
				keyValueAttributes[key] = decoder.readLocation()
			}
			else if (string != null && key == "decl") {
				keyValueAttributes[key] = string
			}
			else if (key == "bind") {
				val string: String = decoder.readDeclarationLocation() ?: decoder.readIdentifier()
				keyValueAttributes[key] = string
			}
			else if (key == "inherits") {
				val string: String = decoder.readIdentifierList()
				keyValueAttributes[key] = string
			}
			else {
				keyValueAttributes[key] = decoder.readStandaloneAttribute()
			}
		}
		else {
			val attribute: String = decoder.readStandaloneAttribute()
			standaloneAttributes.add(attribute)
		}
	}

	return SwiftAST(name, standaloneAttributes, keyValueAttributes, subtrees)
}
