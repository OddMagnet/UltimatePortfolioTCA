import ComposableArchitecture
import SwiftUI

struct AppView: View {
    @Bindable var store: StoreOf<AppFeature>

    var body: some View {
        NavigationSplitView {
            SidebarView(store: store.scope(state: \.sidebar, action: \.sidebar))
        } content: {
            if let contentStore = store.scope(state: \.content, action: \.content) {
                ContentView(store: contentStore)
            } else {
                ContentUnavailableView("Select a Filter", systemImage: "line.3.horizontal.decrease.circle")
            }
        } detail: {
            DetailView(store: store.scope(state: \.detail, action: \.detail))
        }
        .alert(item: $store.tagDraft) {
            Text($0.name.isEmpty ? "New Tag" : "Rename Tag")
        } actions: { tagDraft in
            TextField("Tag name", text: tagDraft.name)
            Button("Save") { store.send(.tagAlertConfirmButtonTapped) }
            Button("Cancel") {}
        }
    }
}

#Preview("Open (Default)") {
    withPreviewDependencies {
        AppView(store: Store(initialState: AppFeature.State()) {
            AppFeature()
        })
    }
}

#Preview("Open / Selected") {
    withPreviewDependencies {
        AppView(store: Store(initialState: AppFeature.State(
            selectedFilter: .open,
            selectedIssueID: .issueLoginLayout
        )) {
            AppFeature()
        })
    }
}

#Preview("Completed") {
    withPreviewDependencies {
        AppView(store: Store(initialState: AppFeature.State(selectedFilter: .completed)) {
            AppFeature()
        })
    }
}

#Preview("Completed / Selected") {
    withPreviewDependencies {
        AppView(store: Store(initialState: AppFeature.State(
            selectedFilter: .completed,
            selectedIssueID: .issueIPadCrash
        )) {
            AppFeature()
        })
    }
}

#Preview("Recent") {
    withPreviewDependencies {
        AppView(store: Store(initialState: AppFeature.State(selectedFilter: .recent)) {
            AppFeature()
        })
    }
}

#Preview("Recent / Selected") {
    withPreviewDependencies {
        AppView(store: Store(initialState: AppFeature.State(
            selectedFilter: .recent,
            selectedIssueID: .issueLoginLayout
        )) {
            AppFeature()
        })
    }
}

#Preview("Tag") {
    withPreviewDependencies {
        let tag = Tag(id: .tagSwiftUI, name: "SwiftUI")
        return AppView(store: Store(initialState: AppFeature.State(selectedFilter: .tag(tag))) {
            AppFeature()
        })
    }
}

#Preview("Tag / Selected") {
    withPreviewDependencies {
        let tag = Tag(id: .tagSwiftUI, name: "SwiftUI")
        return AppView(store: Store(initialState: AppFeature.State(
            selectedFilter: .tag(tag),
            selectedIssueID: .issuePushNotifications
        )) {
            AppFeature()
        })
    }
}
