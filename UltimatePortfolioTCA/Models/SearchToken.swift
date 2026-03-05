import Foundation
import SwiftUI

enum SearchToken: Hashable, Identifiable {
    case tag(Tag)
    case priority(Issue.Priority)
    case status(Status)

    enum Status: String, CaseIterable, Identifiable, Hashable {
        case open
        case completed

        var id: Self { self }

        var label: String {
            switch self {
            case .open: "Open"
            case .completed: "Completed"
            }
        }
    }

    var id: String {
        switch self {
        case let .tag(tag): "tag-\(tag.id)"
        case let .priority(priority): "priority-\(priority.rawValue)"
        case let .status(status): "status-\(status.rawValue)"
        }
    }

    var label: String {
        switch self {
        case let .tag(tag): tag.name
        case let .priority(priority): priority.label
        case let .status(status): status.label
        }
    }

    var systemImage: String {
        switch self {
        case .tag: "tag"
        case .priority: "flag"
        case let .status(status):
            switch status {
            case .open: "circle"
            case .completed: "checkmark.circle"
            }
        }
    }

    var tintColor: Color? {
        switch self {
        case .tag: nil
        case let .priority(priority): priority.color
        case .status(.open): .secondary
        case .status(.completed): .green
        }
    }

    var tag: Tag? {
        switch self {
        case let .tag(value): value
        default: nil
        }
    }

    var priority: Issue.Priority? {
        switch self {
        case let .priority(value): value
        default: nil
        }
    }

    var status: Status? {
        switch self {
        case let .status(value): value
        default: nil
        }
    }
}
