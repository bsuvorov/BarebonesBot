import Foundation

class Reply {
    public static func testQuickReply() -> [String: Any] {
        return ["content_type": "text", "title": "Test", "payload": POSTBACK_GET_STARTED]
    }
}
