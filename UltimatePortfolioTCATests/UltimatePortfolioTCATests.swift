import DependenciesTestSupport
import Foundation
import SQLiteData
import Testing
@testable import UltimatePortfolioTCA

@Suite(
    .dependency(\.date.now, Date(timeIntervalSince1970: 1_234_567_890)),
    .dependency(\.uuid, .incrementing),
    .dependencies {
        try $0.bootstrapDatabase()
        try $0.defaultDatabase.seedSampleData()
    }
)
struct BaseTestSuite {}
