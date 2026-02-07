//
//  UltimatePortfolioTCAApp.swift
//  UltimatePortfolioTCA
//
//  Created by Michael Brünen on 06.02.26.
//

import ComposableArchitecture
import Dependencies
import SwiftUI

@main
struct UltimatePortfolioTCAApp: App {
    let store = Store(initialState: AppFeature.State()) {
        AppFeature()
    }

    init() {
        prepareDependencies {
            try! $0.bootstrapDatabase()
        }
    }

    var body: some Scene {
        WindowGroup {
            AppView(store: store)
        }
    }
}
