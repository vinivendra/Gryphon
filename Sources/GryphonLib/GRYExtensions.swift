internal extension String {
    /// Ignores empty substrings
    func split(withStringSeparator separator: String) -> [String] {
        var result = [String]()
        
        var previousIndex = startIndex
        let separators = self.occurrences(of: separator)
        
        // Add all substrings immediately before each separator
        for separator in separators {
            defer { previousIndex = separator.upperBound }
            
            let substring = self[previousIndex..<separator.lowerBound]
            guard !substring.isEmpty else { continue }
            
            result.append(String(substring))
        }
        
        // Add the last substring (which the loop above ignores)
        let substring = self[previousIndex..<endIndex]
        if !substring.isEmpty {
            result.append(String(substring))
        }
        
        return result
    }
    
    /// Non-overlapping
    func occurrences(of substring: String) -> [Range<String.Index>] {
        var result = [Range<String.Index>]()
        
        var currentRange = Range<String.Index>(uncheckedBounds:
            (lower: startIndex, upper: endIndex))
        
        while let foundRange = self.range(of: substring, range: currentRange) {
            result.append(foundRange)
            currentRange = Range<String.Index>(uncheckedBounds:
                (lower: foundRange.upperBound, upper: endIndex))
        }
        return result
    }
}
