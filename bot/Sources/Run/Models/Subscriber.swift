import Foundation
import FluentProvider
import Fluent
import Vapor

final public class Subscriber: Model {
    public let storage = Storage()
    
    public static let idKey = "fb_messenger_id"
    
    private var isNeedToSave : Bool = false
    
    public var fb_messenger_id: String
    public let first_name: String
    public let last_name: String
    public let locale: String
    public let timezone: Int
    public let gender: String
    
    public var zodiac_sign: String?
    public var phone_number: Int?
    public var status: String?
    public var did_act_on_broadcast_message: Bool = false
    public var last_interaction_with_bot_at: Int?
    public var last_first_card_selected: String? = nil
    
    public var last_broadcast_message_sent_at: Int?
    public var last_broadcast_status: String?
    
    public var last_ad_referral_source: String?
    public var last_ad_referral_type: String?
    public var last_ad_referral_id: String?
    
    public var last_referral_source: String?
    public var last_referral_type: String?
    public var last_referral_id: String?
    
    public var replied_to_greeting: Bool = false
    
    public var id: Identifier? {
        get {
            return Identifier(.string(self.fb_messenger_id), in: nil)
        }
        set {
            self.fb_messenger_id = (newValue?.string)!
        }
    }
    
    public init(fb_messenger_id: String, first_name: String, last_name: String, locale: String, timezone: Int, gender: String) {
        self.fb_messenger_id = fb_messenger_id
        self.first_name = first_name
        self.last_name = last_name
        self.locale = locale
        self.timezone = timezone
        self.gender = gender
        self.last_broadcast_message_sent_at = 0
        self.last_interaction_with_bot_at = Int(Date().timeIntervalSince1970)
        self.status = SubscriberStatus.subscribed.rawValue
    }
    
    public init(row: Row) throws {
        fb_messenger_id = try row.get("fb_messenger_id")
        first_name = try row.get("first_name")
        last_name = try row.get("last_name")
        locale = try row.get("locale")
        timezone = try row.get("timezone")
        gender = try row.get("gender")
        zodiac_sign = try row.get("zodiac_sign")
        phone_number = try row.get("phone_number")
        status = try row.get("status")
        last_first_card_selected = try row.get("last_first_card_selected")
        last_interaction_with_bot_at = try row.get("last_interaction_with_bot_at")
        last_broadcast_message_sent_at = try row.get("last_broadcast_message_sent_at")
        last_broadcast_status = try row.get("last_broadcast_status")
        last_ad_referral_source = try row.get("last_ad_referral_source")
        last_ad_referral_type = try row.get("last_ad_referral_type")
        last_ad_referral_id = try row.get("last_ad_referral_id")
        did_act_on_broadcast_message = try row.get("did_act_on_broadcast_message")
        replied_to_greeting = try row.get("replied_to_greeting")
        last_referral_source = try row.get("last_referral_source")
        last_referral_type = try row.get("last_referral_type")
        last_referral_id = try row.get("last_referral_id")
    }
    
    public func makeRow() throws -> Row {
        var row = Row()
        
        try row.set("fb_messenger_id", fb_messenger_id)
        try row.set("first_name", first_name)
        try row.set("last_name", last_name)
        try row.set("locale", locale)
        try row.set("timezone", timezone)
        try row.set("gender", gender)
        try row.set("zodiac_sign", zodiac_sign)
        try row.set("phone_number", phone_number)
        try row.set("status", status)
        try row.set("last_first_card_selected", last_first_card_selected)
        try row.set("last_interaction_with_bot_at", last_interaction_with_bot_at)
        try row.set("last_broadcast_message_sent_at", last_broadcast_message_sent_at)
        try row.set("last_broadcast_status", last_broadcast_status)
        try row.set("last_ad_referral_source", last_ad_referral_source)
        try row.set("last_ad_referral_type", last_ad_referral_type)
        try row.set("last_ad_referral_id", last_ad_referral_id)
        try row.set("did_act_on_broadcast_message", did_act_on_broadcast_message)
        try row.set("replied_to_greeting", replied_to_greeting)
        try row.set("last_referral_source", last_referral_source)
        try row.set("last_referral_type", last_referral_type)
        try row.set("last_referral_id", last_referral_id)
        
        return row
    }
    
    public func toDictionary() -> [String: Any] {
        var dict: [String: Any] = [
            "fb_messenger_id": fb_messenger_id,
            "first_name": first_name,
            "last_name": last_name,
            "locale": locale,
            "timezone": timezone,
            "gender": gender,
            "replied_to_greeting": self.replied_to_greeting
        ]
        
        if let result = self.zodiac_sign {
            dict["zodiac_sign"] = result
        }

        dict["last_first_card_selected"] = last_first_card_selected
        dict["last_interaction_with_bot_at"] = last_interaction_with_bot_at
        dict["last_broadcast_status"] = last_broadcast_status
        dict["last_ad_referral_source"] = last_ad_referral_source
        dict["last_ad_referral_type"] = last_ad_referral_type
        dict["last_ad_referral_id"] = last_ad_referral_id
        dict["last_referral_source"] = last_referral_source
        dict["last_referral_type"] = last_referral_type
        dict["last_referral_id"] = last_referral_id
        
        if let createdDate = self.createdAt {
            let age = Int(Date().timeIntervalSince(createdDate) / (60 * 60 * 24))
            dict["age_days"] = age
            dict["age_weeks"] = Int(age / 7)
            dict["age_quarters"] = Int(age / 91)
        }
        
        return dict
    }
    
    static public func getSubscriberWith(zodiacSign: String, limit: Int, lastBroadcastSentBeforeDate: Int, timeZone: Int) -> ([Subscriber]?) {
        do {
            let results = try Subscriber.makeQuery()
                .filter("zodiac_sign" == zodiacSign)
                .filter("last_broadcast_message_sent_at" <= lastBroadcastSentBeforeDate)
                .filter("timezone" == timeZone)
                .filter("status" != SubscriberStatus.unsubscribed.rawValue)
                .limit(limit)
                .all()
            return results
        } catch let error {
            print("\(#function) Failed execute fluent / node stuff. Error = \(error)")
        }
        
        return nil
    }
    
    static public func getSubscriberWith(zodiacSign: String, lastBroadcastSentBeforeDate: Int, timeZone: Int, closure: (([Subscriber]) -> ())) {
        do {
            try Subscriber.makeQuery()
                .filter("zodiac_sign" == zodiacSign)
                .filter("last_broadcast_message_sent_at" <= lastBroadcastSentBeforeDate)
                .filter("timezone" == timeZone)
                .filter("status" != SubscriberStatus.unsubscribed.rawValue)
                .chunk(50, closure)
        } catch let error {
            analytics?.logDebug("\(#function) Failed execute fluent / node stuff. Error = \(error)")
            analytics?.logException(error)
        }
    }
    
    static public func chunkedNonMutableGetSubscribersWith(timeZone: Int, closure: (([Subscriber]) -> ())) {
        do {
            try Subscriber.makeQuery()
                .filter("timezone" == timeZone)
                .chunk(50, closure)
        } catch let error {
            analytics?.logDebug("\(#function) Failed execute fluent / node stuff. Error = \(error)")
            analytics?.logException(error)
        }
    }
    
    static public func countSubscribedUsersIgnoringBroadcastAfter(broadcastDate: Int) -> Int? {
        do {
            return try Subscriber.makeQuery()
                .filter("status" == SubscriberStatus.subscribed.rawValue)
                .filter("last_interaction_with_bot_at" <= broadcastDate)
                .count()
        } catch let error {
            analytics?.logDebug("\(#function) Failed execute fluent / node stuff. Error = \(error)")
            analytics?.logException(error)
        }
        return nil
    }
    
    static public func countOfSubscribersWith(status: SubscriberStatus) -> Int? {
        do {
            return try Subscriber.makeQuery()
                .filter("status" == status.rawValue)
                .count()
        } catch let error {
            analytics?.logDebug("\(#function) Failed execute fluent / node stuff. Error = \(error)")
            analytics?.logException(error)
        }
        return nil
    }
    
    static public func countOfSubscribers() -> Int? {
        do {
            return try Subscriber.makeQuery()
                .count()
        } catch let error {
            analytics?.logDebug("\(#function) Failed execute fluent / node stuff. Error = \(error)")
            analytics?.logException(error)
        }
        return nil
    }
}

extension Subscriber: Preparation {
    public static func prepare(_ database: Database) throws {
        try database.create(self) { subscribers in
            subscribers.string("fb_messenger_id", length: nil, optional: false, unique: true, default: nil)
            subscribers.string("first_name")
            subscribers.string("last_name")
            subscribers.string("locale")
            subscribers.string("timezone")
            subscribers.string("gender")
            subscribers.string("zodiac_sign", length: 255, optional: true, unique: false, default: nil)
            subscribers.int("phone_number", optional: true, unique: false, default: nil)
            subscribers.string("status", length: 255, optional: true, unique: false, default: nil)
            subscribers.string("last_first_card_selected", optional: true, unique: false, default: nil)
            subscribers.int("last_interaction_with_bot_at", optional: false, unique: false, default: 0)
            subscribers.int("last_broadcast_message_sent_at", optional: false, unique: false, default: 0)
            subscribers.string("last_broadcast_status", length: 255, optional: true, unique: false, default: nil)
            subscribers.string("last_ad_referral_source", length: 255, optional: true, unique: false, default: nil)
            subscribers.string("last_ad_referral_type", length: 255, optional: true, unique: false, default: nil)
            subscribers.string("last_ad_referral_id", length: 255, optional: true, unique: false, default: nil)
            subscribers.bool("did_act_on_broadcast_message", optional: false, unique: false, default: false)
            subscribers.bool("replied_to_greeting", optional: false, unique: false, default: false)
            subscribers.string("last_referral_source", length: 255, optional: true, unique: false, default: nil)
            subscribers.string("last_referral_type", length: 255, optional: true, unique: false, default: nil)
            subscribers.string("last_referral_id", length: 255, optional: true, unique: false, default: nil)
        }
    }
    
    public static func revert(_ database: Database) throws {
        try database.delete(self)
    }
}

extension Subscriber: Timestampable { }

extension Subscriber {
    
    func durationSinceLastBroadcastWasSent() -> Int? {
        guard
            did_act_on_broadcast_message == false,
            let lastBroadcastTs = last_broadcast_message_sent_at,
            lastBroadcastTs != 0 else {
                return nil
        }
        let interval = Int(Date().timeIntervalSince1970) - lastBroadcastTs
        return interval
    }
}

public extension Subscriber {
    public static func getSubFor(senderId: String) -> Subscriber? {
        do {
            return try Subscriber.find(senderId)
        } catch let error {
            print("Failed to get user from database with error=\(error)")
        }
        return nil
    }
}

public extension Subscriber {
    public func setSign(_ sign: String) {
        guard self.zodiac_sign != sign else { return }
        
        self.zodiac_sign = sign
        self.isNeedToSave = true
    }
    
    public func setStatus(_ status: SubscriberStatus) {
        if self.status != status.rawValue {
            self.status = status.rawValue
            self.isNeedToSave = true
        }
    }
    
    public func setLastInteractionWithBotDate(_ date: Date) {
        self.last_interaction_with_bot_at = Int(date.timeIntervalSince1970)
        self.isNeedToSave = true
    }
    
    public func setLastBroadcastMessageSentDate(_ date: Date) {
        self.last_broadcast_message_sent_at = Int(date.timeIntervalSince1970)
        self.isNeedToSave = true
    }
    
    public func setDidActOnBroadcastMessage(_ didAct: Bool) {
        guard self.did_act_on_broadcast_message != didAct else { return }
        self.did_act_on_broadcast_message = didAct
        self.isNeedToSave = true
    }
    
    public func setLastReferral(refId: String, refType: String, refSource: String) {
        self.last_referral_id = refId
        self.last_referral_type = refType
        self.last_referral_source = refSource
        self.isNeedToSave = true
    }
    
    public func setRepliedToGreeting(_ isReplied: Bool) {
        self.replied_to_greeting = isReplied
        self.isNeedToSave = true
    }
    
    public func saveIfNedeed() {
        guard self.isNeedToSave else { return }
        
        do {
            try self.save()
            self.isNeedToSave = false
        } catch let error {
            print("Failed to save user for \(fb_messenger_id), error=\(error)")
        }
    }
}
