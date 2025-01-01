import SwiftUI

struct BookDetailsSection: View {
    @ObservedObject var viewModel: BookEditViewModel
    @Binding var usePercentage: Bool
    
    var body: some View {
        VStack(spacing: 8) {
            // Title Field
            Text("Title")
                .font(.headline)
                .frame(maxWidth: .infinity, alignment: .leading)
                .accentColor(Color("Accent1"))
            TextField("Enter title", text: $viewModel.title)
                .textFieldStyle(RoundedBorderTextFieldStyle())
            
            // Author Field
            Text("Author")
                .font(.headline)
                .frame(maxWidth: .infinity, alignment: .leading)
            TextField("Enter author", text: $viewModel.author)
                .textFieldStyle(RoundedBorderTextFieldStyle())
            
            // Total Pages Field
            Text("Total Pages")
                .font(.headline)
                .frame(maxWidth: .infinity, alignment: .leading)
            TextField("Enter total pages", text: $viewModel.totalPages)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .keyboardType(.numberPad)
            
            // Current Page / Progress Section
            VStack(alignment: .leading, spacing: 8) {
                Text("Reading Progress")
                    .font(.headline)
                    .frame(maxWidth: .infinity, alignment: .leading)
                
                HStack(spacing: 0) {
                    // Number option
                    Button(action: {
                        if usePercentage {
                            convertPercentageToPage()
                        }
                        usePercentage = false
                    }) {
                        Text("#")
                            .foregroundColor(usePercentage ? .gray : Color("Accent1"))
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                    }
                    
                    // Percentage option
                    Button(action: {
                        if !usePercentage {
                            convertPageToPercentage()
                        }
                        usePercentage = true
                    }) {
                        Text("%")
                            .foregroundColor(usePercentage ? Color("Accent1") : .gray)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                    }
                }
                .background(
                    Capsule()
                        .stroke(Color("Accent1"), lineWidth: 1)
                )
                .clipShape(Capsule())
                .buttonStyle(PlainButtonStyle())
            }
            
            HStack {
                TextField(usePercentage ? "Enter percentage" : "Enter current page", text: $viewModel.currentPage)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .keyboardType(usePercentage ? .decimalPad : .numberPad)
                    .onChange(of: viewModel.currentPage) { newValue in
                        guard !newValue.isEmpty else { return }
                        
                        if usePercentage {
                            // Validate percentage (0-100) with decimal support
                            if let percent = Double(newValue), percent > 100 {
                                viewModel.currentPage = "100"
                            }
                        } else {
                            // Validate page number (remains as integer)
                            if let page = Int(newValue),
                               let totalPages = Int(viewModel.totalPages),
                               page > totalPages {
                                viewModel.currentPage = viewModel.totalPages
                            }
                        }
                    }
                
                Text(usePercentage ? "%" : "pages")
                    .foregroundColor(.secondary)
            }
            
            // ISBN Field
            Text("ISBN")
                .font(.headline)
                .frame(maxWidth: .infinity, alignment: .leading)
            TextField("Enter ISBN", text: $viewModel.isbn)
                .textFieldStyle(RoundedBorderTextFieldStyle())
            
            // Publisher Field
            Text("Publisher")
                .font(.headline)
                .frame(maxWidth: .infinity, alignment: .leading)
            TextField("Enter publisher", text: $viewModel.publisher)
                .textFieldStyle(RoundedBorderTextFieldStyle())
            
            // Publish Year Field
            Text("Publish Year")
                .font(.headline)
                .frame(maxWidth: .infinity, alignment: .leading)
            TextField("Enter publish year", text: $viewModel.publishYear)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .keyboardType(.numberPad)
            
            // Genre Field
            Text("Genre")
                .font(.headline)
                .frame(maxWidth: .infinity, alignment: .leading)
            TextField("Enter genre", text: $viewModel.genre)
                .textFieldStyle(RoundedBorderTextFieldStyle())
            
            // Notes Field
            Text("Notes")
                .font(.headline)
                .frame(maxWidth: .infinity, alignment: .leading)
            TextField("Enter notes", text: $viewModel.notes)
                .textFieldStyle(RoundedBorderTextFieldStyle())
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(8)
    }
    
    /// Converts the currentPage from a page number to a percentage string.
    private func convertPageToPercentage() {
        guard let currentPageInt = Int(viewModel.currentPage),
              let totalPagesInt = Int(viewModel.totalPages),
              totalPagesInt > 0 else {
            viewModel.currentPage = "0"
            return
        }
        let percentage = Double(currentPageInt) / Double(totalPagesInt) * 100
        viewModel.currentPage = String(format: "%.1f", percentage)
    }
    
    /// Converts the currentPage from a percentage string back to a page number.
    /// Updates the viewModel.currentPage with the converted value.
    private func convertPercentageToPage() {
        guard let percentage = Double(viewModel.currentPage),
              let totalPagesInt = Int(viewModel.totalPages),
              totalPagesInt > 0 else {
            viewModel.currentPage = "0"
            return
        }
        // Clamp percentage between 0 and 100 before converting
        let clampedPercentage = min(max(percentage, 0), 100)
        let page = Double(totalPagesInt) * clampedPercentage / 100
        viewModel.currentPage = String(Int(page.rounded()))
    }
    
    /// Ensures the current page is in page format (not percentage) for saving
    func prepareForSave() {
        if usePercentage {
            // Temporarily disable usePercentage to prevent UI updates
            let originalValue = usePercentage
            usePercentage = false
            convertPercentageToPage()
            usePercentage = originalValue
        }
    }
} 
