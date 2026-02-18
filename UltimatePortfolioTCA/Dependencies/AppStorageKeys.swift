import ComposableArchitecture

/// Centralized keys for `@Shared(.appStorage(...))` to prevent typos and duplication.
enum AppStorageKeys {
    static let showCompleted = "showCompleted"
    static let issueSortOrder = "issueSortOrder"
    static let tagSortOrder = "tagSortOrder"
}
