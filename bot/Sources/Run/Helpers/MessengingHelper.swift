import Foundation
import HTTP
import Jay
import Dispatch

public let DEFAULT_MESSAGING_TYPING_DELAY: Double = 2

public enum MessagingType: String {
    case RESPONSE
    case UPDATE
    case NON_PROMOTIONAL_SUBSCRIPTION
}

extension Droplet {
    
    @discardableResult func send(message: String, senderId: String, messagingType: MessagingType, quickReplies: [[String: Any]]? = nil) -> Response? {
        
        var textJSON: [String: Any] = ["text": message]
        if let replies = quickReplies {
            textJSON["quick_replies"] = replies
        }
        return send(messageJSON: textJSON, senderId: senderId, messagingType: messagingType)
    }
    
    @discardableResult func send(attachment: [String: Any], senderId: String, messagingType: MessagingType, quickReplies: [[String: Any]]? = nil) -> Response? {
        
        var attachmentJSON: [String: Any] = ["attachment": attachment]
        if let replies = quickReplies {
            attachmentJSON["quick_replies"] = replies
        }
        return send(messageJSON: attachmentJSON, senderId: senderId, messagingType: messagingType)
    }
    
    @discardableResult private func send(messageJSON: [String: Any], senderId: String, messagingType: MessagingType, quickReplies: [[String: Any]]? = nil) -> Response? {
        
        let targetJSON:[String : Any] = ["messaging_type": messagingType.rawValue,
                                         "recipient": ["id": senderId],
                                         "message": messageJSON]
        return sendGenericMessageDict(dict: targetJSON)
    }
    
    @discardableResult public func sendTyping(isOn: Bool, senderId: String) -> Response? {
        let action = isOn ? "typing_on" : "typing_off"
        let targetJSON:[String: Any] = ["messaging_type": MessagingType.RESPONSE.rawValue,
                                        "recipient": ["id": senderId],
                                        "sender_action": action]
        return sendGenericMessageDict(dict: targetJSON)
    }

    func sendResponseWithTyping(messages: [String],
                                senderId: String,
                                delay: Double = DEFAULT_MESSAGING_TYPING_DELAY,
                                completion: @escaping () -> ()) {
        sendTyping(isOn: true, senderId: senderId)
        
        for (index, message) in messages.enumerated() {
            DispatchQueue.global().asyncAfter(deadline: .now() + delay * Double(index + 1)) { [weak self] in
                guard let welf = self else { return }
                
                welf.send(message: message, senderId: senderId, messagingType: .RESPONSE)
                welf.sendTyping(isOn: true, senderId: senderId)
                
                if (index == messages.count - 1) {
                    completion()
                }
            }
        }

    }
    
    func sendResponseWithTyping(messages: [String],
                                senderId: String,
                                quickReplies: [[String: Any]],
                                delay: Double = DEFAULT_MESSAGING_TYPING_DELAY) {
        
        sendTyping(isOn: true, senderId: senderId)
        
        for (index, message) in messages.enumerated() {
            DispatchQueue.global().asyncAfter(deadline: .now() + delay * Double(index + 1)) { [weak self] in
                guard let welf = self else { return }

                if (index < messages.count - 1) {
                    // If message is not last, send message and enable typing
                    welf.send(message: message, senderId: senderId, messagingType: .RESPONSE)
                    welf.sendTyping(isOn: true, senderId: senderId)
                } else {
                    // If message is last, send message with quickReplies
                    welf.send(message: message,
                              senderId: senderId,
                              messagingType: .RESPONSE,
                              quickReplies: quickReplies)
                }
            }
        }
    }
    
    private func getBroadcastMessageCreativeFrom(creativeMessageJSON: [String: Any]) -> String? {
        let endpoint = "message_creatives"
        let version = "v2.11"
        let response = sendGenericMessageDict(dict: creativeMessageJSON, endpoint: endpoint, version: version)
        guard let json = response?.json else { return nil }
        guard let messageCreativeId = json["message_creative_id"]?.string else { return nil }
        
        return messageCreativeId
    }
    
    @discardableResult private func getBroadcastMessageCreativeFrom(title: String, imageUrl: String, subtitle: String, linkUrl: String, linkTitle: String) -> String? {
        let messageCreativeJSON = broadcastCreativeMessageJSON(title: title,
                                                               imageUrl: imageUrl,
                                                               subtitle: subtitle,
                                                               linkUrl: linkUrl,
                                                               linkTitle: linkTitle)
        
        return getBroadcastMessageCreativeFrom(creativeMessageJSON: messageCreativeJSON)
    }
    
    @discardableResult func sendBroadcastMessageWith(messageCreativeId: String, notificationType: String = "REGULAR", tag: String = "FEATURE_FUNCTIONALITY_UPDATE") -> Response? {
        
        let message = broadcastMessageJSON(messageCreativeId: messageCreativeId,
                                           notificationType: notificationType,
                                           tag: tag)
        let endpoint = "broadcast_messages"
        let version = "v2.11"
        return sendGenericMessageDict(dict: message, endpoint: endpoint, version: version)
    }
    
    @discardableResult func sendBroadcastMessage(title: String, imageUrl: String, subtitle: String, linkUrl: String, linkTitle: String) -> Response? {
        guard let messageCreativeId = getBroadcastMessageCreativeFrom(title: title,
                                                                      imageUrl: imageUrl,
                                                                      subtitle: subtitle,
                                                                      linkUrl: linkUrl,
                                                                      linkTitle: linkTitle) else { return nil }
        return self.sendBroadcastMessageWith(messageCreativeId: messageCreativeId)
    }
    
    @discardableResult func send(attachmentId: String, senderId: String, messagingType: MessagingType, quickReplies: [[String: Any]]? = nil, type: String = "image") -> Response? {
        let attachment = self.mediaTemplateAttachment(attachmentId: attachmentId, type: type)
        return self.send(attachment: attachment,
                         senderId: senderId,
                         messagingType: messagingType)
    }
    
    @discardableResult func uploadAttachment(dict: [String: Any]) -> Response? {
        return sendGenericMessageDict(dict: dict, endpoint: "message_attachments")
    }
    
    @discardableResult private func sendGenericMessageDict(dict: [String: Any], endpoint: String = "messages", version: String = "v2.6") -> Response? {
        let url = "https://graph.facebook.com/\(version)/me/\(endpoint)?access_token=\(configHelper.pageAccessToken)"
        do {
            let data = try Jay().dataFromJson(anyDictionary: dict)
            let finalJSON = try JSON(bytes: data)
            let start = Date().timeIntervalSince1970
            let result = try self.client.post(url, query: [:], ["Content-Type": "application/json"], finalJSON.makeBody(), through: [])
            let duration = Int(1000*(Date().timeIntervalSince1970 - start))
            analytics?.logResponse(result, endpoint: endpoint, duration: duration)
            if result.status != .ok {
                analytics?.logError("Error when sending to \(endpoint) generic message dict \(dict), result = \(result)")
            }
            return result
        } catch let error {
            analytics?.logError("Error when sending to \(endpoint) generic message dict \(dict)")
            analytics?.logException(error)
        }
        return nil
    }
}
