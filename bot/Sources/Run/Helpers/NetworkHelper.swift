import Foundation
import HTTP
import JSON
import Vapor

let safeMemoryCache = SafeMemoryCache()

protocol SimpleJSONInitializable {
    init?(json: JSON)
}

protocol SimpleInitializableFromRequest: SimpleJSONInitializable {
    init?(requestDetails: RequestDetails)
}

public extension Droplet {

    func getData(from url: String, endpoint: String, headers: [HeaderKey : String]? = [:]) -> Response? {
        do {
            let (response, duration) = try timedGet(url, headers: headers)
            analytics?.logResponse(response, endpoint: endpoint, dict: ["request_url" : url], duration: duration)
            guard response.status == .ok else {
                analytics?.logError("Failed to get 200 response for \(endpoint)")
                return nil
            }
            return response
        } catch let error {
            analytics?.logException(error)
            analytics?.logError("Failed to get response for \(endpoint)")
        }
        return nil
    }
    
    func timedGet(_ url: String, headers: [HeaderKey : String]? = [:]) throws -> (Response, Int) {
        let start = Date().timeIntervalSince1970
        let response = try self.client.get(url, query: [:], headers ?? [:], nil, through: [])
        let duration = Int(1000*(Date().timeIntervalSince1970 - start))
        return (response, duration)
    }
    
    func getFirstItemInJSON(from url: String, endpoint: String, headers: [HeaderKey : String]? = [:]) -> JSON? {
        return getJSONArray(from: url,
                            endpoint: endpoint,
                            headers: headers)?.first
    }
    
    func getFirstItemInJSON(from requestDetails: RequestDetails) -> JSON? {
        return getFirstItemInJSON(from: requestDetails.url,
                                  endpoint: requestDetails.endpoint,
                                  headers: requestDetails.headers)
    }
    
    func getJSONArray(from url: String, endpoint: String, headers: [HeaderKey : String]? = [:]) -> [JSON]? {
        guard let response = self.getData(from: url, endpoint: endpoint, headers: headers) else { return nil }
        guard let array = response.json?.array, array.count > 0 else {
            analytics?.logError("Failed to find non empty array in \(endpoint) response=\(response)")
            return nil
        }
        return array
    }
    
    func getJSONArray(from requestDetails: RequestDetails) -> [JSON]? {
        return getJSONArray(from: requestDetails.url,
                            endpoint: requestDetails.endpoint,
                            headers: requestDetails.headers)
    }
    
    internal func fetchModelFrom<T:SimpleInitializableFromRequest>(requestDetails: RequestDetails, to entity: T.Type) -> T? {
        if let entity = safeMemoryCache.get(requestDetails.url) {
            return entity as? T
        } else if let entity = T.init(requestDetails: requestDetails) {
            safeMemoryCache.set(requestDetails.url, entity, expireAfter: requestDetails.data_expiration)
            return entity
        } else if requestDetails.doesNeedToCacheEmptyResponse {
            safeMemoryCache.set(requestDetails.url, NSObject(), expireAfter: requestDetails.data_expiration)
            return nil
        } else {
            analytics?.logError("Failed to fetch out \(requestDetails) to create \(entity)")
            return nil
        }
    }
}
