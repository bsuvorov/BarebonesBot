import Foundation
import HTTP

let TEST_EXPIRATION_INTERVAL = TimeInterval(60 * 60 * 26)

public struct RequestDetailsHelper {
    
    public static func fbEventLinkBy(id: String) -> RequestDetails {
        let endpoint = "events"
        let url = "www.facebook.com/\(endpoint)/\(id)"
        
        return RequestDetails(url: url, endpoint: endpoint, headers: nil, data_expiration: 0.0)
    }
    
    public static func fbEventPictureBy(id: String) -> RequestDetails {
        let endpoint = "picture"
        let type = "large"
        let url = "https://graph.facebook.com/v2.11/\(id)/\(endpoint)?type=\(type)&access_token=\(configHelper.pageAccessToken)"
        
        return RequestDetails(url: url, endpoint: endpoint, headers: nil, data_expiration: 0.0)
    }
}
