import ComposableArchitecture
import SwiftUI

@ViewAction(for: ContentFeature.self)
struct ContentView: View {
    @Bindable var store: StoreOf<ContentFeature>

    var body: some View {
        Group {
            if store.issueRows.isEmpty {
                ContentUnavailableView("No Issues", systemImage: "tray")
            } else {
                List(selection: $store.selectedIssue) {
                    ForEach(store.issueRows) { row in
                        IssueRow(row)
                            .tag(row.issue)
                    }
                    .onDelete { send(.deleteIssuesSwiped(offsets: $0)) }
                }
            }
        }
        .navigationTitle(store.filter.title)
        .toolbarTitleDisplayMode(.inlineLarge)
        .toolbar {
            if store.filter != .completed {
                Button {
                    store.showCompleted.toggle()
                } label: {
                    Label(
                        store.showCompleted ? "Hide Completed" : "Show Completed",
                        systemImage: store.showCompleted ? "eye" : "eye.slash"
                    )
                }
            }

            SortMenu(currentOrder: store.sortOrder) { order in
                send(.didSelectOrder(order))
            }
        }
    }
}

private struct IssueRow: View {
    let issue: Issue
    let tagNames: String?

    init(_ row: IssueWithTags) {
        issue = row.issue
        tagNames = row.tagNames
    }

    var body: some View {
        HStack {
            Circle()
                .fill(issue.priorityColor)
                .frame(width: 10, height: 10)
                .accessibilityLabel("Priority: \(issue.priority.label)")

            VStack(alignment: .leading) {
                Text(issue.title)
                    .strikethrough(issue.isCompleted)
                    .foregroundStyle(issue.isCompleted ? .secondary : .primary)

                if let tagNames {
                    Text(tagNames)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }

            Spacer()

            if issue.isCompleted {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundStyle(.green)
            }
        }
    }
}

#Preview {
    NavigationStack {
        ContentView(store: Store(
            initialState: ContentFeature.State(filter: .open),
            reducer: { ContentFeature() },
            withDependencies: { try! $0.bootstrapDatabase() }
        ))
    }
}
