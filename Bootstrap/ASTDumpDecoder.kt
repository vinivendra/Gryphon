class ASTDumpDecoder {
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

		val description: String
			get() {
				return when (this) {
					is ASTDumpDecoder.DecodingError.UnexpectedContent -> {
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

	internal fun canReadOpeningBracket(): Boolean {
		return buffer[currentIndex] == '['
	}

	internal fun canReadClosingBracket(): Boolean {
		return buffer[currentIndex] == ']'
	}

	internal fun canReadOpeningBrace(): Boolean {
		return buffer[currentIndex] == '{'
	}

	internal fun canReadClosingBrace(): Boolean {
		return buffer[currentIndex] == '}'
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
}