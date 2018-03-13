import Foundation
import HTTP

public struct RequestDetails {
    public let url: String
    public let endpoint: String
    public let headers: [HeaderKey: String]?
    public let data_expiration: TimeInterval
    public var doesNeedToCacheEmptyResponse: Bool = false
}

public extension RequestDetails {
    init(url: String,
         endpoint: String,
         headers: [HeaderKey: String]?,
         data_expiration: TimeInterval) {
        
        self.init(url: url,
                  endpoint: endpoint,
                  headers: headers,
                  data_expiration: data_expiration,
                  doesNeedToCacheEmptyResponse: false)
    }
}
