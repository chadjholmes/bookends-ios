import SwiftUI

struct BookDetails: View {
    let book: Book
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(book.title)
                .font(.title)
                .bold()
                .foregroundColor(.purple)
            
            if !book.author.isEmpty {
                Text("by \(book.author)")
                    .font(.title2)
                    .foregroundColor(.secondary)
            }
            
            BookMetadata(book: book)
        }
        .padding()
    }
}

struct BookMetadata: View {
    let book: Book
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Added on \(book.createdAt.formatted(date: .abbreviated, time: .omitted))")
                .font(.caption)
                .foregroundColor(.secondary)
                .padding(.top)
        
            if let publisher = book.publisher {
                Text("Publisher: \(publisher)")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
        
            if let publishYear = book.publishYear {
                Text("Published: \(String(publishYear))")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }

            Text("Total Pages: \(String(book.totalPages))")
                .font(.subheadline)
                .foregroundColor(.secondary)
    
            if let isbn = book.isbn {
                Text("ISBN: \(isbn)")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
    }
} 