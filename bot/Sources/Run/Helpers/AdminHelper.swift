import Foundation
import HTTP

public extension Droplet {
   
    public func getAttachmentIdFor(url: String, type: String = "image") -> String? {
        do {
            if let upload = try MediaUpload.find(url) {
                return upload.attachmentId
            }

            let uploadImageRequest = self.genericUploadMessage(type: type, url: url)
            let uploadResponse = self.uploadAttachment(dict: uploadImageRequest)
            guard let attachmentId = uploadResponse?.json?["attachment_id"]?.string else {
                return nil
            }
            let upload = MediaUpload(mediaUrl: url, attachmentId: attachmentId)
            try upload.save()
            return attachmentId
        } catch let error {
            analytics?.logError("Failed to upload or save image attachment for url = \(url), error=\(error)")
            analytics?.logException(error,  dict: ["endpoint": "message_attachments"])
            return nil
        }
    }
    
    func getUserProfile(senderId: String) throws -> Subscriber? {
        var sub: Subscriber? = try Subscriber.find(senderId)
        if (sub == nil) {
            let fieldsString = ["first_name", "last_name", "locale", "timezone", "gender", "last_ad_referral"].joined(separator: ",")
            let url = "https://graph.facebook.com/v2.6/\(senderId)?fields=\(fieldsString)&access_token=\(configHelper.pageAccessToken)"
            
            let (response, duration) = try timedGet(url)
            analytics?.logResponse(response, endpoint: "user_profile", dict: ["senderId": senderId], duration: duration)
            guard response.status == .ok || response.status == .gatewayTimeout else {
                analytics?.logError("Failed to get user for \(senderId), with response = \(response)")
                return nil
            }
            
            if response.status == .gatewayTimeout {
                let (response, duration) = try timedGet(url)
                analytics?.logResponse(response, endpoint: "user_profile", dict: ["senderId": senderId], duration: duration)
                guard response.status == .ok else {
                    let fieldsString = ["first_name", "timezone", "last_ad_referral"].joined(separator: ",")
                    let url = "https://graph.facebook.com/v2.6/\(senderId)?fields=\(fieldsString)&access_token=\(configHelper.pageAccessToken)"
                    let (testRes, duration) = try timedGet(url)
                    analytics?.logResponse(testRes, endpoint: "user_profile", dict: ["senderId": senderId], duration: duration)
                    if testRes.status == .ok {
                        analytics?.logDebug("Sender: \(senderId), response=\(testRes)")
                    }
                    
                    return nil
                }
            }
            
            guard let first_name = response.json?["first_name"]?.string,
                let last_name = response.json?["last_name"]?.string,
                let locale = response.json?["locale"]?.string,
                let timezone = response.json?["timezone"]?.int else {
                    analytics?.logError("Failed to deserialize all required fields for the FB user profile for \(senderId)")
                    return nil
            }
            
            let gender = response.json?["gender"]?.string ?? "unknown"
            
            sub = sub ?? Subscriber(fb_messenger_id: senderId, first_name: first_name, last_name: last_name, locale: locale, timezone: timezone, gender: gender)
            
            sub?.last_ad_referral_source = response.json?["last_ad_referral.source"]?.string
            sub?.last_ad_referral_type = response.json?["last_ad_referral.type"]?.string
            sub?.last_ad_referral_id = response.json?["last_ad_referral.ad_id"]?.string
            
            try sub?.save()
        }
        
        return sub
    }
    
    func getSubOrUserProfileFor(senderId: String) -> Subscriber? {
        do {
            return try self.getUserProfile(senderId: senderId)
        } catch let error {
            analytics?.logError("Failed to get user with error=\(error)")
        }
        return nil
    }
}
