import Foundation

public enum SubscriberStatus: String {
    case unsubscribed
    case subscribed
    
    func commands() -> Set<String> {
        switch self {
        case .unsubscribed:
            return ["unsubscribe", "unsubscribed", "stop"]
        case .subscribed:
            return ["subscribe", "subscribed", "start", "run", "NULL"]
        }
    }
    
    static func isUnsubscribeMessage(_ message: String) -> Bool {
        return unsubscribed.commands().contains(message.lowercased())
    }
    
    static func isSubscribeMessage(_ message: String) -> Bool {
        return subscribed.commands().contains(message.lowercased())
    }
}
