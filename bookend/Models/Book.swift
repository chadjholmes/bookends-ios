//
//  book.swift
//  bookend
//
//  Created by Chad Holmes on 11/1/24.
//

import Foundation
import SwiftUI
import SwiftData

@Model
public final class Book {
    public var id: String
    public var title: String
    public var author: String
    public var genre: String?
    public var notes: String?
    public var currentPage: Int
    public var totalPages: Int
    public var createdAt: Date
    public var isbn: String?
    public var publisher: String?
    public var publishYear: Int?
    
    // Make these properties accessible to the extension
    @Attribute(.externalStorage) public var coverImageData: Data?
    @Attribute(.externalStorage) public var coverImageURL: URL?
    
    public init(id: String = UUID().uuidString,
         title: String,
         author: String,
         genre: String? = nil,
         notes: String? = nil,
         totalPages: Int,
         isbn: String? = nil,
         publisher: String? = nil,
         publishYear: Int? = nil,
         currentPage: Int = 0,
         createdAt: Date = Date()
    ) {
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
        self.coverImageData = nil
        self.coverImageURL = nil
    }
} 
