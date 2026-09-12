//
//  ThriftQuestApp.swift
//  ThriftQuest
//
//  Created by Shizawa Ira on 2026/09/06.
//

import SwiftUI

@main
struct ThriftQuestApp: App {
    @StateObject private var store = GameStore()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(store)
        }
    }
}
