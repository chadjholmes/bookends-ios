import SwiftUI
import SwiftData

struct GoalsView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(
        filter: #Predicate<ReadingGoal> { goal in true },
        animation: .default
    ) private var goals: [ReadingGoal]
    @Query private var sessions: [ReadingSession]
    
    @State private var showingAddGoal = false
    @State private var editingGoal: ReadingGoal?
    @State private var showingDeleteAlert = false
    @State private var goalToDelete: ReadingGoal?
    @State private var showingClearSessionsAlert = false
    
    var body: some View {
        NavigationView {
            List {
                Text("Total goals: \(goals.count)")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .onAppear {
                        print("\n=== Goals View Debug ===")
                        print("Goals count: \(goals.count)")
                        
                        // Try direct fetch
                        do {
                            let descriptor = FetchDescriptor<ReadingGoal>()
                            let directFetch = try modelContext.fetch(descriptor)
                            print("\nDirect fetch results:")
                            print("Found \(directFetch.count) goals")
                            directFetch.forEach { goal in
                                print("- Goal: \(goal.target) \(goal.type) (active: \(goal.isActive))")
                            }
                        } catch {
                            print("Direct fetch failed: \(error)")
                        }
                    }
                
                ForEach(goals) { goal in
                    GoalCard(goal: goal, sessions: sessions)
                        .onAppear {
                            print("Displaying goal: \(goal.target) \(goal.type)")
                        }
                        .swipeActions(edge: .trailing) {
                            Button(role: .destructive) {
                                goalToDelete = goal
                                showingDeleteAlert = true
                            } label: {
                                Label("Delete", systemImage: "trash")
                            }
                            
                            Button {
                                editingGoal = goal
                            } label: {
                                Label("Edit", systemImage: "pencil")
                            }
                            .tint(.orange)
                        }
                        .swipeActions(edge: .leading) {
                            Button {
                                toggleGoalStatus(goal)
                            } label: {
                                Label(goal.isActive ? "Pause" : "Resume", 
                                      systemImage: goal.isActive ? "pause.fill" : "play.fill")
                            }
                            .tint(goal.isActive ? .yellow : .green)
                        }
                }
            }
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button(action: { showingAddGoal = true }) {
                        Image(systemName: "plus")
                    }
                }
                ToolbarItem(placement: .bottomBar) {
                    Button("Clear All Sessions (Testing Only)") {
                        showingClearSessionsAlert = true
                    }
                    .foregroundColor(.red)
                }
            }
            .sheet(isPresented: $showingAddGoal) {
                GoalEditView(mode: .create)
            }
            .sheet(item: $editingGoal) { goal in
                GoalEditView(mode: .edit(goal))
            }
            .alert("Delete Goal?", isPresented: $showingDeleteAlert) {
                Button("Cancel", role: .cancel) {}
                Button("Delete", role: .destructive) {
                    if let goal = goalToDelete {
                        deleteGoal(goal)
                    }
                }
            } message: {
                Text("This action cannot be undone.")
            }
            .alert("Clear All Reading Sessions?", isPresented: $showingClearSessionsAlert) {
                Button("Cancel", role: .cancel) {}
                Button("Clear", role: .destructive) {
                    clearAllReadingSessions()
                }
            } message: {
                Text("This will delete all reading sessions for all books. This action cannot be undone.")
            }
        }
    }
    
    private func toggleGoalStatus(_ goal: ReadingGoal) {
        print("Toggling goal status: \(goal.target) \(goal.type)")
        goal.isActive.toggle()
        try? modelContext.save()
        print("Goal status toggled to: \(goal.isActive)")
    }
    
    private func deleteGoal(_ goal: ReadingGoal) {
        print("Attempting to delete goal: \(goal.target) \(goal.type)")
        modelContext.delete(goal)
        try? modelContext.save()
        print("Goal deleted successfully")
    }
    
    private func clearAllReadingSessions() {
        print("Clearing all reading sessions...")
        sessions.forEach { session in
            modelContext.delete(session)
        }
        try? modelContext.save()
        print("All reading sessions cleared.")
    }
}

// Combined Create/Edit view
struct GoalEditView: View {
    enum Mode {
        case create
        case edit(ReadingGoal)
    }
    
    let mode: Mode
    
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    
    @State private var selectedType: ReadingGoal.GoalType = .pages
    @State private var selectedPeriod: ReadingGoal.GoalPeriod = .daily
    @State private var target: String = ""
    @State private var isActive: Bool = true
    
    @Query private var existingGoals: [ReadingGoal]
    
    private var isDuplicatePeriod: Bool {
        switch mode {
        case .create:
            return existingGoals.contains { $0.period == selectedPeriod }
        case .edit(let editingGoal):
            return existingGoals.contains { goal in 
                goal.period == selectedPeriod && goal.id != editingGoal.id
            }
        }
    }
    
    init(mode: Mode) {
        self.mode = mode
        if case .edit(let goal) = mode {
            _selectedType = State(initialValue: goal.type)
            _selectedPeriod = State(initialValue: goal.period)
            _target = State(initialValue: String(goal.target))
            _isActive = State(initialValue: goal.isActive)
        }
    }
    
    var body: some View {
        NavigationView {
            Form {
                Section("Goal Details") {
                    Picker("Goal Type", selection: $selectedType) {
                        Text("Pages").tag(ReadingGoal.GoalType.pages)
                        Text("Minutes").tag(ReadingGoal.GoalType.minutes)
                        Text("Books").tag(ReadingGoal.GoalType.books)
                    }
                    
                    Picker("Period", selection: $selectedPeriod) {
                        Text("Daily").tag(ReadingGoal.GoalPeriod.daily)
                        Text("Weekly").tag(ReadingGoal.GoalPeriod.weekly)
                        Text("Monthly").tag(ReadingGoal.GoalPeriod.monthly)
                        Text("Yearly").tag(ReadingGoal.GoalPeriod.yearly)
                    }
                    
                    TextField("Target", text: $target)
                        .keyboardType(.numberPad)
                }
                
                Section("Status") {
                    Toggle("Active", isOn: $isActive)
                }
                
                if case .edit = mode {
                    Section {
                        HStack {
                            Spacer()
                            Button("Reset Progress", role: .destructive) {
                                resetProgress()
                            }
                            Spacer()
                        }
                    }
                }
                
                if isDuplicatePeriod {
                    Section {
                        Text("A goal for this time period already exists")
                            .foregroundColor(.red)
                            .font(.caption)
                    }
                }
            }
            .navigationTitle(mode.title)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        saveGoal()
                    }
                    .disabled(target.isEmpty || isDuplicatePeriod)
                }
            }
        }
    }
    
    private func saveGoal() {
        print("\n=== Save Goal Debug ===")
        guard let targetValue = Int(target) else { 
            print("❌ Invalid target value: \(target)")
            return 
        }
        
        print("ModelContext initialized")
        
        switch mode {
        case .create:
            let goal = ReadingGoal(
                type: selectedType,
                target: targetValue,
                period: selectedPeriod,
                isActive: isActive
            )
            print("\nCreating new goal:")
            print("- Type: \(selectedType)")
            print("- Target: \(targetValue)")
            print("- Period: \(selectedPeriod)")
            print("- Active: \(isActive)")
            
            modelContext.insert(goal)
            print("✅ Goal inserted into context")
            
        case .edit(let goal):
            print("\nUpdating existing goal:")
            print("Before changes:")
            print("- Type: \(goal.type)")
            print("- Target: \(goal.target)")
            print("- Period: \(goal.period)")
            print("- Active: \(goal.isActive)")
            
            goal.type = selectedType
            goal.target = targetValue
            goal.period = selectedPeriod
            goal.isActive = isActive
            
            print("\nAfter changes:")
            print("- Type: \(selectedType)")
            print("- Target: \(targetValue)")
            print("- Period: \(selectedPeriod)")
            print("- Active: \(isActive)")
        }
        
        do {
            print("\nAttempting to save context...")
            try modelContext.save()
            print("✅ Context saved successfully")
            
            // Verify save immediately
            let descriptor = FetchDescriptor<ReadingGoal>()
            let verification = try modelContext.fetch(descriptor)
            print("\nVerification fetch after save:")
            print("Found \(verification.count) goals")
            verification.forEach { goal in
                print("- Goal: \(goal.target) \(goal.type) (active: \(goal.isActive))")
            }
        } catch {
            print("❌ Failed to save context: \(error)")
        }
        
        dismiss()
    }
    
    private func resetProgress() {
        if case .edit(let goal) = mode {
            goal.currentStreak = 0
            goal.lastProgress = nil
            try? modelContext.save()
            dismiss()
        }
    }
}

extension GoalEditView.Mode {
    var title: String {
        switch self {
        case .create:
            return "New Goal"
        case .edit:
            return "Edit Goal"
        }
    }
}

// Add this struct before or after GoalsView
struct GoalCard: View {
    let goal: ReadingGoal
    let sessions: [ReadingSession]
    
    var progress: Double {
        goal.calculateProgress(from: sessions)
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: goal.type.iconName)
                    .foregroundColor(goal.isActive ? .primary : .secondary)
                Text("\(goal.target) \(goal.type.description) \(goal.period.description)")
                    .font(.headline)
                Spacer()
                if !goal.isActive {
                    Text("Paused")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            
            ProgressView(value: progress)
                .tint(progress >= 1.0 ? .green : (progress >= 0.7 ? .yellow : .red))
            
            HStack {
                Text("Current streak: \(goal.currentStreak)")
                    .font(.caption)
                Spacer()
                Text("\(Int(progress * 100))%")
                    .font(.caption)
            }
            .foregroundColor(.secondary)
        }
        .padding()
    }
}

// You'll also need these extensions to support the GoalCard
extension ReadingGoal.GoalType {
    var iconName: String {
        switch self {
        case .pages: return "book"
        case .minutes: return "clock"
        case .books: return "books.vertical"
        }
    }
    
    var description: String {
        switch self {
        case .pages: return "pages"
        case .minutes: return "minutes"
        case .books: return "books"
        }
    }
}

extension ReadingGoal.GoalPeriod {
    var description: String {
        switch self {
        case .daily: return "per day"
        case .weekly: return "per week"
        case .monthly: return "per month"
        case .yearly: return "per year"
        }
    }
}

extension ReadingGoal {
    var progressColor: Color {
        let progress = calculateProgress(from: [])
        if progress >= 1.0 { return .green }
        if progress >= 0.7 { return .yellow }
        return .red
    }
}

// Add a preview provider for testing
#Preview {
    GoalsView()
        .modelContainer(for: ReadingGoal.self, inMemory: true)
} 
