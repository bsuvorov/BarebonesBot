import Foundation
import Vapor
import HTTP
import Node
import Jay
import Dispatch
import SMTP

extension Droplet {
    
    public func updateMessengerProfileWith(payload: [String: Any]) {
        let data = try! Jay().dataFromJson(anyDictionary: payload)
        let finalJSON = try! JSON(bytes: data)
        let url = "https://graph.facebook.com/v2.6/me/messenger_profile?access_token=\(configHelper.pageAccessToken)"
        let result = try! self.client.post(url, query: [:], ["Content-Type": "application/json"], finalJSON.makeBody(), through: [])
        analytics?.logDebug("Result = \(result)")
    }
    
    public func whiteListDomains() {
        analytics?.logDebug("Whitelisting domains")
        let dict = ["whitelisted_domains": []]
        updateMessengerProfileWith(payload: dict)
    }
    
    public func reinitializeMenu() {
        analytics?.logDebug("Reinitializing menu")
        updateMessengerProfileWith(payload: self.getStartedJSON())
    }
    
    func setupBotRoutes() throws {
        DjangoDateFormat.dateFormat = "yyyy-MM-dd"
        USDateFormat.dateFormat = "MM/dd/yyyy"
        
        get("test") { req in
            return Response(status: Status(statusCode: 200))
        }
        
        get("webhook") { req in
            guard let hubVerifyToken = req.data[DotKey("hub.verify_token")]?.string,
                let hubMode = req.data[DotKey("hub.mode")]?.string,
                let hubChallenge = req.data[DotKey("hub.challenge")]?.string else {
                    throw Abort.unauthorized
            }
            
            let VERIFY_TOKEN = "borisrocks"
            if hubMode == "subscribe" && hubVerifyToken == VERIFY_TOKEN {
                analytics?.logDebug("***Webhook verified***")
                return hubChallenge
            } else {
                throw Abort.badRequest
            }
        }
        
        post("webhook") { req in
            guard req.data["object"]?.string == "page" else {
                analytics?.logError("Entry is not coming from page")
                throw Abort.unauthorized
            }
            
            guard let entryContent = req.data["entry"]?.array else {
                analytics?.logError("Entry is not type of Content")
                throw Abort.unauthorized
            }
            
            for entry in entryContent {
                analytics?.logDebug("Entry=\(entry)")
                if let eventMessage = entry["messaging"]?.array?[0] {
                    guard let senderId = eventMessage["sender.id"]?.string else {
                        throw Abort.badRequest
                    }
                    
                    DispatchQueue.global(qos: DispatchQoS.QoSClass.default).async { [weak self] in
                        guard let welf = self else {
                            return
                        }
                        
                        welf.handleEventMessage(eventMessage, senderId: senderId)
                    }
                    
                } else {
                    analytics?.logError("Uknown entry=\(entry)")
                }
            }
            
            return Response(status: Status(statusCode: 200))
        }
    }
    
    func handleEventMessage(_ eventMessage: Node, senderId: String) {
        guard eventMessage["message"]?["is_echo"] == nil else { return }
        
        if let subscriber = Subscriber.getSubFor(senderId: senderId) {
            if let quickReplyPayload = eventMessage["message"]?["quick_reply"]?["payload"]?.string {
                handleQuickReply(payload: quickReplyPayload, subscriber: subscriber)
            } else if let postbackPayload = eventMessage["postback"]?["payload"]?.string {
                handlePostback(payload: postbackPayload, subscriber: subscriber)
            } else if let incomingMessage = eventMessage["message"], incomingMessage["is_echo"] == nil {
                if let actualText = incomingMessage["text"]?.string {
                    handleIncomeMessage(subscriber: subscriber, incomingMessage: actualText)
                } else if let actualAttachments = incomingMessage["attachments"]?.array {
                    handleAttachments(subscriber: subscriber, attachments: actualAttachments)
                } else {
                    analytics?.logDebug("Entered - incoming message is nil and attachments is nil. Ignore this message.")
                }
            }
            self.updateSubscriber(subscriber, withEventMessage: eventMessage)
            
        } else {
            // assuming brand new user from ad or get started (i.e. #1, #2)
            guard let subscriber = getSubOrUserProfileFor(senderId: senderId) else {
                analytics?.logError("Failed to start onboarding flow")
                return
            }
            self.handleNewUserFlow(subscriber: subscriber)
            self.updateSubscriber(subscriber, withEventMessage: eventMessage)
        }
    }
    
    func updateSubscriber(_ subscriber: Subscriber, withEventMessage eventMessage: Node) {
        subscriber.setLastInteractionWithBotDate(Date())
        subscriber.setDidActOnBroadcastMessage(true)
        updateReferral(for: subscriber, eventMessage: eventMessage)
        
        subscriber.saveIfNedeed()
    }

    func updateReferral(for subscriber: Subscriber, eventMessage: Node) {
        guard
            let refId = eventMessage["postback.referral.ref"]?.string,
            let refType = eventMessage["postback.referral.type"]?.string,
            let refSource = eventMessage["postback.referral.source"]?.string else {
            return
        }
        subscriber.setLastReferral(refId: refId, refType: refType, refSource: refSource)
    }
}
