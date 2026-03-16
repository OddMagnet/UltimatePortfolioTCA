import ComposableArchitecture
import SwiftUI

@ViewAction(for: ContentFeature.self)
struct ContentView: View {
    @Bindable var store: StoreOf<ContentFeature>

    var body: some View {
        List(selection: $store.selectedIssueID) {
            ForEach(store.issueRows) { row in
                IssueRow(row)
                    .tag(row.issue.id)
            }
            .onDelete { send(.deleteIssuesSwiped(offsets: $0)) }
        }
        .overlay {
            if store.issueRows.isEmpty {
                if store.searchText.isEmpty, store.searchTokens.isEmpty {
                    ContentUnavailableView("No Issues", systemImage: "tray")
                } else {
                    ContentUnavailableView.search
                }
            }
        }
        .navigationTitle(store.filter.title)
        .searchable(
            text: $store.searchText,
            tokens: $store.searchTokens,
            prompt: "Search issues or type # for filters"
        ) { token in
            SearchTokenLabel(token: token)
        }
        .searchSuggestions {
            ForEach(store.suggestedTokens) { token in
                SearchTokenLabel(token: token)
                    .searchCompletion(token)
            }
        }
        .toolbar {
            if store.filter.hasShowCompletedToggle {
                Button {
                    store.showCompleted.toggle()
                } label: {
                    Label(
                        store.showCompleted ? "Hide Completed" : "Show Completed",
                        systemImage: store.showCompleted ? "eye" : "eye.slash"
                    )
                }
            }

            Button {
                send(.createIssueButtonTapped)
            } label: {
                Label("New Issue", systemImage: "square.and.pencil")
            }

            SortMenu(currentOrder: store.sortOrder) { order in
                send(.sortOrderSelected(order))
            }
        }
    }
}

private struct SearchTokenLabel: View {
    let token: SearchToken

    var body: some View {
        Label {
            Text(token.label)
                .accessibilityLabel(token.a11yLabel)
        } icon: {
            Image(systemName: token.systemImage)
                .foregroundStyle(token.tintColor ?? .accentColor)
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

    private var issueDate: Date {
        issue.modified ?? issue.created
    }

    var body: some View {
        HStack {
            PriorityIndicator(priority: issue.priority)
                .accessibilitySortPriority(90)

            VStack(alignment: .leading) {
                Text(issue.title)
                    .strikethrough(issue.isCompleted)
                    .foregroundStyle(issue.isCompleted ? .secondary : .primary)
                    .accessibilityLabel(issue.title)
                    .accessibilitySortPriority(100)

                if let tagNames {
                    Text(tagNames)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .accessibilityLabel("tagged with: \(tagNames)")
                        .accessibilitySortPriority(60)
                }
            }

            Spacer()
                .accessibilityLabel("Completed", isEnabled: issue.isCompleted)
                .accessibilitySortPriority(70)

            Text(issueDate.compactRelative())
                .font(.caption)
                .foregroundStyle(.secondary)
                .accessibilityLabel(issueDate.compactRelativeA11y())
                .accessibilitySortPriority(80)
        }
        .accessibilityElement(children: .combine)
    }
}

#Preview("Open") {
    withPreviewDependencies {
        NavigationStack {
            ContentView(store: Store(initialState: ContentFeature.State(filter: .open)) {
                ContentFeature()
            })
        }
    }
}

#Preview("Completed") {
    withPreviewDependencies {
        NavigationStack {
            ContentView(store: Store(initialState: ContentFeature.State(filter: .completed)) {
                ContentFeature()
            })
        }
    }
}

#Preview("Recent") {
    withPreviewDependencies {
        NavigationStack {
            ContentView(store: Store(initialState: ContentFeature.State(filter: .recent)) {
                ContentFeature()
            })
        }
    }
}

#Preview("Tag") {
    withPreviewDependencies {
        let tag = Tag(id: .tagSwiftUI, name: "SwiftUI")
        return NavigationStack {
            ContentView(store: Store(initialState: ContentFeature.State(filter: .tag(tag))) {
                ContentFeature()
            })
        }
    }
}

#Preview("Tag (Empty)") {
    withPreviewDependencies {
        let tag = Tag(id: .tagCoreData, name: "Core Data")
        return NavigationStack {
            ContentView(store: Store(initialState: ContentFeature.State(filter: .tag(tag))) {
                ContentFeature()
            })
        }
    }
}
