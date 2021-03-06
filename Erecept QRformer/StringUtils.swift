import Foundation

extension String {
    // Extracts the first receipt ID found in the string, returning
    // the range of the ID and the ID itself as a tuple.
    // Returns nil if no number is found.
    func extractID() -> (Range<String.Index>, String)? {

        let pattern = #"""
        ([P]\w{3}[ -]?\w{4}[ -]?\w{4})
        """#
        
        guard let range = self.range(of: pattern, options: .regularExpression, range: nil, locale: nil) else {
            // No ID found.
            return nil
        }
        
        // Potential ID found.
        var potentialID = ""
        let substring = String(self[range])
        let nsrange = NSRange(substring.startIndex..., in: substring)
        do {
            // Extract the characters from the substring.
            let regex = try NSRegularExpression(pattern: pattern, options: [])
            if let match = regex.firstMatch(in: substring, options: [], range: nsrange) {
                for rangeInd in 1 ..< match.numberOfRanges {
                    let range = match.range(at: rangeInd)
                    let matchString = (substring as NSString).substring(with: range)
                    potentialID += matchString as String
                }
            }
        } catch {
            print("Error \(error) when creating pattern")
        }
        
        let result = potentialID.correctString()
        return (range, result)
    }
    
    func correctString() -> String {
        var newString = self.replacingOccurrences(of: " ", with: "")
        newString = newString.replacingOccurrences(of: "1", with: "I")
        newString = newString.replacingOccurrences(of: "0", with: "O")
        return newString
    }
}

class StringTracker {
    var frameIndex: Int64 = 0

    typealias StringObservation = (lastSeen: Int64, count: Int64)
    
    // Dictionary of seen strings. Used to get stable recognition before
    // displaying anything.
    var seenStrings = [String: StringObservation]()
    var bestCount = Int64(0)
    var bestString = ""

    func logFrame(strings: [String]) {
        for string in strings {
            if seenStrings[string] == nil {
                seenStrings[string] = (lastSeen: Int64(0), count: Int64(-1))
            }
            seenStrings[string]?.lastSeen = frameIndex
            seenStrings[string]?.count += 1
            //print("Seen \(string) \(seenStrings[string]?.count ?? 0) times")
        }
    
        var obsoleteStrings = [String]()

        // Go through strings and prune any that have not been seen in while.
        // Also find the (non-pruned) string with the greatest count.
        for (string, obs) in seenStrings {
            // Remove previously seen text after 30 frames (~1s).
            if obs.lastSeen < frameIndex - 30 {
                obsoleteStrings.append(string)
            }
            
            // Find the string with the greatest count.
            let count = obs.count
            if !obsoleteStrings.contains(string) && count > bestCount {
                bestCount = Int64(count)
                bestString = string
            }
        }
        // Remove old strings.
        for string in obsoleteStrings {
            seenStrings.removeValue(forKey: string)
        }
        
        frameIndex += 1
    }
    
    func getStableString() -> String? {
        // Require the recognizer to see the same string at least 10 times.
        if bestCount >= 10 {
            return bestString
        } else {
            return nil
        }
    }
    
    func reset(string: String) {
        seenStrings.removeValue(forKey: string)
        bestCount = 0
        bestString = ""
    }
}
