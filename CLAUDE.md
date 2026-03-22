# CLAUDE.md

This file provides guidance to Claude Code when working with code in this repository.

## Project Overview

Multiplatform SwiftUI app (iOS, macOS, visionOS) built with The Composable Architecture (TCA) and SQLiteData for persistence, with iCloud sync via SyncEngine. Xcode project at `UltimatePortfolioTCA.xcodeproj`.

## Build & Test Commands

- **ALWAYS** use the Xcode MCP server for build and test commands
- **NEVER** use `xcodebuild` 

If the Xcode MCP server is not connected ask the developer to connect it again for you.

## Coding Standards

### Architecture

- Views take `StoreOf<Feature>` directly. Do NOT use legacy `ViewStore`/`WithViewStore`.
- Content selection uses `selectedIssueID: Issue.ID?` (not `Issue?`) — `@FetchAll` reloads produce new values that break `List(selection:)` matching.
- Parent replaces entire child state on navigation changes (e.g., `state.content = ContentFeature.State(filter:)`). Do not mutate individual child properties.
- Child columns use delegate actions (not `@Dependency(\.dismiss)`) for parent communication. Reserve `dismiss` for modally-presented features (sheets, popovers).
- `@FetchAll`/`@FetchOne` live in reducer `@ObservableState` for dynamic queries. Plain SwiftUI views without a reducer can use them directly.
- `@FetchAll` property wrapper storage (`_propertyName`) is private — use a `mutating func` on `State` to reassign from the reducer.
- `BindingReducer` only fires for bindings written by the feature's own view. `@Shared` changes from other features bypass it — use `.onChange(of:)` in the view to detect external mutations.

### Naming Conventions

| Item | Convention | Example |
|------|-----------|---------|
| Reducer | `XFeature` | `DetailFeature` |
| View | `XView` | `DetailView` |
| Form section views | `DetailX` | `DetailTitle`, `DetailTags` |
| Sort order | `XSortOrder` | `IssueSortOrder` |
| Test suite | `XTests` (nested in `BaseTestSuite`) | `DetailFeatureTests` |
| Boolean model properties | `is`-prefix | `isCompleted`, not `completed` |
| Switch cases | `case let .foo(bar)` | Not `case .foo(let bar)` |

### Action Naming

- View actions (in `Action.View`): past-tense verbs — `createIssueButtonTapped`, `deleteTagsSwiped`, `sortOrderSelected`
- Delegate actions: `delegate(Delegate)` wrapper with associated values — `delegate(.selectedIssueChanged(Issue.ID?))`
### Database

- Use `prepareDependencies` (not `withDependencies`) for dependency setup — except in `#Preview` macros (see workaround below). `prepareDependencies` must complete before `Store` initialization since `AppFeature.State()` constructs child states with `@FetchAll` queries that require the database.
- `modified` column: managed by temporary trigger. Do NOT set from Swift code — the property is `let`.
- Previews: use `withPreviewDependencies(view:)` helper. WORKAROUND for `prepareDependencies` bug with `@FetchAll` since swift-dependencies 1.10.1. REMOVAL: test with `prepareDependencies` after each swift-dependencies update; revert when fixed.
- Query pipeline ordering: `Where` -> `Group` -> `Order` -> `Join` -> `Select`.
- Sample data and test helpers must use `@Dependency(\.date.now)` for dates (not `Date()`), so they are deterministic when the date dependency is pinned in tests.
- FTS triggers must NOT guard against `SyncEngine.$isSynchronizing` (unlike the `modified` trigger) — FTS must always stay in sync.

### Swift Settings

- Swift 6, strict concurrency, `nonisolated` default — mark `@MainActor` explicitly when needed.
- Import minimization: only import modules you directly use. `ComposableArchitecture` re-exports `Dependencies`, `Sharing`, `CasePaths`, `IssueReporting`. `SQLiteData` re-exports `StructuredQueries`, `Dependencies`. `MEMBER_IMPORT_VISIBILITY` enforces at compile time.
- Deployment targets: iOS 26.2, macOS 26.2, visionOS 26.2.

### Localization & Accessibility

- Dual-property pattern: `label: String` for programmatic use/testing, `a11yLabel: LocalizedStringKey` for VoiceOver. Tests assert against the `String` `label` property.
- Reusable components own their own `.accessibilityLabel`. Call sites use `.accessibilitySortPriority` for reading order, not duplicate labels.

### Error Handling

- Effects: wrap database operations in `await withErrorReporting { ... }` (from IssueReporting, re-exported by TCA). Do not add manual `do/catch` blocks.
- App bootstrap: `try!` for `bootstrapDatabase()` — database setup failure is unrecoverable.
- Bundle decoding: `fatalError` with detailed `DecodingError` messages — intentional crash-on-bad-data for development.

### File Placement

File System Synchronized Groups — new files placed in the source directory are automatically included in the build.

- Features: `Features/{Name}/{Name}Feature.swift` + `{Name}View.swift`
- Form sections: `Features/Detail/FormSections/Detail{Section}.swift`
- Models: `Models/{Name}.swift` — one `@Table` struct per file, extensions in same file
- Sort orders: `Models/SortOrder/{Type}SortOrder.swift`
- Shared components: `Common/` — extensions in `Common/Extensions/`
- Tests: `UltimatePortfolioTCATests/{Feature}Tests.swift`

## Restrictions

**NEVER:**
- Set `modified` from Swift code — managed by database trigger
- Hand-write or edit inline snapshot strings — run tests in record mode to generate/update
- Conform `Action` enums to `Equatable`
- Use legacy `ViewStore`/`WithViewStore`
- Link transitive dependencies to the test target (causes duplicate class warnings)
- Add `Co-Authored-By` trailers to commit messages

**ALWAYS:**
- Present a plan before architectural changes, schema changes, or multi-reducer features
- Invoke the relevant PFW skill before writing code that uses Point-Free libraries
- Wrap database operations in `withErrorReporting { ... }`
- Wait for approval before adding new library dependencies
- Check staged diff for test coverage before committing (new reducer logic needs tests; view-only changes do not)

## Skills

- ALWAYS invoke `/pfw-pfw` alongside any other PFW skill
- ALWAYS invoke `/swiftui-expert-skill` and `/pfw-modern-swiftui` when writing SwiftUI views
- When using `/pfw-composable-architecture`, also invoke `/pfw-dependencies` for dependency work and `/pfw-sharing` for `@Shared` state
- Individual PFW skills contain their own cross-references to related skills (e.g., `pfw-sqlite-data` references `pfw-structured-queries`, `pfw-dependencies`, `pfw-issue-reporting`)
- When proposing a new library dependency from a skill, wait for approval before adding it

## Testing

Swift Testing framework. Test files in `UltimatePortfolioTCATests/`.

- Base suite: see `UltimatePortfolioTCATests.swift` for `BaseTestSuite` with pinned dependencies and seeded database. `.serialized` is a workaround — remove when TCA 2.0 addresses in-flight effect interference.
- Nest new test suites via `extension BaseTestSuite { @MainActor struct FeatureTests { ... } }`. `@MainActor` must be applied to each nested suite individually — not inherited.
- Use `TestStoreOf<Feature>`. Features under test require `Equatable` on `State`.
- Use case key path syntax: `store.send(\.view.createTagButtonTapped)`, `store.receive(\.delegate.createTag, UUID(0))`. Add `@CasePathable` to nested `Action` enums (`View`, `Delegate`).
- Use `assertInlineSnapshot(of:as:.customDump)` for state snapshots.
- Use `UUID(-1)` for non-existent entity IDs in tests (avoids collisions with `.incrementing` generator and sample data).
- Test target links only: `DependenciesTestSupport`, `InlineSnapshotTesting`, `SnapshotTesting`, `SnapshotTestingCustomDump`. Everything else comes through `@testable import UltimatePortfolioTCA`.

## Commits & Code Quality

- Commit message format: short title summarizing the change, blank line, body explaining approach and key decisions. Match existing commit style.
- SwiftFormat pre-commit hook auto-formats staged files. Manual: `swiftformat UltimatePortfolioTCA/ UltimatePortfolioTCATests/`
- Rule philosophy: SwiftFormat owns formatting/style. SwiftLint owns safety/correctness/complexity.

## Debugging

- **Evidence over theory**: When debug output, logs, or test results are provided, treat them as primary evidence. If evidence contradicts your hypothesis, discard the hypothesis — do not rationalize.

## Workflows

### New Feature

1. Create `{Name}Feature.swift` (reducer) and `{Name}View.swift` in `Features/{Name}/`.
2. Add `@ObservableState struct State`, `enum Action` with `View` and `Delegate` sub-enums, `ViewAction` protocol on the view.
3. Wire into parent reducer via `Scope` or `.ifLet`.
4. Add `#Preview` blocks using `withPreviewDependencies(view:)` with multiple states.
5. Add tests nested in `BaseTestSuite` with `TestStore`.
6. Verify build and all tests pass.

### Database Schema Change

1. Add migration in `Schema.swift` via `migrator.registerMigration`.
2. Update or create `@Table` model in `Models/`.
3. Add temporary triggers if needed (via `createTemporaryTrigger`, registered in `bootstrapDatabase()`).
4. Update `seedSampleData()` if the change affects sample data.
5. Extract query helpers into model extensions if reusable.
6. Add tests covering the new schema behavior.

### Pre-Commit Review

1. Build succeeds.
2. All tests pass.
3. New reducer logic has corresponding test coverage.
4. New views have `#Preview` blocks.
5. `swiftformat` has been run (or will be caught by pre-commit hook).
6. Relevant PFW skills were consulted for any library API usage.
7. Check if CLAUDE.md needs updating — propose changes, never update without approval.

### Expanding CLAUDE.md

1. Identify which section the addition belongs to.
2. Apply the mistake test: "Would Claude make a specific mistake without this?" If not, consider `.claude/rules/` instead.
3. State rules, not rationale. Use code comments for "why" explanations.
4. Use discovery rules over enumerations (e.g., "search for X" instead of listing all instances).
5. See `CLAUDE-MD-GUIDE.md` for the full set of principles and evaluation criteria.
6. Never update without explicit developer approval.
