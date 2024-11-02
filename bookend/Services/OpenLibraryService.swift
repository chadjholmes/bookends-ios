import Foundation

// Response structure
struct OpenLibraryResponse: Codable {
    let numFound: Int
    let start: Int
    let numFoundExact: Bool
    let docs: [OpenLibraryBook]
    let q: String
}

// Book structure from search results
struct OpenLibraryBook: Codable, Identifiable {
    let key: String
    let title: String
    let author_name: [String]?
    let number_of_pages_median: Int?
    let cover_i: Int?
    let first_publish_year: Int?
    let publisher: [String]?
    let isbn: [String]?
    
    var id: String { key }
    var authorDisplay: String {
        author_name?.first ?? "Unknown Author"
    }
    
    var coverImageUrl: String? {
        if let coverId = cover_i {
            return "https://covers.openlibrary.org/b/id/\(coverId)-L.jpg"
        }
        return nil
    }
    
    var completenessScore: Int {
        var score = 0
        if author_name != nil { score += 1 }
        if number_of_pages_median != nil { score += 1 }
        if cover_i != nil { score += 1 }
        if first_publish_year != nil { score += 1 }
        if publisher?.isEmpty == false { score += 1 }
        if isbn?.isEmpty == false { score += 1 }
        return score
    }
}

class OpenLibraryService {
    static let shared = OpenLibraryService()
    private let baseURL = "https://openlibrary.org"
    
    private init() {}
    
    func searchBooks(query: String) async throws -> [OpenLibraryBook] {
        let searchQuery = query.trimmingCharacters(in: .whitespacesAndNewlines)
        let encodedQuery = searchQuery.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? searchQuery
        
        // Changed URL to use q parameter instead of title for broader search
        // Added limit parameter to get more results
        // Added mode=everything to search across all fields
        let url = URL(string: "\(baseURL)/search.json?q=\(encodedQuery)&fields=key,title,author_name,number_of_pages_median,cover_i,first_publish_year,publisher,isbn&mode=everything&limit=50")!
        
        // Log the outbound request URL
        print("Request URL: \(url.absoluteString)")

        let (data, response) = try await URLSession.shared.data(from: url)

        // Log the response data
        if let httpResponse = response as? HTTPURLResponse {
            print("Response Status Code: \(httpResponse.statusCode)")
        }
        print("Response Data: \(String(data: data, encoding: .utf8) ?? "Unable to decode response")")
        
        let decodedResponse = try JSONDecoder().decode(OpenLibraryResponse.self, from: data)
        
        // Improved sorting algorithm
        return decodedResponse.docs.sorted { book1, book2 in
            // First priority: Title contains exact query (case-insensitive)
            let queryLower = searchQuery.lowercased()
            let title1Contains = book1.title.lowercased().contains(queryLower)
            let title2Contains = book2.title.lowercased().contains(queryLower)
            
            if title1Contains && !title2Contains { return true }
            if title2Contains && !title1Contains { return false }
            
            // Second priority: Title starts with query
            let title1Starts = book1.title.lowercased().starts(with: queryLower)
            let title2Starts = book2.title.lowercased().starts(with: queryLower)
            
            if title1Starts && !title2Starts { return true }
            if title2Starts && !title1Starts { return false }
            
            // Third priority: Completeness score
            if book1.completenessScore != book2.completenessScore {
                return book1.completenessScore > book2.completenessScore
            }
            
            // Final priority: Alphabetical order
            return book1.title < book2.title
        }
    }

    /// Fetches detailed information about a book using its key.
    /// - Parameter key: The OpenLibrary key for the book (e.g., "/works/OL12345W").
    /// - Returns: An `OpenLibraryBook` with detailed information.
    func fetchBookDetails(key: String) async throws -> OpenLibraryBook {
        // Clean the key
        let cleanKey = key
            .replacingOccurrences(of: "/works/", with: "")
            .trimmingCharacters(in: .whitespacesAndNewlines)
        
        let url = URL(string: "\(baseURL)/works/\(cleanKey).json")!
        
        // Log the outbound request URL
        print("Fetching Book Details from URL: \(url.absoluteString)")
        
        let (data, response) = try await URLSession.shared.data(from: url)
        
        // Log the response
        if let httpResponse = response as? HTTPURLResponse {
            print("Response Status Code: \(httpResponse.statusCode)")
        }
        print("Response Data: \(String(data: data, encoding: .utf8) ?? "Unable to decode response")")
        
        guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
            throw OpenLibraryError.invalidResponse
        }
        
        let decodedBook = try JSONDecoder().decode(OpenLibraryBook.self, from: data)
        return decodedBook
    }
    
    func getEditions(workId: String) async throws -> [OpenLibraryEdition] {
        guard !workId.isEmpty else {
            throw OpenLibraryError.invalidWorkId
        }
        
        // Adjust the cleaning process to handle different potential prefixes
        let cleanWorkId = workId
            .replacingOccurrences(of: "/works/", with: "")
            .replacingOccurrences(of: "works/", with: "")
            .replacingOccurrences(of: "/books/", with: "")
            .replacingOccurrences(of: "books/", with: "")
            .trimmingCharacters(in: .whitespacesAndNewlines)
        
        let urlString = "\(baseURL)/works/\(cleanWorkId)/editions.json"
        print("Cleaned URL: \(urlString)")  // Debug log
        
        guard let url = URL(string: urlString) else {
            throw OpenLibraryError.invalidURL
        }
        
        // Log the outbound request URL
        print("Request URL: \(url.absoluteString)")

        let (data, response) = try await URLSession.shared.data(from: url)

        // Log the response data
        if let httpResponse = response as? HTTPURLResponse {
            print("Response Status Code: \(httpResponse.statusCode)")
        }
        print("Response Data: \(String(data: data, encoding: .utf8) ?? "Unable to decode response")")
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw OpenLibraryError.invalidResponse
        }
        
        guard httpResponse.statusCode == 200 else {
            throw OpenLibraryError.serverError(statusCode: httpResponse.statusCode)
        }
        
        // Log the raw response for debugging
        print("Raw response: \(String(data: data, encoding: .utf8) ?? "Unable to decode response")")
        
        do {
            let decodedResponse = try JSONDecoder().decode(OpenLibraryEditionsResponse.self, from: data)
            return decodedResponse.entries
        } catch {
            print("Decoding error: \(error)")  // Debug log
            throw OpenLibraryError.decodingError(underlying: error)
        }
    }
}

struct OpenLibraryEditionsResponse: Codable {
    let entries: [OpenLibraryEdition]
}

struct OpenLibraryEdition: Codable, Identifiable {
    let key: String // This is the edition ID
    var id: String { key }
    let title: String
    let publishers: [String]?
    let publish_date: String?
    let number_of_pages: Int?
    let isbn_13: [String]?
    let isbn_10: [String]?
    let covers: [Int]?
    
    var coverImageUrl: String? {
        if let coverId = covers?.first {
            return "https://covers.openlibrary.org/b/id/\(coverId)-L.jpg"
        }
        return nil
    }
    
    var displayPublisher: String {
        publishers?.first ?? "Unknown Publisher"
    }
    
    var displayISBN: String? {
        isbn_13?.first ?? isbn_10?.first
    }
}

enum OpenLibraryError: LocalizedError {
    case invalidWorkId
    case invalidURL
    case invalidResponse
    case serverError(statusCode: Int)
    case decodingError(underlying: Error)
    
    var errorDescription: String? {
        switch self {
        case .invalidWorkId:
            return "Invalid work ID"
        case .invalidURL:
            return "Invalid URL"
        case .invalidResponse:
            return "Invalid response from server"
        case .serverError(let statusCode):
            return "Server error (Status \(statusCode))"
        case .decodingError(let error):
            return "Failed to parse response: \(error.localizedDescription)"
        }
    }
}
