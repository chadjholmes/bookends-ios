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
        
        let url = URL(string: "\(baseURL)/search.json?q=\(encodedQuery)&fields=key,title,author_name,number_of_pages_median,cover_i,first_publish_year,publisher,isbn&lang=en")!
        
        print("Request URL: \(url.absoluteString)")

        let (data, response) = try await URLSession.shared.data(from: url)

        if let httpResponse = response as? HTTPURLResponse {
            print("Response Status Code: \(httpResponse.statusCode)")
        }
        print("Response Data: \(String(data: data, encoding: .utf8) ?? "Unable to decode response")")
        
        let decodedResponse = try JSONDecoder().decode(OpenLibraryResponse.self, from: data)
        
        // Generate variants of the search query within an edit distance of 2
        let variants = generateVariants(for: searchQuery)

        // Filter books based on substring match with variants
        let filteredBooks = decodedResponse.docs.filter { book in
            let titleMatch = variants.contains { variant in
                book.title.lowercased().contains(variant.lowercased())
            }
            let authorMatch = book.author_name?.contains(where: { author in
                variants.contains { variant in
                    author.lowercased().contains(variant.lowercased())
                }
            }) ?? false
            return titleMatch || authorMatch
        }
        
        return filteredBooks
    }

    // Function to generate variants within an edit distance of 2
    private func generateVariants(for query: String) -> [String] {
        var variants = Set<String>()
        // Add the original query
        variants.insert(query)

        // Generate variants by modifying the query
        // You can implement a more sophisticated variant generation here
        for i in 0..<query.count {
            let index = query.index(query.startIndex, offsetBy: i)
            let char = query[index]

            // Deletion
            let deleted = query.replacingCharacters(in: index...index, with: "")
            variants.insert(deleted)

            // Substitution (replace with all lowercase letters)
            for letter in "abcdefghijklmnopqrstuvwxyz" {
                let substituted = query.replacingCharacters(in: index...index, with: String(letter))
                variants.insert(substituted)
            }

            // Insertion (insert a letter)
            for letter in "abcdefghijklmnopqrstuvwxyz" {
                let inserted = query.replacingCharacters(in: index...index, with: "\(char)\(letter)")
                variants.insert(inserted)
            }
        }

        return Array(variants).filter { $0.count <= query.count + 2 } // Limit to reasonable length
    }

    // Function to calculate the Levenshtein distance
    private func editDistance(_ a: String, _ b: String) -> Int {
        let aCount = a.count
        let bCount = b.count
        var matrix = [[Int]]()

        for i in 0...aCount {
            matrix.append(Array(repeating: 0, count: bCount + 1))
            matrix[i][0] = i
        }
        for j in 0...bCount {
            matrix[0][j] = j
        }

        for i in 1...aCount {
            for j in 1...bCount {
                let cost = a[a.index(a.startIndex, offsetBy: i - 1)] == b[b.index(b.startIndex, offsetBy: j - 1)] ? 0 : 1
                matrix[i][j] = min(matrix[i - 1][j] + 1,      // Deletion
                                   matrix[i][j - 1] + 1,      // Insertion
                                   matrix[i - 1][j - 1] + cost) // Substitution
            }
        }

        return matrix[aCount][bCount]
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
