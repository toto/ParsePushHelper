//
//  ContentView.swift
//  ParsePush
//
//  Created by Thomas Kollbach on 26.01.26.
//

import SwiftUI

struct ContentView: View {
    @State private var store: ParseServerStore
    let templateStore: PushTemplateStore
    @State private var isPresentingInitialConfiguration = false
    @State private var initialAPIKey = ""

    init(store: ParseServerStore, templateStore: PushTemplateStore) {
        _store = State(initialValue: store)
        self.templateStore = templateStore
    }

    var body: some View {
        TabView {
            PushView(templateStore: templateStore)
                .tabItem {
                    Label("Templates", systemImage: "doc.on.doc")
                }

            ConfigurationView(store: store)
                .tabItem {
                    Label("Configuration", systemImage: "gearshape")
                }
        }
        .sheet(isPresented: $isPresentingInitialConfiguration) {
            ParseServerConfigurationFormView(
                existingConfiguration: nil,
                existingAPIKey: initialAPIKey,
                isCancellationAllowed: false,
                onSave: { configuration, apiKey in
                    store.add(configuration, apiKey: apiKey)
                    initialAPIKey = ""
                    isPresentingInitialConfiguration = false
                },
                onCancel: {
                    initialAPIKey = ""
                    isPresentingInitialConfiguration = false
                }
            )
            .interactiveDismissDisabled(true)
        }
        .task {
            if store.configurations.isEmpty {
                isPresentingInitialConfiguration = true
            }
        }
        .onChange(of: store.configurations) { _, newValue in
            if newValue.isEmpty {
                isPresentingInitialConfiguration = true
            }
        }
    }
}

//#Preview {
//    let previewDefaults = UserDefaults(suiteName: "ParsePushPreview")
//    previewDefaults?.removePersistentDomain(forName: "ParsePushPreview")
//    let store = ParseServerStore(userDefaults: previewDefaults ?? .standard, keychain: KeychainStore())
//    if let url = URL(string: "https://api.example.com/parse") {
//        store.add(
//            ParseServerConfiguration(name: "Production", serverURL: url, appID: "APP123"),
//            apiKey: "preview-api-key"
//        )
//    }
//    ContentView(store: store)
//}
