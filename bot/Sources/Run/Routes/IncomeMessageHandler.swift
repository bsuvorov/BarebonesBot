import Foundation

extension Droplet {
    
    func handleIncomeMessage(subscriber: Subscriber, incomingMessage: String? = nil) {
        analytics?.logDebug("Entered - existing user flow")
        if let message = incomingMessage {
            
            analytics?.logIncomingMessage(subscriber: subscriber, message: message)
            
            self.send(message: "I'm not sure what you mean, try saying \"Go\"",
                      senderId: subscriber.fb_messenger_id,
                      messagingType: .RESPONSE)
            
        } else {
            analytics?.logDebug("Entered - incoming message is nil. Ignore this message.")
        }
    }
}
