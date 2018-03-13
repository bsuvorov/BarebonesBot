import Foundation
import Vapor

public class ConfigHelper {
    
    let config: Config
    let analytics: MessengerAnalytics?
    
    init(_ config: Config, analytics: MessengerAnalytics? = nil) {
        self.config = config
        self.analytics = analytics
    }
    
    lazy var authToken: String = {
        let token = self.config["appkeys", "djangoToken"]?.string
        if token == nil {
            analytics?.logError("FAILED TO GET djangoToken from configuration files!")
        }
        
        return token!
    }()
    
    lazy var pageAccessToken: String = {
        let token = self.config["appkeys", "fbPageAccessToken"]?.string
        if token == nil {
            analytics?.logError("FAILED TO GET fbPageAccessToken from configuration files!")
        }
        
        return token!
    }()
}
