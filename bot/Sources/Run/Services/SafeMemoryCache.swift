import Foundation
import Dispatch

public final class SafeMemoryCache {
    private static let CACHE_CLEAN_DELAY: Double = 60 * 60
    
    private var storage: [String: (Date?, Any)] = [:]
    private let lock = NSLock()
    private var lastClean = Date()
    
    public func get(_ key: String) -> Any? {
        lock.lock()
        defer { lock.unlock() }
        
        guard let (expiration, value) = storage[key] else {
            return nil
        }
        
        if isExpired(expiration) {
            return nil
        }
        
        cleanExpiredDataAsync()
        
        return value
    }
    
    public func set(_ key: String, _ value: Any, expiration: Date? = nil) {
        lock.lock()
        defer { lock.unlock() }
        storage[key] = (expiration, value)
        
        cleanExpiredDataAsync()
    }
    
    public func delete(_ key: String) {
        lock.lock()
        defer { lock.unlock() }
        storage.removeValue(forKey: key)
    }
    
    public func cleanExpiredDataAsync() {
        DispatchQueue(label: "MessengerBot.MemoryCache.Queue").async { [weak self] in
            guard let welf = self else {
                return
            }
            welf.cleanExpiredData()
        }
    }
    
    public func cleanExpiredData() {
        if lastClean.timeIntervalSinceNow + SafeMemoryCache.CACHE_CLEAN_DELAY < 0  {
            lastClean = Date()
            for (key, (expiration, _)) in storage {
                if isExpired(expiration) {
                    storage.removeValue(forKey: key)
                }
            }
        }
    }
    
    private func isExpired(_ expiration: Date?) -> Bool {
        if let expirationInterval = expiration?.timeIntervalSinceNow,
            expirationInterval < 0 {
            return true
        }
        return false
    }
}

extension SafeMemoryCache {
    public func set(_ key: String, _ value: Any) {
        return set(key, value, expiration: nil)
    }
    
    public func set(_ key: String, _ value: Any, expireAfter: TimeInterval) {
        return set(key, value, expiration: Date(timeIntervalSinceNow: expireAfter))
    }
}

