import SwiftUI
import SwiftData

struct ReadingSessionView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    let book: Book
    @Binding var currentPage: Int
    
    @State private var startPage: Int
    @State private var endPage: Int // Change to Int for Picker selection
    @State private var duration: Int // Duration in seconds
    @State private var date = Date()
    
    // New state variables for duration input as Strings
    @State private var inputHours: String = "0"
    @State private var inputMinutes: String = "0"
    @State private var inputSeconds: String = "0"

    @State private var showingStartPicker = false
    @State private var showingEndPicker = false
    @State private var showPercentage: Bool
    
    var onSessionAdded: (() -> Void)?
    var existingSession: ReadingSession? // New optional property for existing session
    
    // Updated initializer to accept an optional ReadingSession
    init(book: Book, currentPage: Binding<Int>, duration: Int? = nil, startPage: Int? = nil, endPage: Int? = nil, date: Date? = nil, onSessionAdded: (() -> Void)? = nil, existingSession: ReadingSession? = nil) {
        self.book = book
        _currentPage = currentPage
        self.onSessionAdded = onSessionAdded
        // Initialize showPercentage based on book's preference
        self._showPercentage = State(initialValue: book.showPercentage) // Assuming book has this property
        
        // Initialize state variables based on existing session or defaults
        if let session = existingSession {
            self._startPage = State(initialValue: session.startPage)
            self._endPage = State(initialValue: session.endPage)
            self._duration = State(initialValue: session.duration)
            self._date = State(initialValue: session.date)
            // Initialize input fields based on existing session duration
            let totalDuration = session.duration
            self._inputHours = State(initialValue: "\(totalDuration / 3600)")
            self._inputMinutes = State(initialValue: "\((totalDuration % 3600) / 60)")
            self._inputSeconds = State(initialValue: "\(totalDuration % 60)")
            self.existingSession = existingSession
        } else {
            self._startPage = State(initialValue: startPage ?? currentPage.wrappedValue)
            self._endPage = State(initialValue: endPage ?? currentPage.wrappedValue)
            let totalDuration = duration ?? 30 // Default to 30 seconds if no duration is provided
            self._duration = State(initialValue: totalDuration)
            self._inputHours = State(initialValue: "\(totalDuration / 3600)")
            self._inputMinutes = State(initialValue: "\((totalDuration % 3600) / 60)")
            self._inputSeconds = State(initialValue: "\(totalDuration % 60)")
            self._date = State(initialValue: date ?? Date())
        }
    }
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 30) {
                DatePicker("Date", selection: $date, displayedComponents: [.date])
                
                // Update the page input section
                VStack(spacing: 12) {
                    HStack {
                        HStack {
                            Text("Start:")
                            TextField(showPercentage ? "%" : "Page", text: Binding(
                                get: { 
                                    showPercentage ? pageToPercentage(startPage) : String(startPage)
                                },
                                set: { newValue in
                                    if showPercentage {
                                        if let page = percentageToPage(newValue) {
                                            startPage = page
                                        }
                                    } else if let page = Int(newValue), page >= 0 {
                                        startPage = page
                                    }
                                }
                            ))
                            .keyboardType(.decimalPad)
                            .frame(width: showPercentage ? 70 : 60)
                            .padding(6)
                            .background(Color(UIColor.systemGray6))
                            .cornerRadius(8)
                        }
                        
                        Spacer()
                        
                        HStack {
                            Text("End:")
                            TextField(showPercentage ? "%" : "Page", text: Binding(
                                get: { 
                                    showPercentage ? pageToPercentage(endPage) : String(endPage)
                                },
                                set: { newValue in
                                    if showPercentage {
                                        if let page = percentageToPage(newValue) {
                                            endPage = min(page, book.totalPages)
                                        }
                                    } else if let page = Int(newValue), page >= startPage, page <= book.totalPages {
                                        endPage = page
                                    }
                                }
                            ))
                            .keyboardType(.decimalPad)
                            .frame(width: showPercentage ? 70 : 60)
                            .padding(6)
                            .background(Color(UIColor.systemGray6))
                            .cornerRadius(8)
                        }
                    }
                    
                    // Move the toggle control here
                    HStack(spacing: 0) {
                        Button(action: { showPercentage = false }) {
                            Image(systemName: "number")
                                .foregroundColor(!showPercentage ? .white : Color("Accent1"))
                                .padding(.horizontal, 12)
                                .padding(.vertical, 6)
                                .background(!showPercentage ? Color("Accent1") : .clear)
                        }
                        
                        Button(action: { showPercentage = true }) {
                            Image(systemName: "percent")
                                .foregroundColor(showPercentage ? .white : Color("Accent1"))
                                .padding(.horizontal, 12)
                                .padding(.vertical, 6)
                                .background(showPercentage ? Color("Accent1") : .clear)
                        }
                    }
                    .background(
                        Capsule()
                            .stroke(Color("Accent1"), lineWidth: 1)
                    )
                    .clipShape(Capsule())
                    .buttonStyle(PlainButtonStyle())
                    .frame(maxWidth: .infinity, alignment: .center)
                }

                // Duration Input Section using MultiPicker
                VStack(spacing: 20) {
                    Text("Duration")
                        .font(.headline)
                        .frame(maxWidth: .infinity, alignment: .center) // Center the Duration text

                    MultiPicker(data: [
                        ("Hours", Array(0...23).map { "\($0)" }), // Hours from 0 to 23
                        ("Minutes", Array(0...59).map { "\($0)" }), // Minutes from 0 to 59
                        ("Seconds", Array(0...59).map { "\($0)" }) // Seconds from 0 to 59
                    ], selection: Binding(
                        get: {
                            [inputHours, inputMinutes, inputSeconds]
                        },
                        set: { newValue in
                            inputHours = newValue[0]
                            inputMinutes = newValue[1]
                            inputSeconds = newValue[2]
                        }
                    ))
                    .frame(height: 200) // Set fixed height
                    .frame(maxWidth: .infinity, alignment: .center) // Center horizontally
                }
                .frame(maxWidth: .infinity) // Make the VStack take full width
                .padding(.top, UIScreen.main.bounds.height * 0.075)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        }
        .navigationTitle("New Reading Session")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .confirmationAction) {
                Button("Save") {
                    saveSession()
                }
            }
        }
        .padding(.horizontal)
        .padding(.top, 40)
    }
    
    private func saveSession() {
        // Convert input fields to integers
        let hours = Int(inputHours) ?? 0
        let minutes = Int(inputMinutes) ?? 0
        let seconds = Int(inputSeconds) ?? 0

        // Calculate total duration in seconds
        let totalDurationFromInput = (hours * 3600) + (minutes * 60) + seconds
        let finalDuration = totalDurationFromInput > 0 ? totalDurationFromInput : duration

        // Ensure we're using page numbers, not percentages
        let finalStartPage = showPercentage ? (percentageToPage(pageToPercentage(startPage)) ?? startPage) : startPage
        let finalEndPage = showPercentage ? (percentageToPage(pageToPercentage(endPage)) ?? endPage) : endPage

        // Update both the book and the binding
        if finalEndPage > book.currentPage {
            print("Updating book current page")
            book.currentPage = finalEndPage
            currentPage = finalEndPage
            print("Book current page updated to \(book.currentPage)")
        }
        
        if let existingSession = existingSession {
            print("Updating existing session")
            // Update existing session
            existingSession.startPage = finalStartPage
            existingSession.endPage = finalEndPage
            existingSession.duration = finalDuration
            existingSession.date = date
        } else {
            print("Creating new session")
            // Create new session
            let session = ReadingSession(
                book: book,
                startPage: finalStartPage,
                endPage: finalEndPage,
                duration: finalDuration,
                date: date
            )
            modelContext.insert(session)
        }
        
        do {
            onSessionAdded?()
            try modelContext.save()
            print("Reading session saved successfully")
            DispatchQueue.main.async {
                dismiss()
            }
        } catch {
            print("Failed to save reading session: \(error.localizedDescription)")
        }
    }
    
    private func pageToPercentage(_ page: Int) -> String {
        let percentage = Double(page) / Double(book.totalPages) * 100
        return String(format: "%.1f", percentage)
    }
    
    private func percentageToPage(_ percentage: String) -> Int? {
        guard let value = Double(percentage) else { return nil }
        return Int((value / 100) * Double(book.totalPages))
    }
}

// Preview
struct ReadingSessionView_Previews: PreviewProvider {
    static var previews: some View {
        // Create a mock Book instance for preview
        let mockBook = Book(
            title: "Sample Book",
            author: "Author Name",
            totalPages: 100,
            currentPage: 1,
            externalReference: [:]
        )
        
        ReadingSessionView(book: mockBook, currentPage: .constant(1), duration: 120) // Example with 120 seconds
            .previewLayout(.sizeThatFits) // Adjust the preview layout
            .padding() // Add padding for better visibility
    }
} 
