import Vapor
import Console
import FluentProvider
import Jay
import Dispatch
import Foundation

let NOTIFICATION_HOUR = 9
let SECONDS_IN_HOUR: TimeInterval = 60 * 60

final class TestCustomCommand: Command, ConfigInitializable {
    public let id = "test_command"
    public let help = ["This command does things, like foo, and bar."]
    public let console: ConsoleProtocol
    
    public init(console: ConsoleProtocol) {
        self.console = console
    }
    
    public convenience init(config: Config) throws {
        let console = try config.resolveConsole()
        self.init(console: console)
    }
    
    public func run(arguments: [String]) throws {
        analytics?.logDebug("run test_command")
    }
}

final class WhitelistDomainsCommand: Command, ConfigInitializable {
    public let id = "whitelist_domains"
    public let help = ["This command updates whitelist of domains"]
    public let console: ConsoleProtocol
    
    public init(console: ConsoleProtocol) {
        self.console = console
    }
    
    public convenience init(config: Config) throws {
        let console = try config.resolveConsole()
        self.init(console: console)
    }
    
    public func run(arguments: [String]) throws {
        drop.whiteListDomains()
    }
}

final class UpdateBotMenuCommand: Command, ConfigInitializable {
    public let id = "update_bot_menu"
    public let help = ["This command update bot menu"]
    public let console: ConsoleProtocol
        
    public init(console: ConsoleProtocol) {
        self.console = console
    }
    
    public convenience init(config: Config) throws {
        let console = try config.resolveConsole()
        self.init(console: console)
    }
    
    public func run(arguments: [String]) throws {
        console.print("running custom command...")
        drop.reinitializeMenu()
    }
}

final class CountSubscribersCommand: Command, ConfigInitializable {
    public let id = "count_subscribers"
    
    public let help = ["This command counts number of users that are subscribed and count of users that are unsubscribed and posts it to kibana product index as \"total_subscribed\" and \"total_unsubscribed\""]
    public let console: ConsoleProtocol
    
    public init(console: ConsoleProtocol) {
        self.console = console
    }
    
    public convenience init(config: Config) throws {
        let console = try config.resolveConsole()
        self.init(console: console)
    }
    
    func countSubscribers() {
        let sevenDaysAgo = Int(Date().addingTimeInterval(-7 * 24 * SECONDS_IN_HOUR).timeIntervalSince1970)
        guard let countOfUsers = Subscriber.countOfSubscribers(),
            let countOfSubscribed = Subscriber.countOfSubscribersWith(status: .subscribed),
            let countOfUsersIgnoringBroadcastsForAWeek = Subscriber.countSubscribedUsersIgnoringBroadcastAfter(broadcastDate: sevenDaysAgo) else {
                analytics?.logError("Failed to get count of users and subscribers.")
                return
        }
        let countOfUnsubscribed = countOfUsers - countOfSubscribed
        
        analytics?.logEvent(event: .TotalSubscribed, withIntValue: countOfSubscribed)
        analytics?.logEvent(event: .TotalUnsubscribed, withIntValue: countOfUnsubscribed)
        analytics?.logEvent(event: .TotalUsersIgnoringBroadcastsForWeek, withIntValue: countOfUsersIgnoringBroadcastsForAWeek)
        
        analytics?.logDebug("Count of subscribed users = \(countOfSubscribed), \ncount of unsubscribed users = \(countOfUnsubscribed)")
    }
    
    public func run(arguments: [String]) throws {
        let date = Date()
        analytics?.logDebug("Running command=\(id), time is now \(date)")
        countSubscribers()
        
        // Make delay for send async request to analytics
        sleep(5)
        
        analytics?.logDebug("Done with \(self.id) command!")
    }
}

