---
paths: ["UltimatePortfolioTCA/Common/**"]
---

# Shared UI Components

## `SortMenu` + `SortOrderProtocol`

Generic toolbar sort menu. `SortOrderProtocol` pairs a `Field` enum with `isAscending`; `apply(_:)` toggles direction for the same field or replaces with a new field's default. Conforming types are in `Models/SortOrder/`.

## `FlowLayout`

Custom SwiftUI `Layout` that arranges children left-to-right, wrapping to the next line. Configurable `horizontalSpacing`/`verticalSpacing` (default 6). Used for tag chips.

## `ChipStyle` + `.chipStyle(isAssigned:)`

`ViewModifier` applying capsule-shaped chip styling. Assigned = white text on tint background; unassigned = secondary text on tertiary fill. Uses `.geometryGroup()` to keep text and background animations in sync.

## `PriorityIndicator`

10pt colored circle for `Issue.Priority` with an accessibility label. Color is defined on `Issue.Priority.color`. Owns its own `.accessibilityLabel` — call sites should not duplicate it.

## `Bundle.decode(_:as:)`

In `Extensions/Bundle+Decodable.swift`. Generic JSON decoder for bundled resources. Uses `fatalError` with detailed `DecodingError` messages. Used by `Award.allAwards`.

## `Date.compactRelative(to:)` / `Date.compactRelativeA11y(to:)`

In `Extensions/Date+CompactRelative.swift`. Compact relative date string for issue row trailing labels. The `A11y` variant returns a `LocalizedStringKey` with VoiceOver-friendly phrasing and pluralization support.
