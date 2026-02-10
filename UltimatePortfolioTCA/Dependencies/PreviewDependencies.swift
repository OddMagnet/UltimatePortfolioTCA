import Dependencies
import SwiftUI

// TODO: Revert to prepareDependencies once swift-dependencies > 1.10.1 fixes #Preview + @FetchAll
func withPreviewDependencies<Content: View>(@ViewBuilder content: () -> Content) -> Content {
    withDependencies {
        try! $0.bootstrapDatabase()
    } operation: {
        content()
    }
}
