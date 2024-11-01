//
//  book.swift
//  bookend
//
//  Created by Chad Holmes on 11/1/24.
//

import Foundation
import SwiftData

@Model
public class Book {
    public var id: String
    public var title: String
    public var author: String
    public var genre: String?
    public var notes: String?
    public var coverImage: String?
    public var currentPage: Int
    public var totalPages: Int
    public var createdAt: Date
    
    init(id: String = UUID().uuidString,
         title: String,
         author: String,
         coverImage: String? = nil,
         genre: String? = nil,
         notes: String? = nil,
         currentPage: Int = 0,
         totalPages: Int,
         createdAt: Date = Date()) {
        self.id = id
        self.title = title
        self.author = author
        self.coverImage = coverImage
        self.genre = genre
        self.notes = notes
        self.currentPage = currentPage
        self.totalPages = totalPages
        self.createdAt = createdAt
    }
} 
