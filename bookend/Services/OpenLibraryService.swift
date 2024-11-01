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
        let encodedQuery = query.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? query
        let url = URL(string: "\(baseURL)/search.json?q=\(encodedQuery)")!
        
        let (data, _) = try await URLSession.shared.data(from: url)
        let response = try JSONDecoder().decode(OpenLibraryResponse.self, from: data)
        return response.docs
    }
    
    func getEditions(workId: String) async throws -> [OpenLibraryEdition] {
        guard !workId.isEmpty else {
            throw OpenLibraryError.invalidWorkId
        }
        
        // Clean the workId to remove any potential /works/ prefix
        let cleanWorkId = workId.replacingOccurrences(of: "/works/", with: "")
                               .replacingOccurrences(of: "works/", with: "")
                               .trimmingCharacters(in: .whitespacesAndNewlines)
        
        let urlString = "\(baseURL)/works/\(cleanWorkId)/editions.json"
        print("Cleaned URL: \(urlString)")  // Debug log
        
        guard let url = URL(string: urlString) else {
            throw OpenLibraryError.invalidURL
        }
        
        let (data, response) = try await URLSession.shared.data(from: url)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw OpenLibraryError.invalidResponse
        }
        
        guard httpResponse.statusCode == 200 else {
            throw OpenLibraryError.serverError(statusCode: httpResponse.statusCode)
        }
        
        // Log the raw response for debugging
        print("Raw response: \(String(data: data, encoding: .utf8) ?? "Unable to decode response")")
        
        do {
            let response = try JSONDecoder().decode(OpenLibraryEditionsResponse.self, from: data)
            return response.entries
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