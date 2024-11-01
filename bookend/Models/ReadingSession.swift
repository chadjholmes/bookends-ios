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
    public var id: String
    public var book: Book?
    public var startPage: Int
    public var endPage: Int
    public var date: Date
    
    init(id: String = UUID().uuidString,
         book: Book?,
         startPage: Int,
         endPage: Int,
         date: Date = Date()) {
        self.id = id
        self.book = book
        self.startPage = startPage
        self.endPage = endPage
        self.date = date
    }
} 
