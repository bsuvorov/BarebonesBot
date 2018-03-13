import Foundation

let DjangoDateFormat = DateFormatter()
let USDateFormat = DateFormatter()

public class Utils {
    
    public static func dateStringFor(subscriber: Subscriber?) -> String {
        // assume PDT time zone if it is not set.
        let timezone = Double(subscriber?.timezone ?? -8)
        let SECONDS_IN_HOUR: TimeInterval = 60 * 60
        
        let today = Date().addingTimeInterval(timezone * SECONDS_IN_HOUR)
        return DjangoDateFormat.string(from: today)
    }
    
    public static func targetTimeZones(from date:Date) -> (Int?, Int?) {
        
        let hourformatter = DateFormatter()
        hourformatter.dateFormat = "HH"
        hourformatter.timeZone = TimeZone(abbreviation: "UTC")
        let defaultTimeZoneString = hourformatter.string(from: date)
        guard let utcZoneHour = Int(defaultTimeZoneString) else {
            analytics?.logError("Failed to get target time zones from \(defaultTimeZoneString)")
            return (nil, nil)
        }
        
        // ensure we cover timezone of hour overlap.
        // there 26 overall timezones. yeah, right. you're reading it right. not 24.
        // read more https://www.timeanddate.com/time/dateline.html
        let targetTimeZoneTwo = (utcZoneHour >= 20) ? NOTIFICATION_HOUR - utcZoneHour + 24 : nil
        let targetTimeZoneOne = NOTIFICATION_HOUR - utcZoneHour
        
        return (targetTimeZoneOne, targetTimeZoneTwo)
    }
}

public extension Collection {
    /// Convert self to JSON String.
    /// - Returns: Returns the JSON as String or empty string if error while parsing.
    func json() -> String {
        do {
            let jsonData = try JSONSerialization.data(withJSONObject: self, options: [.prettyPrinted])
            guard let jsonString = String(data: jsonData, encoding: String.Encoding.utf8) else {
                print("Can't create string with data.")
                return "{}"
            }
            return jsonString
        } catch let parseError {
            print("json serialization error: \(parseError)")
            return "{}"
        }
    }
}

extension String {
    func split(len: Int) -> [String] {
        return stride(from: 0, to: self.characters.count, by: len).map {
            let start = self.index(self.startIndex, offsetBy: $0)
            let end = self.index(start, offsetBy: len, limitedBy: self.endIndex) ?? self.endIndex
            return String(self[start..<end])
        }
    }
    
    func componentsAppendingSeparators(separatedBy separators: Set<String>) -> [String] {
        let separatorString = "SomeStringThatYouDoNotExpectToOccurInSelf"
        var preparedString: String = self
        
        for separator in separators {
            preparedString = preparedString.replacingOccurrences(of: separator, with: "\(separator)\(separatorString)")
        }
        
        return preparedString.components(separatedBy: separatorString)
            .map { $0.trim() }
            .filter { $0 != "" }
    }
}


extension Formatter {
    static let iso8601: DateFormatter = {
        let formatter = DateFormatter()
        formatter.calendar = Calendar(identifier: .iso8601)
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.timeZone = TimeZone(secondsFromGMT: 0)
        formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSSZ"
        return formatter
    }()
}
extension Date {
    var iso8601: String {
        return Formatter.iso8601.string(from: self)
    }
}

extension String {
    var dateFromISO8601: Date? {
        return Formatter.iso8601.date(from: self)   // "Mar 22, 2017, 10:22 AM"
    }
}
