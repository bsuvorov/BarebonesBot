import Foundation
import Jay
import Dispatch
import HTTP

public class StripeClient {
    let stripeKey: String
    let client: Vapor.Responder
    
    static public func getStripeKey(_ config: Config) -> String {
        let key = "stripeKey"
        let token = config["appkeys", key]?.string
        if token == nil {
            analytics?.logError("FAILED TO GET \(key) from configuration files!")
        }
        
        return token!
    }

    public init(config: Vapor.Config, responder: Responder) {
        stripeKey = StripeClient.getStripeKey(config)
        client = responder
    }
    
    public convenience init(droplet: Vapor.Droplet) {
        self.init(config: droplet.config, responder: droplet.client)
    }
    
    
    @discardableResult
    public func stripeCharge(token: String, description: String, amount: Int) -> Response? {
        do {
            analytics?.logDebug("Charging \(amount)")
            let payload: [String: Any] = [
                "amount": "\(amount)",
                "currency": "usd",
                "description": description,
                "source": token
            ]
            
            let endpoint = "charges"
            let url = "https://api.stripe.com/v1/\(endpoint)"
            let data = try Jay().dataFromJson(anyDictionary: payload)
            let finalJSON = try JSON(bytes: data)
            let node = try Node(node: finalJSON)
            let urlEncodedForm = Body.data(try! node.formURLEncoded())
            let headers = [
                HeaderKey("Authorization"): "Bearer \(stripeKey)",
                HeaderKey("Content-Type"): "application/x-www-form-urlencoded"
            ]
            
            let result = try client.post(url, query: [:], headers, urlEncodedForm, through: [])
            if result.status != .ok {
                analytics?.logError("Error when posting charge to Stripe, response = \(result)")
                analytics?.logResponse(result, endpoint: endpoint)
            }
            return result
        } catch let error {
            analytics?.logException(error)
        }
        
        return nil
    }
}

