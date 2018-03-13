@_exported import Vapor

var stripeClient: StripeClient?
var analytics: MessengerAnalytics?
var configHelper: ConfigHelper!

extension Droplet {
    public func setup() throws {
        stripeClient = StripeClient(droplet: self)
        analytics = MessengerAnalytics(droplet: self)
        configHelper = ConfigHelper(config, analytics: analytics)
        try setupBotRoutes()
    }
}
