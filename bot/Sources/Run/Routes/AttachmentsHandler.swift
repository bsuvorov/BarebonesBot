import Foundation

extension Droplet {

    func handleAttachments(subscriber: Subscriber, attachments: [Node]) {
        for attachment in attachments {
            guard
                let type = attachment["type"]?.string,
                let url = attachment["payload.url"]?.string else {
                    analytics?.logDebug("Entered - handle attachments. Attachment type or url is nil. Ignore this message.")
                    return
            }
            analytics?.logDebug("attachment: \(type) \(url)")
        }
    }
}
