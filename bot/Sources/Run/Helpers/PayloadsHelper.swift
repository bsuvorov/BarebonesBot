import Foundation
import Jay
import HTTP

public extension Droplet {
        
    func genericUploadMessage(type: String, url: String) -> [String: Any] {
        return [
            "message": [
                "attachment":[
                    "type":type,
                    "payload":
                        ["is_reusable": true,
                         "url": url
                    ]
                ]
            ]
        ]
    }
    
    func broadcastCreativeMessageJSON(title: String, imageUrl: String, subtitle: String, linkUrl: String, linkTitle: String) -> [String: Any] {
        let button = ["type": "web_url", "url": linkUrl, "title": linkTitle]
        let elements: [String : Any] = ["title": title,
                                        "subtitle": subtitle,
                                        "image_url": imageUrl,
                                        "buttons": [button]]
        let attachment = genericShortAttachment(elements: [elements])
        
        return ["messages": [attachment]]
    }
    
    func broadcastMessageJSON(messageCreativeId: String, notificationType: String, tag: String) -> [String: Any] {
        return ["message_creative_id": messageCreativeId,
                "notification_type": notificationType,
                "tag": tag
        ]
    }
    
    func mediaTemplateAttachment(attachmentId: String, type: String = "image", buttons: [[String: Any]]? = nil) -> [String: Any] {
        var elements: [String: Any] = ["media_type": type,
                                       "attachment_id": attachmentId]
        
        if let mediaButtons = buttons {
            elements["buttons"] = mediaButtons
        }
        
        return ["type": "template",
                "payload": [
                    "template_type": "media",
                    "elements": [elements]
            ]
        ]
    }
    
    func genericButtonsAttachment(message: String, buttons: [[String: Any]]) -> [String: Any] {
        return ["type": "template",
                "payload":
                    ["template_type": "button",
                     "text": message,
                     "buttons": buttons
            ]
        ]
    }
    
    func genericShortAttachment(elements: [[String: Any]]) -> [String: Any] {
        return ["attachment":
            ["type": "template",
             "payload":
                ["template_type": "generic",
                 "elements": elements
                ]
            ]
        ]
    }
    
    func genericAttachment(elements: [[String: Any]]) -> [String: Any] {
        return ["type": "template",
                "payload":
                    ["template_type": "generic",
//                     "image_aspect_ratio": "square",
                     "elements": elements
            ]
        ]
    }
    
    func listAttachment(elements: [[String: Any]]) -> [String: Any] {
        return ["type": "template",
                "payload":
                    ["template_type": "list",
                     "top_element_style": "LARGE",
                     "elements": elements
            ]
        ]
    }
}

