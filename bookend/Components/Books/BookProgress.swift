import SwiftUI
import SwiftData

struct BookProgress: View {
    let book: Book
    @Binding var currentPage: Int
    let modelContext: ModelContext
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Reading Progress")
                .font(.headline)
            
            HStack {
                Text("\(currentPage) of \(book.totalPages) pages")
                Spacer()
                Text("\(calculateProgress())%")
            }
            .font(.subheadline)
            
            ProgressView(value: Double(currentPage), total: Double(book.totalPages))
                .tint(.purple)
            
            PageStepper(currentPage: $currentPage, book: book, modelContext: modelContext)
        }
        .padding(.top)
    }
    
    private func calculateProgress() -> String {
        guard book.totalPages > 0 else { return "0" }
        let progress = (Double(currentPage) / Double(book.totalPages)) * 100
        return String(format: "%.0f", progress)
    }
}

struct PageStepper: View {
    @Binding var currentPage: Int
    let book: Book
    let modelContext: ModelContext
    
    var body: some View {
        Stepper("Current Page: \(currentPage)", value: $currentPage, in: 0...book.totalPages)
            .onChange(of: currentPage) { oldValue, newValue in
                book.currentPage = newValue
                do {
                    try modelContext.save()
                } catch {
                    print("Failed to save current page: \(error.localizedDescription)")
                }
            }
    }
} 