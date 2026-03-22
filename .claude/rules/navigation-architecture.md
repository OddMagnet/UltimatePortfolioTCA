---
paths: ["UltimatePortfolioTCA/Features/**"]
---

# Navigation Architecture

Three-column `NavigationSplitView` — Sidebar (always present), Content (optional, shown when a filter is selected), Detail (optional, shown when an issue is selected; otherwise AppView shows a "No Issue Selected" empty state).

## Composition

- `AppFeature` composes children via `Scope` (sidebar) and `.ifLet` (content, detail).
- Child reducers intercept their own binding changes via `BindingReducer().onChange(of:)` and forward them as delegate actions with associated values (e.g., `selectedFilterChanged(IssueFilter?)`).
- The parent only handles delegate actions to drive navigation.

## State Replacement Pattern

When the selected filter or issue changes, the parent replaces the entire child state rather than mutating individual properties:
```swift
state.content = ContentFeature.State(filter: newFilter)
```
This ensures all state resets atomically — including `@FetchAll`/`@FetchOne` observations — and means new properties added to a child are automatically handled without updating a separate mutation method.

## Issue Creation Flow

New issues can be created from multiple entry points, all handled by a single `AppFeature` case that generates the UUID, ensures content exists (defaulting to the `.open` filter), and replaces the detail state with `DetailFeature.State(issueID:isEditing: true)`. On save, the parent replaces the detail state again to show the saved issue.

## ViewAction Protocol

All features use the `ViewAction` protocol to separate view actions (`enum View`) from internal actions (`delegate`, `binding`). Views use `@ViewAction(for:)` to send view actions via `send()` instead of `store.send()`.

## Detail View

- Uses `VStack` container (not `Group`) with `.animation(.default, value: store.isEditing)` for edit/view transitions.
- Since `issueID` is `let` and the parent replaces entire detail state on issue changes, no `issueID`-based animation is needed.

## Alerts

- `DetailFeature`: TCA's `AlertState` via `@Presents var alert` for delete confirmation.
- `AppFeature`: `@CasePathable` `Destination` enum (see `AppFeature.Destination` for current cases) driven by native SwiftUI `.alert(item:)` and `.sheet(isPresented:)` — avoids TCA's `AlertState` (which doesn't support text fields).
- `AwardsView` is a plain SwiftUI view (no reducer) presented as a sheet.

## Completed-Issue Visibility

`IssueFilter` centralizes rules via `hasShowCompletedToggle` and `showsCompletedIssues(with:)`. When `DetailFeature` toggles completion (via `.delegate(.issueCompletedToggled)`), `AppFeature` clears the detail and content selection if the issue would disappear from the current list.

## Search

`ContentFeature` provides FTS5 full-text search combined with token-based filtering (tag, priority, status). Search query is debounced (0.3s) via `issueQueryChanged(debounce:)` with `cancelInFlight`. Tokens combine with AND logic.

## No-op Save Prevention

`DetailFeature` compares the edit draft against the current issue before writing. If nothing changed, no database write occurs. New issues (where `state.issue` is `nil`) always save.
