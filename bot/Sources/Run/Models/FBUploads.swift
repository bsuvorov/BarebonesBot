import Foundation
import FluentProvider
import Fluent
import Vapor

final public class MediaUpload: Model {
    public let storage = Storage()
    
    public static let idKey = "mediaUrl"
    public var mediaUrl: String
    public let attachmentId: String
    
    public var id: Identifier? {
        get {
            return Identifier(.string(self.mediaUrl), in: nil)
        }
        set {
            self.mediaUrl = (newValue?.string)!
        }
    }
    
    public init(mediaUrl: String, attachmentId: String) {
        self.mediaUrl = mediaUrl
        self.attachmentId = attachmentId
    }
    
    public init(row: Row) throws {
        mediaUrl = try row.get("mediaUrl")
        attachmentId = try row.get("attachmentId")
    }
    
    public func makeRow() throws -> Row {
        var row = Row()
        try row.set("mediaUrl", mediaUrl)
        try row.set("attachmentId", attachmentId)
        return row
    }    
}

extension MediaUpload: Preparation {
    public static func revert(_ database: Database) throws {
        try database.delete(self)
    }
    
    public static func prepare(_ database: Database) throws {
        try database.create(self) { MediaUpload in
            MediaUpload.string("mediaUrl", length: nil, optional: false, unique: true, default: nil)
            MediaUpload.string("attachmentId")
        }
    }
}

extension MediaUpload: Timestampable { }
