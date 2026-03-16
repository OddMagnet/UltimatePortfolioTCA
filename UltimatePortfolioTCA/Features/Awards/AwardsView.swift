import SQLiteData
import SwiftUI
import SwiftUINavigation

struct AwardsView: View {
    @Selection struct IssueCounts {
        var total = 0
        var closed = 0
    }

    @FetchOne var issueCounts = IssueCounts()
    @FetchOne(Tag.all.count()) var tagCounts = 0
    @State private var selectedAward: Award?

    var columns: [GridItem] {
        [GridItem(.adaptive(minimum: 100, maximum: 100))]
    }

    init() {
        _issueCounts = FetchOne(
            wrappedValue: IssueCounts(),
            Issue.select { IssueCounts.Columns(total: $0.count(), closed: $0.count(filter: $0.isCompleted)) },
            animation: .default
        )
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                LazyVGrid(columns: columns) {
                    ForEach(Award.allAwards) { award in
                        Button {
                            selectedAward = award
                        } label: {
                            Image(systemName: award.image)
                                .resizable()
                                .scaledToFit()
                                .padding()
                                .frame(width: 100, height: 100)
                                .foregroundStyle(
                                    hasEarned(award)
                                        ? Color(award.color)
                                        : .secondary.opacity(0.5)
                                )
                        }
                        .accessibilityLabel(hasEarned(award) ? "Unlocked: \(award.name)" : "Locked")
                        .accessibilityHint(award.description)
                    }
                }
            }
            .navigationTitle("Awards")
            .toolbarTitleDisplayMode(.inlineLarge)
            .alert(item: $selectedAward) {
                Text(hasEarned($0) ? "Unlocked: \($0.name)" : "Locked")
            } actions: { _ in
                Button("Okay") {}
            } message: {
                Text($0.description)
            }
        }
    }

    private func hasEarned(_ award: Award) -> Bool {
        switch award.criterion {
        case .issues: issueCounts.total >= award.value
        case .closed: issueCounts.closed >= award.value
        case .tags: tagCounts >= award.value
        case .unlock: false
        }
    }
}

#Preview {
    withPreviewDependencies {
        AwardsView()
    }
}
