import Foundation
import SwiftData

@Model
public final class BookGroupRelationship {
    @Attribute(.unique) public var id: UUID
    public var book: Book
    public var group: BookGroup
    public var dateAdded: Date
    
    public init(
        id: UUID = UUID(),
        book: Book,
        group: BookGroup,
        dateAdded: Date = Date()
    ) {
        self.id = id
        self.book = book
        self.group = group
        self.dateAdded = dateAdded
    }
} 