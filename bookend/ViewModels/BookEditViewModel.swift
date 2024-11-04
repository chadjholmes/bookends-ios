import SwiftUI
import Combine

class BookEditViewModel: ObservableObject {
    @Published var book: Book?
    @Published var title: String
    @Published var author: String
    @Published var totalPages: String
    @Published var isbn: String
    @Published var publisher: String
    @Published var publishYear: String
    @Published var genre: String
    @Published var notes: String
    @Published var selectedBook: Book?
    @Published var selectedEdition: OpenLibraryEdition?
    @Published var selectedImage: UIImage?
    @Published var showAlert = false
    @Published var alertMessage = ""

    init(book: Book? = nil) {
        self.book = book
        self.selectedBook = book
        self.title = book?.title ?? ""
        self.author = book?.author ?? ""
        self.totalPages = book?.totalPages != nil ? String(book!.totalPages) : ""
        self.isbn = book?.isbn ?? ""
        self.publisher = book?.publisher ?? ""
        self.publishYear = book?.publishYear != nil ? String(book!.publishYear!) : ""
        self.genre = book?.genre ?? ""
        self.notes = book?.notes ?? ""

        // Initialize cover image from existing book
        if let book = book {
            Task {
                if let image = try? book.loadCoverImage() {
                    await MainActor.run {
                        self.selectedImage = image
                    }
                }
            }
        }
    }

    func fetchBookDetails(openlibKey: String) {
        Task {
            do {
                let fetchedBook = try await OpenLibraryService.shared.fetchBookDetails(key: openlibKey)
                let transformedBook = BookTransformer.transformToBook(book: fetchedBook)
                DispatchQueue.main.async {
                    self.selectedBook = transformedBook
                    self.updateUIWithSelectedBook(transformedBook)
                }
            } catch {
                handleFetchError(error)
            }
        }
    }

    func selectEdition(_ edition: OpenLibraryEdition) {
        selectedEdition = edition
        title = edition.title.isEmpty ? selectedBook?.title ?? "" : edition.title
        author = selectedBook?.author ?? ""
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
        guard let workId = selectedBook?.externalReference["openlibraryKey"] else {
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
                        self.selectedEdition = editions.first
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

    func loadCoverImage() {
        if let book = selectedBook {
            self.selectedImage = book.coverImageData.flatMap { UIImage(data: $0) } // Convert Data to UIImage
        }
    }

    private func updateUIWithSelectedBook(_ book: Book) {
        self.title = book.title
        self.author = book.author
        self.totalPages = String(book.totalPages)
        self.isbn = book.isbn ?? ""
        self.publisher = book.publisher ?? ""
        self.publishYear = book.publishYear != nil ? String(book.publishYear!) : ""
        self.genre = book.genre ?? ""
        self.notes = book.notes ?? ""
        // Load cover image if available
        loadCoverImage()
    }
}
