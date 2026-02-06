//
//  UltimatePortfolioTCAApp.swift
//  UltimatePortfolioTCA
//
//  Created by Michael Brünen on 06.02.26.
//

import Dependencies
import SwiftUI

@main
struct UltimatePortfolioTCAApp: App {
    init() {
        prepareDependencies {
            try! $0.bootstrapDatabase()
        }
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}
