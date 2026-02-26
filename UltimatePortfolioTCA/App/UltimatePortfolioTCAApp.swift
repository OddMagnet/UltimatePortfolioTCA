import ComposableArchitecture
import SwiftUI

@main
struct UltimatePortfolioTCAApp: App {
    let store: StoreOf<AppFeature>

    init() {
        prepareDependencies {
            try! $0.bootstrapDatabase()
        }
        store = Store(initialState: AppFeature.State()) {
            AppFeature()
        }
    }

    var body: some Scene {
        WindowGroup {
            if !isTesting {
                AppView(store: store)
            }
        }
    }
}

func withPreviewDependencies(view: () -> any View) -> any View {
    withDependencies {
        try! $0.bootstrapDatabase()
        $0.date = .constant(Date(timeIntervalSince1970: 1_234_567_890))
    } operation: {
        view()
    }
}
