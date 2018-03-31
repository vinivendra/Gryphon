import Foundation

/////////// Examples ///////////////////////////////////////////////////////////
//
//// Search for matches:
//
//for match in text =~ "__([^_]+)__" {
//	print(match)	// Prints info on the match and the capture groups
//}
//
//// Replace text:
//
//text =~ "__([^_]+)__" => "\\textbf{$1}"

////////////////////////////////////////////////////////////////////////////////
// MARK: API
infix operator =~: CastingPrecedence
infix operator =>: RangeFormationPrecedence	// just above CastingPrecedence

extension String {
	// Regex search
	static func =~ (string: String, regexString: String) -> RegexIterator {
		do {
			let regex = try NSRegularExpression(pattern: regexString,
												options: [])

			let stringRange = NSRange(location: 0,
									  length: string.count)

			let matches = regex.matches(in: string,
										options: [],
										range: stringRange)

			return RegexIterator(originalText: string, matches: matches)
		} catch {
			return RegexIterator.empty
		}
	}

	// Regex substitution
	static func => (regex: String, substitutionPattern: String)
		-> RegexSubstitution
	{
		return RegexSubstitution(regexPattern: regex,
								 substitutionPattern: substitutionPattern)
	}

	/// Result doesn't indicate matches exist, only that no errors were thrown
	@discardableResult
	static func =~ (string: inout String,
					regexSubstitution: RegexSubstitution) -> Bool
	{
		do {
			let regex = try NSRegularExpression(
				pattern: regexSubstitution.regexPattern,
				options: [])

			let stringRange = NSRange(location: 0,
									  length: string.count)

			string = regex.stringByReplacingMatches(
				in: string,
				options: [],
				range: stringRange,
				withTemplate: regexSubstitution.substitutionPattern)

			return true
		} catch {
			return false
		}
	}
}

////////////////////////////////////////////////////////////////////////////////
// MARK: Implementation

struct RegexSubstitution {
	fileprivate let regexPattern: String
	fileprivate let substitutionPattern: String
}

struct RegexIterator: Sequence, IteratorProtocol {
	private let originalText: String
	private var iterator: IndexingIterator<[NSTextCheckingResult]>

	fileprivate static let empty = RegexIterator(originalText: "", matches: [])

	fileprivate init(originalText: String, matches: [NSTextCheckingResult]) {
		self.originalText = originalText
		self.iterator = matches.makeIterator()
	}

	public func makeIterator() -> RegexIterator {
		return self
	}

	public mutating func next() -> RegexMatch? {
		guard let match = iterator.next() else { return nil }
		return RegexMatch(originalText: originalText, match: match)
	}
}

/**
A match for a regex. Includes the string that was matched, its range in the
original index, as well as any capture groups the match might contain.
**/
struct RegexMatch: CustomStringConvertible {
	// API
	public let numberOfCaptureGroups: Int

	public var matchedString: String {
		return captureGroup(0)!.matchedString
	}

	public var matchedRange: NSRange {
		return captureGroup(0)!.matchedRange
	}

	/**
	Capture group 0 is the whole match. The others are equivalent to perl's
	$1, $2, $3, etc.
	**/
	public func captureGroup(_ index: Int) -> CaptureGroup? {
		guard index < match.numberOfRanges else { return nil }

		let range = match.range(at: index)

		guard range.location != NSNotFound else { return nil }

		let ns = originalText as NSString
		let substring = ns.substring(with: range)
		let matchedString = substring as String

		return CaptureGroup(matchedString: matchedString,
							matchedRange: range)
	}

	// Implementation
	private let originalText: String
	private let match: NSTextCheckingResult

	fileprivate init(originalText: String, match: NSTextCheckingResult) {
		self.originalText = originalText
		self.match = match
		self.numberOfCaptureGroups = match.numberOfRanges - 1
	}

	public var description: String {
		var result: String

		let header = "Regex match at \(match.range) with \(match.numberOfRanges - 1) capture groups:\n"
		let matchedString = "\t\(captureGroup(0)!)\n"

		result = header + matchedString

		var i = 1
		while i < match.numberOfRanges {
			let capturedString = "\t$\(i): \(captureGroup(i)!)\n"
			result += capturedString

			i += 1
		}

		return result
	}
}

/// The contents of a capture group for a match in a regular expression.
struct CaptureGroup: CustomStringConvertible {
	/// The substring that was captured.
	public let matchedString: String
	/// The range of the captured substring in the original text.
	public let matchedRange: NSRange

	public var description: String {
		return "\"\(matchedString)\""
	}
}

