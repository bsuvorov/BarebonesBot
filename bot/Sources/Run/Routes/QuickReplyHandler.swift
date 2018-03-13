import Foundation

extension Droplet {
    
    func handleQuickReply(payload: String, subscriber: Subscriber) {
        analytics?.logDebug("Quick reply payload = \(payload)")
        let quickReply = String(payload.split(separator: "|")[0])
        
        analytics?.logDebug(quickReply)
    }
}
