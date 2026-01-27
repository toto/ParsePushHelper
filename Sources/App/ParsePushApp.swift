//
//  ParsePushApp.swift
//  ParsePush
//
//  Created by Thomas Kollbach on 26.01.26.
//

import SwiftUI

@main
struct ParsePushApp: App {
    @State private var templateStore = PushTemplateStore()

    var body: some Scene {
        WindowGroup {
            ContentView(store: ParseServerStore(keychain: KeychainStore()), templateStore: templateStore)
        }
    }
}
