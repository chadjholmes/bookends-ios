import SwiftUI

struct BookPageSelector: View {
    @Binding var currentPage: Int
    var totalPages: Int
    @State private var showingCurrentPagePicker = false
    @AppStorage("showPercentage") private var showPercentage = false
    @State private var editingPercentage: Double = 0

    var body: some View {
        VStack {
            pageProgressHeader
            
            if totalPages > 0 {
                pageSlider
            } else {
                noPageCountMessage
            }
            
            if showingCurrentPagePicker {
                pageInputField
            }
        }
        .background(Color(.clear))
        .cornerRadius(8)
        .onTapGesture {
            UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
            showingCurrentPagePicker = false
        }
        .onChange(of: showingCurrentPagePicker) { isShowing in
            if isShowing {
                editingPercentage = (Double(currentPage) / Double(totalPages)) * 100
            }
        }
    }
    
    private var pageProgressHeader: some View {
        HStack {
            progressButton
            Spacer()
            displayToggle
        }
        .padding(.bottom, 8)
        .background(Color(.clear))
        .cornerRadius(8)
    }
    
    private var progressButton: some View {
        Button(action: {
            showingCurrentPagePicker.toggle()
            if showingCurrentPagePicker {
                UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
            }
        }) {
            HStack {
                Text("Progress ")
                    .font(.headline)
                    .foregroundColor(.gray)
                Text(formatProgress(current: currentPage, total: totalPages))
                    .font(.headline)
                    .foregroundColor(Color("Accent1"))
            }
        }
        .buttonStyle(PlainButtonStyle())
    }
    
    private var displayToggle: some View {
        HStack(spacing: 0) {
            Button(action: {
                showPercentage = false
            }) {
                Text("#")
                    .foregroundColor(showPercentage ? .gray : Color("Accent1"))
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
            }
            
            Button(action: {
                showPercentage = true
            }) {
                Text("%")
                    .foregroundColor(showPercentage ? Color("Accent1") : .gray)
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
    
    private var pageSlider: some View {
        Slider(value: Binding(
            get: { Double(currentPage) },
            set: { newValue in
                currentPage = Int(newValue)
            }
        ), in: 0...Double(totalPages), step: 1)
        .accentColor(Color("Accent1"))
    }
    
    private var noPageCountMessage: some View {
        VStack {
            Text("😢 We couldn't find total pages for this title 😢")
                .font(.headline)
                .foregroundColor(.gray)
                .padding(.top, 4)
            Text("you can still adjust the total below to match your copy!")
                .font(.subheadline)
                .foregroundColor(.gray)
        }
        .padding(.top, 8)
        .background(Color(.clear))
        .cornerRadius(8)
    }
    
    private var pageInputField: some View {
        HStack {
            if showPercentage {
                let formatter: NumberFormatter = {
                    let formatter = NumberFormatter()
                    formatter.numberStyle = .decimal
                    formatter.maximumFractionDigits = 1
                    formatter.minimumFractionDigits = 1
                    return formatter
                }()
                
                TextField("Enter %", value: $editingPercentage, formatter: formatter)
                    .keyboardType(.decimalPad)
                    .frame(width: 80)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .padding(.vertical, 8)
                
                Text("%")
                    .padding(.leading, 4)
            } else {
                TextField("Enter Page", value: $currentPage, formatter: NumberFormatter())
                    .keyboardType(.numberPad)
                    .frame(width: 80)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .padding(.vertical, 8)
                    .onChange(of: currentPage) { newValue in
                        if newValue > totalPages {
                            currentPage = totalPages
                        }
                    }
                
                Text("of \(totalPages)")
                    .padding(.leading, 4)
            }
        }
        .padding(.top, 8)
        .background(Color(.clear))
        .cornerRadius(8)
        .toolbar {
            ToolbarItem(placement: .keyboard) {
                HStack {
                    Spacer()
                    Button("Done") {
                        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
                        showingCurrentPagePicker = false
                        if showPercentage {
                            updatePageFromPercentage()
                        }
                    }
                }
            }
        }
    }

    private func formatProgress(current: Int, total: Int) -> String {
        return showPercentage 
            ? String(format: "%.1f%%", (Double(current) / Double(total)) * 100)
            : "\(current) of \(total)"
    }

    private func updatePageFromPercentage() {
        var newPage = Int((editingPercentage / 100.0) * Double(totalPages))
        if editingPercentage > 100 {
            editingPercentage = 100
            newPage = totalPages
        }
        currentPage = newPage
    }
}
