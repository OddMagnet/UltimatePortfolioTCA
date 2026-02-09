# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

UltimatePortfolioTCA is a multiplatform SwiftUI app (iOS, macOS, visionOS) built with the Composable Architecture (TCA) and SQLiteData for persistence, with iCloud sync via SyncEngine. The Xcode project is at `UltimatePortfolioTCA.xcodeproj`.

## Build & Test Commands

This is an Xcode project — build and test via Xcode or `xcodebuild`:

```bash
# Build
xcodebuild -project UltimatePortfolioTCA.xcodeproj -scheme UltimatePortfolioTCA build

# Run all unit tests
xcodebuild -project UltimatePortfolioTCA.xcodeproj -scheme UltimatePortfolioTCA test -destination 'platform=iOS Simulator,name=iPhone 16'

# Run a single test (Swift Testing)
xcodebuild -project UltimatePortfolioTCA.xcodeproj -scheme UltimatePortfolioTCA test -destination 'platform=iOS Simulator,name=iPhone 16' -only-testing:UltimatePortfolioTCATests/SuiteOrTestName
```

When an Xcode MCP server is available, prefer using `BuildProject`, `RunAllTests`, and `RunSomeTests` tools instead.

## Architecture

- **UI Framework**: SwiftUI with `#Preview` macros
- **App Architecture**: Composable Architecture (TCA) from pointfreeco — features are `@Reducer` structs with `@ObservableState struct State`, `enum Action`, and `var body: some Reducer<State, Action>`. Views take `StoreOf<Feature>` directly (do NOT use legacy `ViewStore`/`WithViewStore`).
- **Navigation**: Three-column `NavigationSplitView` — Sidebar (always present), Content (optional, shown when a filter is selected), Detail (optional, shown when an issue is selected). `AppFeature` composes children via `Scope` (sidebar) and `.ifLet` (content/detail). Child-to-parent communication uses `BindableAction` — the parent intercepts binding changes to drive navigation.
- **Persistence**: SQLiteData (pointfreeco) with StructuredQueries for type-safe SQL (`@Table`, not GRDB's `FetchableRecord`/`PersistableRecord`). The test target links `SQLiteDataTestSupport` for in-memory database testing.
- **Database observation**: `@FetchAll`/`@FetchOne`/`@Fetch` live in TCA reducer `@ObservableState` (not in views), so the reducer can update queries dynamically for sorting/filtering.
- **Testing**: Swift Testing framework (`import Testing`, `@Test`, `@Suite`, `#expect`)

## Database

- **Setup**: `Schema.swift` in `Dependencies/` — `bootstrapDatabase()` on `DependencyValues` configures the database, runs migrations, and starts `SyncEngine`.
- **Models**: `Issue`, `Tag`, `IssueTag` (join table) — all use `@Table` with UUID primary keys.
- **iCloud sync**: `SyncEngine` initialized for all three tables. Entitlements and `CKSharingSupported` are configured. Metadatabase is attached for future sharing support.
- **Foreign keys**: `configuration.foreignKeysEnabled = true` — enforced at runtime.
- **`modified` column on `Issue`**: Managed by a SQLite trigger (`AFTER UPDATE ... WHEN OLD."modified" IS NEW."modified"`). The Swift property is `let modified: Date?` to prevent manual updates. Do NOT set `modified` from Swift code.
- **Tag names**: Use `COLLATE NOCASE` — case-insensitive by default.
- **Date precision**: `datetime('subsec')` for sub-second precision.
- **Debug only**: `eraseDatabaseOnSchemaChange = true`, SQL query tracing via `os.Logger`.
- **Context-aware database**: `SQLiteData.defaultDatabase()` automatically uses in-memory for previews, temporary file for tests, app container for live.

## Key Dependencies

| Package | Product(s) | Target |
|---------|-----------|--------|
| [swift-composable-architecture](https://github.com/pointfreeco/swift-composable-architecture) >= 1.23.1 | `ComposableArchitecture` | App |
| [sqlite-data](https://github.com/pointfreeco/sqlite-data) >= 1.5.1 | `SQLiteData` | App |
| [sqlite-data](https://github.com/pointfreeco/sqlite-data) >= 1.5.1 | `SQLiteDataTestSupport` | Tests |

## Swift Settings

- **Swift 6 language mode**: All targets use Swift 6 (`SWIFT_VERSION = 6.0`).
- **Strict concurrency**: `SWIFT_STRICT_CONCURRENCY = complete` at the project level.
- **Default nonisolated**: `SWIFT_DEFAULT_ACTOR_ISOLATION = nonisolated` — traditional Swift default. Mark `@MainActor` explicitly when needed.
- **Member import visibility**: `SWIFT_UPCOMING_FEATURE_MEMBER_IMPORT_VISIBILITY = YES` — modules must be explicitly imported to use their members.
- Deployment targets: iOS 26.2, macOS 26.2, visionOS 26.2

## Project Structure

The Xcode project uses **File System Synchronized Groups** — the on-disk folder structure under `UltimatePortfolioTCA/` is automatically mirrored in the project navigator. New Swift files placed in the source directory are automatically included in the build.

```
UltimatePortfolioTCA/
  App/                  — App entry point (UltimatePortfolioTCAApp.swift)
  Assets.xcassets
  Dependencies/         — Database setup, dependency keys (Schema.swift)
  Features/
    App/                — Root AppFeature + AppView (NavigationSplitView)
    Sidebar/            — SidebarFeature + SidebarView + IssueFilter
    Content/            — ContentFeature + ContentView (issue list)
    Detail/             — DetailFeature + DetailView (single issue)
  Models/               — Data models (Issue.swift, Tag.swift, IssueTag.swift)
UltimatePortfolioTCATests/    — Unit tests (Swift Testing)
UltimatePortfolioTCAUITests/  — UI tests
```

## Point-Free Skills (slash commands)

This project has Point-Free skills installed that provide up-to-date API guidance for the libraries used here. **Always invoke the relevant skill before writing code that uses these libraries** — they contain correct patterns, API usage, and best practices that may differ from what you learned in training.

Invoke skills with the Skill tool (e.g., `/pfw-composable-architecture`). **ALWAYS also invoke `/pfw-pfw` when using any pfw- skill** — it provides cross-cutting guidance for the entire Point-Free ecosystem. When a skill recommends adding a new library dependency, propose it to the user and wait for approval before adding it.

### Directly relevant to this project

| Skill | Use when... |
|-------|-------------|
| `/pfw-composable-architecture` | Writing or modifying TCA reducers, features, stores, effects, bindings |
| `/pfw-sqlite-data` | Working with SQLiteData schemas, queries, `@FetchAll`/`@FetchOne`, migrations, iCloud sync. Always also invoke `/pfw-structured-queries` for schema and query work, `/pfw-dependencies` for `@Dependency` and `prepareDependencies`, and `/pfw-issue-reporting` for error handling with `withErrorReporting` |
| `/pfw-structured-queries` | Type-safe SQL schema design and querying with `@Table` (used by SQLiteData) |
| `/pfw-testing` | Writing Swift Testing `@Suite`s and `@Test`s. Always also invoke `/pfw-dependencies` (dependency control), `/pfw-custom-dump` (`expectNoDifference`/`expectDifference`), and `/pfw-case-paths` for enum associated value mutation |
| `/pfw-dependencies` | Registering or overriding dependencies (`@Dependency`, `DependencyKey`, `prepareDependencies`) |
| `/pfw-modern-swiftui` | Building SwiftUI views — naming conventions, bindings, state initialization, tips |
| `/pfw-sharing` | Using `@Shared` to share/persist state across features |
| `/pfw-identified-collections` | Using `IdentifiedArrayOf` for collection state (TCA, SwiftUI, observable models) |
| `/pfw-case-paths` | Working with enum key paths and `@CasePathable` |
| `/pfw-custom-dump` | Using `customDump`, `diff`, `expectNoDifference` for debugging/testing. Prefer `expectDifference` over `expectNoDifference` when asserting mutations |
| `/pfw-swift-navigation` | State-driven navigation with enum domain modeling. Always also invoke `/pfw-case-paths` for enum navigation patterns |
| `/pfw-issue-reporting` | Using `reportIssue` and `withErrorReporting` for error handling |

### Also available

| Skill | Purpose |
|-------|---------|
| `/pfw-observable-models` | `@Observable` models outside of TCA. Also invoke `/pfw-dependencies` when using or adding dependencies to the model |
| `/pfw-snapshot-testing` | Snapshot testing with the SnapshotTesting library |
| `/pfw-macro-testing` | Testing Swift macros with MacroTesting |
| `/pfw-perception` | Back-porting Swift Observation to older platforms |
| `/pfw-spm` | Modifying Package.swift — adding targets, dependencies, etc. |
