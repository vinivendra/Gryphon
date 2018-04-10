internal extension String {
    /// Ignores empty substrings
    func split(separator: String) -> [String] {
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
        if !separators.isEmpty {
            let substring = self[previousIndex..<endIndex]
            if !substring.isEmpty {
                result.append(String(substring))
            }
        }
        
        return result
    }
    
    /// Non-overlapping
    func occurrences(of substring: String) -> [Range<String.Index>] {
        var result = [Range<String.Index>]()
        var currentIndex = startIndex
        while let range = range(of: substring, startingAt: currentIndex) {
            result.append(range)
            currentIndex = range.upperBound
        }
        return result
    }
    
    func range(of substring: String) -> Range<String.Index>? {
        return range(of: substring, startingAt: startIndex)
    }
    
    private func range(of substring: String, startingAt startingIndex: String.Index) -> Range<String.Index>? {
        var j = substring.startIndex
        var lowerBound: String.Index? = nil
        
        var i = startingIndex
        while i != endIndex {
            defer { i = index(after: i) }
            
            if self[i] == substring[j] {
                if lowerBound == nil {
                    lowerBound = i
                }
                
                j = substring.index(after: j)
                if j == substring.endIndex {
                    let upperBound = self.index(after: i)
                    let rangeBounds = (lower: lowerBound!, upper: upperBound)
                    return Range<String.Index>(uncheckedBounds: rangeBounds)
                }
            }
            else {
                j = substring.startIndex
                lowerBound = nil
            }
        }
        
        assert(lowerBound == nil)
        return nil
    }
}
