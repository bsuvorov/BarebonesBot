import Foundation
import Vapor

extension Droplet {
    
    func handlePostback(payload: String, subscriber: Subscriber) {
        analytics?.logDebug("Payload = \(payload)")
        let postback = String(payload.split(separator: "|")[0])
        
        if postback == POSTBACK_GET_STARTED {
            self.handleNewUserFlow(subscriber: subscriber)
            
        } else if postback == POSTBACK_UNSUBSCRIBE_RESUBSCRIBE {
            handleUnsubscribeResubscribe(subscriber: subscriber)
            
        } else {
            analytics?.logDebug(postback)
        }
    }
    
    func handleUnsubscribeResubscribe(subscriber: Subscriber) {
        if SubscriberStatus.isSubscribeMessage(subscriber.status ?? "") {
            handleUnsubscribe(subscriber: subscriber)
        } else {
            handleSubscribe(subscriber: subscriber)
        }
    }
    
    func handleSubscribe(subscriber: Subscriber) {
        analytics?.logDebug("Entered - subscribe selected flow. Subscribe user.")
        subscriber.setStatus(.subscribed)
        subscriber.saveIfNedeed()
        self.send(message: "You are subscribed.",
                  senderId: subscriber.fb_messenger_id,
                  messagingType: .RESPONSE)
        analytics?.logAnalytics(event: .SubscribeRequested, for: subscriber)
    }
    
    func handleUnsubscribe(subscriber: Subscriber) {
        analytics?.logDebug("Entered - unsubscribe selected flow. Unsubscribe user.")
        subscriber.setStatus(.unsubscribed)
        subscriber.saveIfNedeed()
        self.send(message: "You just unsubscribed from daily notifications.",
                  senderId: subscriber.fb_messenger_id,
                  messagingType: .RESPONSE)
        analytics?.logAnalytics(event: .UnsubscribeRequested, for: subscriber)
    }
    
    public func handleNewUserFlow(subscriber: Subscriber) {
        analytics?.logDebug("Entered - new user flow")
        analytics?.logAnalytics(event: .NewUserRegistered, for: subscriber)
        
        let message = "Hi, \(subscriber.first_name)! \n\nWelcome to Bot!"
        self.send(message: message,
                  senderId: subscriber.fb_messenger_id,
                  messagingType: .RESPONSE)
    }
}
