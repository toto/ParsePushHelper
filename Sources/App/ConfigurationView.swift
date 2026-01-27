//
//  ConfigurationView.swift
//  ParsePush
//
//  Created by Thomas Kollbach on 26.01.26.
//

import SwiftUI

struct ConfigurationView: View {
    @Bindable var store: ParseServerStore
    @State private var isPresentingConfigurationSheet = false
    @State private var configurationToEdit: ParseServerConfiguration?
    @State private var apiKeyToEdit = ""
    @State private var pendingDeleteIDs: [ParseServerConfiguration.ID] = []
    @State private var isPresentingDeleteConfirmation = false

    var body: some View {
        NavigationStack {
            List {
                if store.configurations.isEmpty {
                    ContentUnavailableView(
                        "No Parse Servers",
                        systemImage: "server.rack",
                        description: Text("Add a Parse Server configuration to get started.")
                    )
                } else {
                    ForEach(store.configurations) { configuration in
                        Button {
                            configurationToEdit = configuration
                            apiKeyToEdit = store.apiKey(for: configuration) ?? ""
                            isPresentingConfigurationSheet = true
                        } label: {
                            VStack(alignment: .leading, spacing: 4) {
                                Text(configuration.name)
                                    .font(.headline)
                                Text(configuration.serverURL.absoluteString)
                                    .font(.footnote)
                                    .foregroundStyle(.secondary)
                            }
                        }
                        .buttonStyle(.plain)
                    }
                    .onDelete(perform: requestDelete)
                    .onMove(perform: store.move(from:to:))
                }
            }
            .navigationTitle("Servers")
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button("Add", systemImage: "plus") {
                        configurationToEdit = nil
                        apiKeyToEdit = ""
                        isPresentingConfigurationSheet = true
                    }
                }
                ToolbarItem(placement: .navigationBarLeading) {
                    EditButton()
                }
            }
        }
        .confirmationDialog(
            deleteConfirmationTitle,
            isPresented: $isPresentingDeleteConfirmation
        ) {
            Button("Delete", role: .destructive) {
                store.delete(ids: pendingDeleteIDs)
                pendingDeleteIDs = []
            }
            Button("Cancel", role: .cancel) {
                pendingDeleteIDs = []
            }
        } message: {
            Text(deleteConfirmationMessage)
        }
        .sheet(isPresented: $isPresentingConfigurationSheet) {
            ParseServerConfigurationFormView(
                existingConfiguration: configurationToEdit,
                existingAPIKey: apiKeyToEdit,
                isCancellationAllowed: !store.configurations.isEmpty,
                onSave: { configuration, apiKey in
                    if configurationToEdit == nil {
                        store.add(configuration, apiKey: apiKey)
                    } else {
                        store.update(configuration, apiKey: apiKey)
                    }
                    configurationToEdit = nil
                    apiKeyToEdit = ""
                    isPresentingConfigurationSheet = false
                },
                onCancel: {
                    configurationToEdit = nil
                    apiKeyToEdit = ""
                    isPresentingConfigurationSheet = false
                }
            )
            .interactiveDismissDisabled(store.configurations.isEmpty)
        }
    }

    private var deleteConfirmationTitle: String {
        pendingDeleteIDs.count == 1 ? "Delete Parse Server?" : "Delete Parse Servers?"
    }

    private var deleteConfirmationMessage: String {
        if pendingDeleteIDs.count == 1, let configuration = store.configurations.first(where: { $0.id == pendingDeleteIDs[0] }) {
            return "This will remove “\(configuration.name)” from this device."
        }
        return "This will remove \(pendingDeleteIDs.count) servers from this device."
    }

    private func requestDelete(at offsets: IndexSet) {
        let ids: [UUID] = offsets.compactMap { index in
            guard store.configurations.indices.contains(index) else {
                return nil
            }
            return store.configurations[index].id
        }
        pendingDeleteIDs = ids
        isPresentingDeleteConfirmation = !ids.isEmpty
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
//    ConfigurationView(store: store)
//}
