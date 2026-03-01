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
- **Navigation**: Three-column `NavigationSplitView` — Sidebar (always present), Content (optional, shown when a filter is selected), Detail (always present — shows issue details, the edit/create form, or an empty state with a "Create New Issue" button). `AppFeature` composes children via `Scope` (sidebar, detail) and `.ifLet` (content). Child reducers intercept their own binding changes and forward them as delegate actions with associated values (e.g., `selectedFilterChanged(IssueFilter?)`), so the parent only handles delegate actions to drive navigation. Content list selection uses `selectedIssueID: Issue.ID?` (not `Issue?`) so that `@FetchAll` reloads (which produce new `Issue` values with updated `modified` timestamps) don't break SwiftUI's `List(selection:)` matching.
- **Child-to-parent communication**: Child reducers in the `NavigationSplitView` columns use **delegate actions** (not `@Dependency(\.dismiss)`) to communicate back to `AppFeature`. This is because `AppFeature` must coordinate multiple children simultaneously — e.g., clearing both the detail column and the content list's selection when an issue is deleted. `dismiss` only removes the child's own state and can't carry semantic context (deleted vs. navigated away). Reserve `@Dependency(\.dismiss)` for modally-presented features (sheets, popovers) where the parent doesn't need to react.
- **ViewAction**: Features with view-sent actions use the `ViewAction` protocol to separate view actions (`enum View`) from internal actions (`delegate`, `binding`). Views use `@ViewAction(for:)` to send view actions via `send()` instead of `store.send()`.
- **Persistence**: SQLiteData (pointfreeco) with StructuredQueries for type-safe SQL (`@Table`, not GRDB's `FetchableRecord`/`PersistableRecord`).
- **Database observation**: `@FetchAll`/`@FetchOne` live in TCA reducer `@ObservableState` (not in views), so the reducer can update queries dynamically for sorting/filtering. `@Selection` structs are used for custom row types when queries involve joins or aggregations (e.g., `TagWithCount`, `TagRow`, `IssueWithTags`, `SmartFilterCounts`).
- **User preferences**: `@Shared(.appStorage(AppStorageKeys.key))` from the Sharing library (re-exported by TCA) persists user preferences. Keys are centralized in `AppStorageKeys` enum (`Dependencies/AppStorageKeys.swift`) to prevent typos. Current keys: `showCompleted`, `issueSortOrder`, `tagSortOrder`.
- **Alerts**: `DetailFeature` uses TCA's `AlertState` via `@Presents var alert` and `.ifLet(\.$alert, action: \.alert)` for the delete confirmation dialog. The view uses `.alert($store.scope(state: \.alert, action: \.alert))`. `AppFeature` uses native SwiftUI `.alert(item:)` with `Tag.Draft?` state for tag creation/renaming, since TCA's `AlertState` does not support text fields.
- **No-op save prevention**: `DetailFeature` compares the edit draft and tag selection against the current issue before writing. If nothing changed, the database write is skipped entirely, preventing unnecessary `modified` timestamp updates from the trigger. New issues (where `issueID` is `nil`) always save since there is no existing issue to compare against.
- **Completed-issue visibility**: `IssueFilter` centralizes the rules via `hasShowCompletedToggle` (whether the UI shows the toggle) and `showsCompletedIssues(with:)` (whether the query includes completed issues). The "Open" filter never shows completed issues; "Completed" always does; "Recent" and tag filters respect the `showCompleted` user preference.
- **Testing**: Swift Testing framework — see the dedicated **Testing** section below for conventions, patterns, and linking rules.

## Database

- **Setup**: `Schema.swift` in `Dependencies/` — `bootstrapDatabase()` on `DependencyValues` configures the database, runs migrations, starts `SyncEngine`, registers temporary triggers, and seeds sample data (debug only).
- **Sample data**: `SampleData.swift` in `Dependencies/` — `seedSampleData()` on `DatabaseWriter` provides seed issues, tags, and associations for development/previews. Issue dates are computed relative to `@Dependency(\.date.now)` via `daysAgo(_:)`, making them deterministic in tests when the date dependency is pinned. `UUID+SampleData.swift` defines static UUID constants (e.g., `.tagSwiftUI`, `.issueLoginLayout`) for all sample entities, used in seed data, previews, and tests.
- **Models**: `Issue`, `Tag`, `IssueTag` (join table) — all use `@Table` with UUID primary keys. `Tag.Draft` conforms to `Equatable` (required for SwiftUI's `.alert(item:)`).
- **iCloud sync**: `SyncEngine` initialized for all three tables. Entitlements and `CKSharingSupported` are configured. Metadatabase is attached for future sharing support.
- **Foreign keys**: `configuration.foreignKeysEnabled = true` — enforced at runtime.
- **`modified` column on `Issue`**: Managed by a type-safe temporary trigger (`Issue.createTemporaryTrigger(after: .update(touch: \.modified))`), created after migrations in `bootstrapDatabase()`. The trigger uses `!SyncEngine.$isSynchronizing` to skip SyncEngine's no-op updates. The Swift property is `let modified: Date?` to prevent manual updates. Do NOT set `modified` from Swift code.
- **Tag names**: Use `COLLATE NOCASE` — case-insensitive by default.
- **Date precision**: `datetime('subsec')` for sub-second precision.
- **Debug only**: `eraseDatabaseOnSchemaChange = true`, SQL query tracing via `os.Logger`.
- **Context-aware database**: `SQLiteData.defaultDatabase()` automatically uses in-memory for previews, temporary file for tests, app container for live.
- **Previews**: Use the `withPreviewDependencies(view:)` helper (defined in `UltimatePortfolioTCAApp.swift`) which wraps preview content in `withDependencies { try! $0.bootstrapDatabase(); $0.date = .constant(...) } operation: { ... }`. Inside the closure, `Store` uses the plain `Store(initialState:) { Reducer() }` initializer — no `withDependencies` trailing closure on `Store` itself. This is a workaround for a `prepareDependencies` bug in swift-dependencies (since 1.10.1) with `@FetchAll` — revert to `prepareDependencies` once fixed.
- **Query operation ordering**: Use `Where → Group → Order → Join → Select` ordering in StructuredQueries chains. Operations that don't need join tables should come before joins (per StructuredQueries convention), and within the pre-join operations, filter first, then group, then sort — matching the logical data pipeline.
- **Query convenience properties**: `Issue.TableColumns` has reusable computed properties (`lastActivity`, `isNotCompleted`, `isRecent`) available as `$0.property` inside StructuredQueries closures. Note: custom `TableColumns` computed properties cannot be accessed via the static shorthand (`Issue.lastActivity`) — only real `@Table` columns support `@dynamicMemberLookup` on the static subscript.
- **Extracted query helpers**: Common filter/ordering logic is extracted into model file extensions:
  - `Issue.filter(with:)` returns `Where<Issue>` for an `IssueFilter` predicate
  - `extension Select where From == Issue, Joins == ()` adds `.order(by:)` for `IssueSortOrder` (pre-join only)
  - `extension Select where From == Tag, Joins == (IssueTag?, Issue?)` adds `.order(by:showCompleted:)` for `TagSortOrder` (post-join — `leftJoin` produces optional `Joins` types)
- **App entry point**: `prepareDependencies` must complete before `Store` initialization, since `AppFeature.State()` constructs child states with `@FetchAll` queries that require the database. The app body guards with `if !isTesting` (from IssueReporting, re-exported via ComposableArchitecture) to skip UI during test runs.

## Key Dependencies

| Package | Product(s) | Target |
|---------|-----------|--------|
| [swift-composable-architecture](https://github.com/pointfreeco/swift-composable-architecture) >= 1.23.1 | `ComposableArchitecture` | App |
| [sqlite-data](https://github.com/pointfreeco/sqlite-data) >= 1.5.1 | `SQLiteData` | App |
| [swift-dependencies](https://github.com/pointfreeco/swift-dependencies) >= 1.11.0 | `DependenciesTestSupport` | Tests |
| [swift-snapshot-testing](https://github.com/pointfreeco/swift-snapshot-testing) >= 1.18.9 | `InlineSnapshotTesting`, `SnapshotTesting`, `SnapshotTestingCustomDump` | Tests |

## Swift Settings

- **Swift 6 language mode**: All targets use Swift 6 (`SWIFT_VERSION = 6.0`).
- **Strict concurrency**: `SWIFT_STRICT_CONCURRENCY = complete` at the project level.
- **Default nonisolated**: `SWIFT_DEFAULT_ACTOR_ISOLATION = nonisolated` — traditional Swift default. Mark `@MainActor` explicitly when needed.
- **Approachable concurrency**: `SWIFT_APPROACHABLE_CONCURRENCY = YES` — enables Swift 6.2 approachable concurrency.
- **Upcoming features**:
  - `SWIFT_UPCOMING_FEATURE_MEMBER_IMPORT_VISIBILITY = YES` — modules must be explicitly imported to use their members.
  - `SWIFT_UPCOMING_FEATURE_INTERNAL_IMPORTS_BY_DEFAULT = YES` — imports are internal by default.
  - `SWIFT_UPCOMING_FEATURE_EXISTENTIAL_ANY = YES` — requires `any` keyword for existential types.
- **Import minimization**: Only import the modules you directly use. `ComposableArchitecture` re-exports `Dependencies`, `Sharing`, `CasePaths`, `IssueReporting`, and others via `@_exported import`. `SQLiteData` re-exports `StructuredQueries` and `Dependencies`. Do not add redundant explicit imports for these transitive modules. The `MEMBER_IMPORT_VISIBILITY` upcoming feature enforces this at compile time.
- Deployment targets: iOS 26.2, macOS 26.2, visionOS 26.2

## Project Structure

The Xcode project uses **File System Synchronized Groups** — the on-disk folder structure under `UltimatePortfolioTCA/` is automatically mirrored in the project navigator. New Swift files placed in the source directory are automatically included in the build.

```
UltimatePortfolioTCA/
  App/                  — App entry point (UltimatePortfolioTCAApp.swift)
  Assets.xcassets
  Dependencies/         — Database setup, sample data, constants (Schema.swift, SampleData.swift, AppStorageKeys.swift, UUID+SampleData.swift)
  Features/
    App/                — Root AppFeature + AppView (NavigationSplitView) + Common/
    Sidebar/            — SidebarFeature + SidebarView + IssueFilter
    Content/            — ContentFeature + ContentView (issue list)
    Detail/             — DetailFeature + DetailView + Subviews/ (IssueView, EditIssueView)
    App/Common/Extensions/ — Foundation extensions (Date+CompactRelative)
  Models/               — Data models (Issue.swift, Tag.swift, IssueTag.swift) + SortOrder/
UltimatePortfolioTCATests/    — Unit tests (Swift Testing)
```

## Shared UI Components (`Features/App/Common/`)

- **`SortMenu`** + **`SortOrderProtocol`**: Generic toolbar sort menu. `SortOrderProtocol` pairs a `Field` enum with `isAscending`; `apply(_:)` toggles direction for the same field or replaces with a new field's default. Conforming types: `IssueSortOrder`, `TagSortOrder` (in `Models/SortOrder/`).
- **`FlowLayout`**: Custom SwiftUI `Layout` that arranges children left-to-right, wrapping to the next line. Configurable `horizontalSpacing`/`verticalSpacing` (default 6). Used for tag chips.
- **`ChipStyle`** + **`.chipStyle(isAssigned:)`**: A `ViewModifier` applying capsule-shaped chip styling to any view. Assigned = white text on tint background; unassigned = secondary text on tertiary fill. Uses `.geometryGroup()` to keep text and background animations in sync.
- **`PriorityIndicator`**: 10pt colored circle for `Issue.Priority` with an accessibility label. Color is defined on `Issue.Priority.color`.
- **`Date.compactRelative(to:)`** (in `Extensions/Date+CompactRelative.swift`): Compact relative date string — "< 1 hour" / "> N hours" (today), "> N days" (this week), locale-aware day+month (this year), "> N years" (older). Used in issue row trailing labels.

## Commits

- **No `Co-Authored-By`**: Do not add `Co-Authored-By` trailers to commit messages. Claude's role in this project is scaffolding, idea exploration, and commit message authoring — the developer reviews and revises all code before committing, so the trailer doesn't reflect the actual workflow.

## Code Quality Tools

- **SwiftLint** + **SwiftFormat**: Both run on every Xcode build via a Run Script phase (report-only — no file modifications). SwiftLint handles safety, complexity, and semantic rules; SwiftFormat `--lint` checks formatting. All style rules in SwiftLint are disabled to avoid conflicts.
- **SwiftFormat pre-commit hook**: Auto-formats staged `.swift` files before each commit. Run `./scripts/install-hooks.sh` to install.
- **Manual formatting**: `swiftformat UltimatePortfolioTCA/ UltimatePortfolioTCATests/` to format all source.
- **Tool installation**: `brew bundle` from the project root (or `brew install swiftlint swiftformat`).
- **Config files**: `.swiftlint.yml` (lint rules), `.swiftformat` (format rules), `.swift-version` (Swift version for tools). All rules are listed explicitly with comments — toggle rules directly in the config files.
- **Rule philosophy**: SwiftFormat owns all formatting/style. SwiftLint owns safety, correctness, and complexity. If a new rule is style-related, disable it in `.swiftlint.yml` and add the SwiftFormat equivalent instead.

## Debugging

- **Evidence over theory**: When the user provides debug output, logs, or test results, treat that as the primary evidence. If the evidence contradicts your current hypothesis, discard the hypothesis and re-evaluate from the evidence — do not rationalize the evidence to fit the theory.

## Testing

Uses the Swift Testing framework (`import Testing`, `@Test`, `@Suite`, `#expect`). Test files live in `UltimatePortfolioTCATests/`.

### Base test suite

`UltimatePortfolioTCATests.swift` defines `BaseTestSuite` — a `@Suite` with pinned dependencies and a seeded database:

```swift
@Suite(
    .dependency(\.date.now, Date(timeIntervalSince1970: 1_234_567_890)),
    .dependency(\.uuid, .incrementing),
    .dependencies {
        try $0.bootstrapDatabase()
        try $0.defaultDatabase.seedSampleData()
    }
)
struct BaseTestSuite {}
```

All feature test suites are nested via `extension BaseTestSuite { @MainActor struct FeatureTests { ... } }` to inherit these traits. `@MainActor` must be applied to each nested suite individually — it is **not** inherited from the base suite.

### TestStore conventions

- Use `TestStoreOf<Feature>` for isolated feature testing.
- Features under test require `Equatable` on their `State` and any `@Selection` types used in state (e.g., `TagWithCount`, `SmartFilterCounts`).
- **Action key path syntax**: Use case key paths for `send` and `receive`:
  ```swift
  await store.send(\.view.createTagButtonTapped)
  await store.send(\.view.deleteTagSwiped, tag)
  await store.receive(\.delegate.createTag, UUID(0))
  ```
  This requires `@CasePathable` on `Action` sub-enums (`Delegate`, `View`). The top-level `Action` already gets `@CasePathable` from `@Reducer`, but nested enums need it explicitly.
- **DO NOT** conform `Action` enums to `Equatable`.

### Inline snapshots

Use `assertInlineSnapshot(of:as:.customDump)` from `InlineSnapshotTesting` + `SnapshotTestingCustomDump` to capture full state snapshots (e.g., initial state after database seeding). Never hand-write or hand-edit snapshot content — run the test in record mode to generate or update snapshots.

### Test target linking

Do **not** link transitive dependencies to the test target — they come through `@testable import UltimatePortfolioTCA`. Only link test-specific products:
- `DependenciesTestSupport`
- `InlineSnapshotTesting`
- `SnapshotTesting`
- `SnapshotTestingCustomDump`

Linking a product to both the app target and the test target causes duplicate class warnings and potential runtime issues.

### Sample data in tests

`seedSampleData()` uses `@Dependency(\.date.now)` internally, so all dates in sample data are relative to the pinned test date (`1_234_567_890` / 2009-02-13). This ensures deterministic query results — e.g., no issues fall within the "recent" window because the pinned date makes all sample dates older than 7 days.

### Pre-commit test coverage check

Before creating any commit, review the staged diff for new or changed reducer logic (new actions, state properties, effects, or modified behavior) and verify that corresponding tests exist. If feature code is staged without tests, flag the gap and propose what tests are needed — do not commit until coverage is addressed. Pure test-infrastructure changes (adding `Equatable`, `@CasePathable` for testability) and view-only changes (SwiftUI layout, styling) do not require new tests.

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
| `/pfw-snapshot-testing` | Inline snapshot testing of TCA feature state with `assertInlineSnapshot(of:as:.customDump)` |

### Also available

| Skill | Purpose |
|-------|---------|
| `/pfw-observable-models` | `@Observable` models outside of TCA. Also invoke `/pfw-dependencies` when using or adding dependencies to the model |
| `/pfw-macro-testing` | Testing Swift macros with MacroTesting |
| `/pfw-perception` | Back-porting Swift Observation to older platforms |
| `/pfw-spm` | Modifying Package.swift — adding targets, dependencies, etc. |

### Other skills

| Skill | Use when... |
|-------|-------------|
| `/swiftui-expert-skill` | Broad SwiftUI best practices — state management, performance, animations, Liquid Glass (iOS 26+), lists, navigation, modern API migrations. Complementary to `/pfw-modern-swiftui` (which focuses on action closures and custom bindings) |
