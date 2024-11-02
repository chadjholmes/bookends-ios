import Foundation

public class BookTransformer {
    
    /// Transforms an OpenLibraryBook and an optional OpenLibraryEdition into an internal Book model.
    /// - Parameters:
    ///   - book: The selected OpenLibraryBook.
    ///   - edition: The selected OpenLibraryEdition (optional).
    /// - Returns: A new Book instance populated with data from the selected book and edition.
    static func transformToBook(book: OpenLibraryBook, edition: OpenLibraryEdition? = nil) -> Book {
        return Book(
            title: edition?.title.isEmpty == false ? edition?.title ?? book.title : book.title,
            author: book.authorDisplay,
            genre: nil,  // Genre can be added later or fetched from another source
            notes: nil,  // Notes can be added by the user
            totalPages: edition?.number_of_pages ?? book.number_of_pages_median ?? 0,
            isbn: edition?.displayISBN ?? book.isbn?.first,
            publisher: edition?.displayPublisher ?? book.publisher?.first,
            publishYear: parsePublishYear(from: edition?.publish_date ?? "\(book.first_publish_year ?? 0)"),
            currentPage: 0,  // Initialize to 0 or load existing data
            createdAt: Date(),
            externalReference: ["openlibraryKey": book.key]
        )
    }
    
    /// Parses the publish year from a string.
    /// - Parameter dateString: The publish date string.
    /// - Returns: An integer representing the publish year, if parsable.
    public static func parsePublishYear(from dateString: String) -> Int? {
        // Attempt to extract the year from the date string
        let components = dateString.components(separatedBy: CharacterSet.decimalDigits.inverted)
        if let yearString = components.first(where: { $0.count == 4 }),
           let year = Int(yearString) {
            return year
        }
        // Fallback to converting the entire string to Int
        return Int(dateString)
    }
}