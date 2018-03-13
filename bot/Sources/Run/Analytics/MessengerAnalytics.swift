import Dispatch
import Foundation
import BotAnalytics
import Vapor

public enum AnalyticsEvent: String {
    
    case IncomingMessage = "incoming_message"
    case NewUserRegistered = "new_user_registered"
    case SubscribeRequested = "subscribe_requested"
    case UnsubscribeRequested = "unsubscribe_requested"
    case GetStartedRequested = "get_started_requested"
    case CountOfSubscribers = "count_of_subscribers"
    case TotalSubscribed = "total_subscribed"
    case TotalUnsubscribed = "total_unsubscribed"
    case TotalUsersIgnoringBroadcastsForWeek = "total_users_ignoring_broadcast_for_week"
}

public class MessengerAnalytics {
    
    let fbAnalytics: FacebookAnalytics
    let kibanaAnalytics: KibanaAnalytics
    let isAnalyticsDisabled: Bool
    let analyticsIndexName: String
    
    let fbEndpoint = "activities"
    let fbAnalyticsEvent = "CUSTOM_APP_EVENTS"
    let kibanaHost = "ip_adress:8080"
    let kibanaEndpoint = "events"
    let kibanaAuthorization = "Token"
    
    public init(config: Vapor.Config, responder: Responder) {
        let appID = MessengerAnalytics.getAppID(config)
        let pageID = MessengerAnalytics.getPageID(config)
        let analyticsIndexName = MessengerAnalytics.getProductAnalyticsIndexName(config)
        let engAnalyticsIndexName = MessengerAnalytics.getEngAnalyticsIndexName(config)
        
        self.analyticsIndexName = MessengerAnalytics.getProductAnalyticsIndexName(config)
        self.isAnalyticsDisabled = MessengerAnalytics.isAnalyticsDisabled(config)
        
        self.fbAnalytics = FacebookAnalytics(client: responder,
                                             appID: appID,
                                             pageID: pageID,
                                             endpoint: self.fbEndpoint,
                                             event: self.fbAnalyticsEvent)
        
        self.kibanaAnalytics = KibanaAnalytics(client: responder,
                                               analyticsIndexName: analyticsIndexName,
                                               engAnalyticsIndexName: engAnalyticsIndexName,
                                               host: self.kibanaHost,
                                               endpoint: self.kibanaEndpoint,
                                               authorization: self.kibanaAuthorization)
    }
    
    public convenience init(droplet: Vapor.Droplet) {
        self.init(config: droplet.config, responder: droplet.client)
    }
    
    public func logIncomingMessage(subscriber: Subscriber, message: String) {
        if self.isAnalyticsDisabled {
            return
        }
        
        let details = ["message": message]
        logAnalytics(event: AnalyticsEvent.IncomingMessage.rawValue, for: subscriber, details: details)
    }
    
    public func logAnalytics(event: AnalyticsEvent, for subscriber: Subscriber, eventValue: String? = nil) {
        if self.isAnalyticsDisabled {
            return
        }
        
        var details = [String: Any]()
        if let value = eventValue {
            details["event_value"] = value
        }
        
        logAnalytics(event: event.rawValue, for: subscriber, details: details)
    }

    public func logEvent(event: AnalyticsEvent, withIntValue value: Int) {
        var payload: [String: Any] = [:]
        
        payload["event_int_value"] = value
        
        payload["event_type"] = event.rawValue
        
        let timestamp = Int(Date().timeIntervalSince1970*1000)
        payload["date"] = timestamp
        let eventId = "\(event.rawValue)_\(timestamp)"
        let index = self.analyticsIndexName
        
        let url = self.kibanaAnalytics.elkURL(index: index, eventId: eventId)
        self.kibanaAnalytics.writeKibanaEntry(url: url, event: payload)
    }

    
    public func logEvent(event: AnalyticsEvent, withValue value: String) {
        var payload: [String: Any] = [:]
        
        payload["event_value"] = value
        
        payload["event_type"] = event.rawValue
        
        let timestamp = Int(Date().timeIntervalSince1970*1000)
        payload["date"] = timestamp
        let eventId = "\(event.rawValue)_\(timestamp)"
        let index = self.analyticsIndexName
        
        let url = self.kibanaAnalytics.elkURL(index: index, eventId: eventId)
        self.kibanaAnalytics.writeKibanaEntry(url: url, event: payload)
    }
    
    private func logAnalytics(event: String, for subscriber: Subscriber, details: [String: Any] = [String:Any]()) {
        var payload = subscriber.toDictionary()
        for (key, value) in details {
            payload[key] = value
        }
        
        if let interval = subscriber.durationSinceLastBroadcastWasSent() {
            payload["seconds_since_broadcast"] = interval
        }
        
        payload["experiments"] = ExperimentManager.listExperimentsForSubscriber(subscriber)
        
        elkLogAnalytics(event: event, for: subscriber.fb_messenger_id, details: payload)
        
        DispatchQueue.global(qos: DispatchQoS.QoSClass.background).async {[weak self] in
            self?.fbAnalytics.writeFBAnalyticsEntry(event: event, senderId: subscriber.fb_messenger_id)
        }
    }
    
    private func elkLogAnalytics(event: String, for senderId: String, details: [String: Any] = [String:Any]()) {
        var payload = details
        payload["event_type"] = event
        
        let timestamp = Int(Date().timeIntervalSince1970*1000)
        payload["date"] = timestamp
        let eventId = "\(senderId)_\(event)_\(timestamp)"
        let index = self.analyticsIndexName
        
        let url = self.kibanaAnalytics.elkURL(index: index, eventId: eventId)
        self.kibanaAnalytics.writeKibanaEntry(url: url, event: payload)
    }
}

// MARK: Log exception, error, debug, warning, response
public extension MessengerAnalytics {
    public func logException(_ error: Error, dict: [String: Any] = [String: Any]()) {
        self.kibanaAnalytics.logException(error, dict: dict)
    }
    
    public func logError(_ error: String, dict: [String: Any] = [String: Any]()) {
        self.kibanaAnalytics.logError(error, dict: dict)
    }
    
    public func logWarning(_ warning: String, dict: [String: Any] = [String: Any]()) {
        self.kibanaAnalytics.logWarning(warning, dict: dict)
    }
    
    public func logDebug(_ message: String, dict: [String: Any] = [String: Any]()) {
        print("Debug: \(message)")
    }
    
    public func logResponse(_ response: Response, endpoint: String, dict: [String: Any] = [String: Any](), duration: Int? = nil) {
        self.kibanaAnalytics.logResponse(response, endpoint: endpoint, dict: dict, duration: duration)
    }
}

// MARK: Get configs
extension MessengerAnalytics {
    static func getAppID(_ config: Config) -> String {
        let key = "fbAppId"
        let result = config["appkeys", key]?.string
        if result == nil {
            print("******FATAL ERROR: FAILED TO GET \(key) from configuration files!")
        }
        
        return result!
    }
    
    static func isAnalyticsDisabled(_ config: Config) -> Bool {
        let key = "disableAnalytics"
        let result = config["appkeys", key]?.string
        return result != nil
    }
    
    static func getEngAnalyticsIndexName(_ config: Config) -> String {
        let key = "eng_analytics_index"
        return config["appkeys", key]?.string ?? "default"
    }
    
    static func getProductAnalyticsIndexName(_ config: Config) -> String {
        let key = "product_analytics_index"
        return config["appkeys", key]?.string ?? "default"
    }
    
    static func getPageID(_ config: Config) -> String {
        let key = "fbPageId"
        let result = config["appkeys", key]?.string
        if result == nil {
            print("******FATAL ERROR: FAILED TO GET \(key) from configuration files!")
        }
        return result!
    }
}
