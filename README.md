# UltimatePortfolioTCA

A multiplatform issue tracker, rebuilt from scratch with The Composable Architecture and SQLiteData.

![Swift](https://img.shields.io/badge/Swift-6.0-orange)
![Platforms](https://img.shields.io/badge/platforms-iOS%20%7C%20macOS%20%7C%20visionOS-blue)
![Architecture](https://img.shields.io/badge/architecture-TCA-green)
![Status](https://img.shields.io/badge/status-work%20in%20progress-yellow)

## Screenshots

| iPhone | iPad | macOS |
|---|---|---|
| ![Issue list on iPhone](docs/screenshots/iphone-content.png) | ![Split view on iPad](docs/screenshots/ipad-split.png) | ![Detail view on macOS](docs/screenshots/macos-detail.png) |

> Screenshots pending.

## About

UltimatePortfolioTCA is an issue tracker: create issues, tag them, filter and
search them, and keep everything in sync across devices. One SwiftUI codebase
runs on iOS, macOS and visionOS.

The project follows Paul Hudson's Ultimate Portfolio App series, but none of the
course code is used. Every feature is rebuilt with a stack I wanted to work with:
The Composable Architecture for state and side effects, SQLiteData for
persistence and iCloud sync. Working from a known target made it easy to see what
those libraries change about how an app is structured and tested.

## Features

- **Issues and tags**: create, edit and complete issues, organise them with tags
- **Smart filters**: open, completed and recently modified issues, plus one filter per tag
- **Full text search**: search across titles and descriptions, narrowed further
  by tokens for tag, priority and status
- **Sorting**: sort issues and tags by several criteria, the choice is remembered
- **Awards**: unlockable milestones based on how the app is used
- **iCloud sync**: changes propagate across devices through CloudKit
- **Localisation**: English and German
- **Accessibility**: VoiceOver labels and a deliberate reading order throughout

## Architecture

Application logic is built with The Composable Architecture: each feature owns
its state and its actions, and what is on screen follows from that state rather
than from imperative navigation calls. The interface is a three column split
view, filters on the left, the matching issues in the middle, the selected issue
on the right, and every column is a feature of its own. A root feature
coordinates them: the columns report upwards through delegate actions, and the
root decides what a change means for the other two, for example which list a new
issue belongs in and whether the detail view still has something to show.

Data lives in SQLite, accessed through SQLiteData on top of GRDB. The schema is
created and evolved through migrations, and queries are observed straight from
feature state, so a write in one place updates every view that depends on it.
Search runs against an FTS5 table that database triggers keep in sync. iCloud
sync is handled by SQLiteData's sync engine on top of CloudKit.

Everything is Swift 6 with strict concurrency. Dependencies such as the database,
the clock and UUID generation are injected rather than reached for globally,
which is what makes the tests below possible.

| Library | Role |
|---|---|
| The Composable Architecture | Feature state, actions and side effects |
| SQLiteData | Persistence, live queries and iCloud sync |
| GRDB | The SQLite layer underneath SQLiteData |
| swift-dependencies | Injection of database, clock and UUID generation |
| Swift Testing, swift-snapshot-testing | Test suite and inline state snapshots |

## Testing

Features are tested with TCA's test store, which asserts on every state change
and every effect a feature produces. A test fails when something unexpected
happens, not only when an expectation goes unmet. Models and helpers are covered
by plain unit tests on top of that.

Anything a feature would otherwise reach for globally is a dependency instead:
the database, the current date, UUID generation, the clock. Tests take control of
them, so every test runs against its own in-memory database, built by the same
bootstrap and migration code the app uses, with time and identifiers fixed.
Results are deterministic and no test can be influenced by another. Written with
Swift Testing, using inline snapshots for the larger state assertions.

## Tooling

SwiftFormat and SwiftLint have separate jobs: SwiftFormat owns formatting and
style, SwiftLint owns safety, correctness and complexity. Every rule in both
configurations is listed explicitly with the reason it is enabled or disabled, so
the two tools never disagree about the same line. A pre-commit hook formats
staged files before they land, and a Brewfile installs what is needed.

Project conventions are written down in `CLAUDE.md` and `.claude/rules/`, which
double as the rule set for AI assisted work. The code is mine: the assistant is a
second opinion and a sounding board inside those rules, and what ends up in a
commit is my call.

## Building

Requires Xcode 26 or newer. The project targets iOS 26.2, macOS 26.2 and
visionOS 26.2 and builds in Swift 6 language mode. Swift package dependencies
resolve on first open.

```sh
git clone https://github.com/OddMagnet/UltimatePortfolioTCA.git
cd UltimatePortfolioTCA
brew bundle             # SwiftFormat and SwiftLint
scripts/install-hooks.sh
```

Then open `UltimatePortfolioTCA.xcodeproj`, pick a scheme and run.

The CloudKit container comes from the app's entitlements rather than from code.
To run with sync under your own account, select your team and add your own
container in the target's Signing & Capabilities tab. Previews and the test suite
use a mock CloudKit container and need no setup at all.

## Status

Work in progress. Features arrive as I work through the series, and the
architecture still shifts when a better shape turns up.

The app follows [Ultimate Portfolio App](https://www.hackingwithswift.com/plus/ultimate-portfolio-app)
by Paul Hudson at Hacking with Swift. The course is worth its price if you want
the original, built with Core Data and plain SwiftUI.
