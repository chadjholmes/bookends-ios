//
//  readingSession.swift
//  bookend
//
//  Created by Chad Holmes on 11/1/24.
//
import Foundation
import SwiftData

@Model
public class ReadingSession {
    @Attribute(.unique) public var id: UUID
    @Relationship public var book: Book?
    public var startPage: Int
    public var endPage: Int
    public var duration: Int
    public var date: Date
    
    init(id: UUID = UUID(),
         book: Book?,
         startPage: Int,
         endPage: Int,
         duration: Int = 0,
         date: Date = Date()) {
        self.id = id
        self.book = book
        self.startPage = startPage
        self.endPage = endPage
        self.duration = duration
        self.date = date
    }
} 
