---
paths: ["UltimatePortfolioTCA/Dependencies/**", "UltimatePortfolioTCA/Models/**"]
---

# Database Internals

## Schema & Setup

- `Schema.swift` in `Dependencies/` — `bootstrapDatabase()` on `DependencyValues` configures the database, runs migrations, starts `SyncEngine`, registers temporary triggers, and seeds sample data (debug only).
- `SampleData.swift` — `seedSampleData()` on `DatabaseWriter` provides seed issues, tags, and associations. `UUID+SampleData.swift` defines static UUID constants for all sample entities.
- `configuration.foreignKeysEnabled = true` — enforced at runtime.
- `datetime('subsec')` for sub-second precision.
- Debug only: `eraseDatabaseOnSchemaChange = true`, SQL query tracing via `os.Logger`.
- `SQLiteData.defaultDatabase()` automatically uses in-memory for previews, temporary file for tests, app container for live.

## Models

- All models use `@Table` with UUID primary keys — see `Models/` for the current list. `IssueTag` is the join table.
- `Tag.Draft` conforms to `Equatable` (required for SwiftUI's `.alert(item:)`).
- `IssueText` is an FTS5 virtual table (`@Table` with `FTS5` conformance) for full-text search.
- `SearchToken` is a plain enum (tag/priority/status) for token-based filtering.
- `Award` is `Decodable + Identifiable`, loaded from localized `Awards.json` via `Bundle.decode` — not a database table.
- Tag names use `COLLATE NOCASE`.

## iCloud Sync

- `SyncEngine` initialized for the persistent tables (`Issue`, `Tag`, `IssueTag`) — not the FTS5 virtual table (`IssueText`). Entitlements and `CKSharingSupported` are configured.
- The `modified` trigger uses `!SyncEngine.$isSynchronizing` to skip SyncEngine's no-op updates.
- FTS triggers do NOT guard against `SyncEngine.$isSynchronizing` — FTS must always stay in sync.

## FTS5 Full-Text Search

The `issueTexts` virtual table uses `content="issues"` (external content table) with `content_rowid="rowid"`. Raw SQL temporary triggers keep the FTS index in sync with the `issues` table (insert, update of title/detail, delete). `IssueText.sanitize(query:)` strips FTS5 operators, wraps terms in double-quotes, and appends `*` for prefix matching.

## Query Patterns

- `Issue.TableColumns` has reusable computed properties available as `$0.property` inside StructuredQueries closures — search for `extension Issue.TableColumns` in `Issue.swift` for the current list. Note: custom `TableColumns` computed properties cannot use static shorthand (`Issue.lastActivity`) — only real `@Table` columns support `@dynamicMemberLookup` on the static subscript.
- Common filter/ordering logic is extracted into model file extensions. Search for `Issue.filter(with:)` and `extension Select where From ==` for examples.
- `leftJoin` produces optional `Joins` types (e.g., `(IssueTag?, Issue?)` not `(IssueTag, Issue)`).

## User Preferences

`@Shared(.appStorage(AppStorageKeys.key))` from the Sharing library persists user preferences. Keys are centralized in `AppStorageKeys` enum (`Dependencies/AppStorageKeys.swift`).

## App Entry Point

`prepareDependencies` must complete before `Store` initialization, since `AppFeature.State()` constructs child states with `@FetchAll` queries that require the database. The app body guards with `if !isTesting` to skip UI during test runs.
