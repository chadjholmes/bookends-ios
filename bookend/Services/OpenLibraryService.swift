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
}

class OpenLibraryService {
    static let shared = OpenLibraryService()
    private let baseURL = "https://openlibrary.org"
    
    private init() {}
    
    func searchBooks(query: String) async throws -> [OpenLibraryBook] {
        guard query.count >= 2,
              let encodedQuery = query.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed),
              let url = URL(string: "\(baseURL)/search.json?title=\(encodedQuery)&fields=key,title,author_name,number_of_pages_median,cover_i,first_publish_year,publisher,isbn&limit=10")
        else {
            throw URLError(.badURL)
        }
        
        let (data, response) = try await URLSession.shared.data(from: url)
        guard let httpResponse = response as? HTTPURLResponse, (200..<300).contains(httpResponse.statusCode) else {
            throw URLError(.badServerResponse)
        }
        
        return try JSONDecoder().decode(OpenLibraryResponse.self, from: data).docs
    }
} 