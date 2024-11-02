import SwiftUI
import Combine

class BookEditViewModel: ObservableObject {
    @Published var title: String = ""
    @Published var author: String = ""
    @Published var totalPages: String = ""
    @Published var selectedImage: UIImage?
    @Published var selectedBook: OpenLibraryBook?
    @Published var selectedEdition: OpenLibraryEdition?
    @Published var showAlert = false
    @Published var alertMessage = ""

    var book: Book?

    init(book: Book? = nil) {
        self.book = book
        if let existingBook = book {
            title = existingBook.title
            author = existingBook.author
            totalPages = String(existingBook.totalPages)
            
            if let image = try? existingBook.loadCoverImage() {
                selectedImage = image
            }
            
            if let openlibKey = existingBook.externalReference["openlibraryKey"] {
                fetchBookDetails(openlibKey: openlibKey)
            }
        }
    }

    func fetchBookDetails(openlibKey: String) {
        Task {
            do {
                let fetchedBook = try await OpenLibraryService.shared.fetchBookDetails(key: openlibKey)
                DispatchQueue.main.async {
                    self.selectedBook = fetchedBook
                }
            } catch {
                handleFetchError(error)
            }
        }
    }

    func selectEdition(_ edition: OpenLibraryEdition) {
        selectedEdition = edition
        title = edition.title.isEmpty ? selectedBook?.title ?? "" : edition.title
        author = selectedBook?.authorDisplay ?? ""
        totalPages = edition.number_of_pages != nil ? String(edition.number_of_pages!) : ""
        loadCoverImage(from: edition.coverImageUrl)
    }

    public func loadCoverImage(from coverURLString: String?) {
        guard let coverURLString = coverURLString,
              let url = URL(string: coverURLString) else {
            selectedImage = nil
            return
        }
        Task {
            do {
                let (data, _) = try await URLSession.shared.data(from: url)
                if let image = UIImage(data: data) {
                    DispatchQueue.main.async {
                        self.selectedImage = image
                    }
                }
            } catch {
                print("Failed to load cover image: \(error.localizedDescription)")
                DispatchQueue.main.async {
                    self.selectedImage = nil
                }
            }
        }
    }

    private func handleFetchError(_ error: Error) {
        DispatchQueue.main.async {
            self.alertMessage = "Failed to fetch book details: \(error.localizedDescription)"
            self.showAlert = true
        }
    }

    func searchOpenLibraryEditions() {
        guard let workId = selectedBook?.key else {
            self.alertMessage = "No book selected to search editions."
            self.showAlert = true
            return
        }
        
        Task {
            do {
                let editions = try await OpenLibraryService.shared.getEditions(workId: workId)
                DispatchQueue.main.async {
                    if editions.isEmpty {
                        self.alertMessage = "No editions found for the selected book."
                        self.showAlert = true
                    } else {
                        // Assuming you have a property to store the editions
                        self.selectedEdition = editions.first
                        // Optionally, handle multiple editions
                    }
                }
            } catch {
                DispatchQueue.main.async {
                    self.alertMessage = "Failed to search editions: \(error.localizedDescription)"
                    self.showAlert = true
                }
            }
        }
    }
}
