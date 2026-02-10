import ComposableArchitecture
import SwiftUI

struct ContentView: View {
    @Bindable var store: StoreOf<ContentFeature>

    var body: some View {
        List(selection: $store.selectedIssue) {
            if store.issues.isEmpty {
                ContentUnavailableView("No Issues", systemImage: "tray")
            } else {
                ForEach(store.issues) { issue in
                    IssueRow(issue: issue)
                        .tag(issue)
                }
                .onDelete { store.send(.deleteIssuesSwiped(offsets: $0)) }
            }
        }
        .navigationTitle(store.filter.title)
    }
}

private struct IssueRow: View {
    let issue: Issue

    var body: some View {
        HStack {
            Circle()
                .fill(issue.priorityColor)
                .frame(width: 10, height: 10)

            Text(issue.title)
                .strikethrough(issue.completed)
                .foregroundStyle(issue.completed ? .secondary : .primary)

            Spacer()

            if issue.completed {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundStyle(.green)
            }
        }
    }
}

#Preview {
    withPreviewDependencies {
        ContentView(store: Store(initialState: ContentFeature.State(filter: .all)) {
            ContentFeature()
        })
    }
}
