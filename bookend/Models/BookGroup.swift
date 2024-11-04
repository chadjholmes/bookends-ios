import Foundation
import SwiftData

@Model
public final class BookGroup {
    @Attribute(.unique) public var id: UUID
    public var name: String
    public var groupDescription: String?
    public var createdAt: Date
    
    public init(
        id: UUID = UUID(),
        name: String,
        groupDescription: String? = nil,
        createdAt: Date = Date()
    ) {
        self.id = id
        self.name = name
        self.groupDescription = groupDescription
        self.createdAt = createdAt
    }
} 