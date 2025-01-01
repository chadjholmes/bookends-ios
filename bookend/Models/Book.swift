//
//  Book.swift
//  bookend
//
//  Created by Chad Holmes on 11/1/24.
//

import Foundation
import SwiftUI
import SwiftData

@Model
public final class Book {
    @Attribute(.unique) public var id: UUID
    public var title: String
    public var author: String
    public var genre: String?
    public var notes: String?
    public var currentPage: Int
    public var totalPages: Int
    public var createdAt: Date
    public var isbn: String?               // Ensure this property is included
    public var publisher: String?
    public var publishYear: Int?
    public var showPercentage: Bool = false
    public var isCompleted: Bool = false
    
    // External references to maintain OpenLibrary identifiers
    public var externalReference: [String: String]  // Ensure this property is included
    
    @Attribute(.externalStorage) public var coverImageData: Data?  // Ensure this property is included
    @Attribute(.externalStorage) public var coverImageURL: URL?
    
    // Relationship to ReadingSession
    @Relationship(deleteRule: .cascade) public var readingSessions: [ReadingSession]?
    
    public init(id: UUID = UUID(),
                title: String,
                author: String,
                genre: String? = nil,
                notes: String? = nil,
                totalPages: Int,
                isbn: String? = nil,
                publisher: String? = nil,
                publishYear: Int? = nil,
                currentPage: Int = 0,
                createdAt: Date = Date(),
                externalReference: [String: String],
                showPercentage: Bool = false,
                isCompleted: Bool = false) {
        self.id = id
        self.title = title
        self.author = author
        self.genre = genre
        self.notes = notes
        self.totalPages = totalPages
        self.isbn = isbn
        self.publisher = publisher
        self.publishYear = publishYear
        self.currentPage = currentPage
        self.createdAt = createdAt
        self.externalReference = externalReference
        self.coverImageData = nil
        self.coverImageURL = nil
        self.showPercentage = showPercentage
        self.isCompleted = isCompleted
    }
    
    /// Loads the cover image from stored data or URL.
    public func loadCoverImage() throws -> UIImage {
        if let imageData = coverImageData {
            guard let image = UIImage(data: imageData) else {
                throw NSError(domain: "Invalid image data", code: 0, userInfo: nil)
            }
            return image
        } else if let imageUrl = coverImageURL,
                  let data = try? Data(contentsOf: imageUrl),
                  let image = UIImage(data: data) {
            return image
        } else {
            throw NSError(domain: "No cover image available", code: 0, userInfo: nil)
        }
    }
    
    /// Saves the cover image to storage.
    /// - Parameter image: The UIImage to save.
    public func saveCoverImage(_ image: UIImage) throws {
        if let data = image.jpegData(compressionQuality: 0.8) {
            self.coverImageData = data
            self.coverImageURL = nil // Clear URL if saving data directly
        } else {
            throw NSError(domain: "Failed to convert image to data", code: 0, userInfo: nil)
        }
    }
} 