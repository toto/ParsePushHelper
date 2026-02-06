//
//  ContentView.swift
//  ParsePush
//
//  Created by Thomas Kollbach on 26.01.26.
//

import SwiftUI

struct ContentView: View {
    private enum Tab: Int {
        case status
        case templates
        case servers
    }

    @State private var store: ParseServerStore
    let templateStore: PushTemplateStore
    @AppStorage("selectedTab") private var selectedTab = Tab.status.rawValue
    @State private var isPresentingInitialConfiguration = false
    @State private var initialAPIKey = ""

    init(store: ParseServerStore, templateStore: PushTemplateStore) {
        _store = State(initialValue: store)
        self.templateStore = templateStore
    }

    var body: some View {
        TabView(selection: $selectedTab) {

            PushStatusView(store: store)
                .tabItem {
                    Label("Status", systemImage: "bell.badge")
                }
                .tag(Tab.status.rawValue)

            PushView(templateStore: templateStore)
                .tabItem {
                    Label("Templates", systemImage: "doc.on.doc")
                }
                .tag(Tab.templates.rawValue)

            ConfigurationView(store: store)
                .tabItem {
                    Label("Servers", systemImage: "server.rack")
                }
                .tag(Tab.servers.rawValue)

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
