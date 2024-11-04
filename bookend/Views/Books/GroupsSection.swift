import SwiftUI

struct GroupsSection: View {
    var allGroups: [BookGroup]
    var isBookInGroup: (BookGroup) -> Bool
    var toggleGroup: (BookGroup) -> Void

    var body: some View {
        VStack {
            Section(header: Text("Groups")) {
                ForEach(allGroups) { group in
                    Toggle(isOn: Binding(
                        get: { isBookInGroup(group) },
                        set: { _ in toggleGroup(group) }
                    )) {
                        VStack(alignment: .leading) {
                            Text(group.name)
                            if let description = group.groupDescription {
                                Text(description)
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                        }
                    }
                }
            }
        }
    }
}