//
//  ContentView.swift
//  ParsePush
//
//  Created by Thomas Kollbach on 26.01.26.
//

import SwiftUI

@MainActor
struct ContentView: View {
    @State private var store: ParseServerStore
    @State private var isPresentingConfigurationSheet = false
    @State private var configurationToEdit: ParseServerConfiguration?
    @State private var pendingDeleteIDs: [ParseServerConfiguration.ID] = []
    @State private var isPresentingDeleteConfirmation = false

    @MainActor
    init() {
        store = ParseServerStore()
    }

    @MainActor
    init(store: ParseServerStore) {
        self.store = store
    }

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
                    Section("Servers") {
                        ForEach(store.configurations) { configuration in
                            Button {
                                configurationToEdit = configuration
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
            }
            .navigationTitle("Parse Servers")
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button("Add", systemImage: "plus") {
                        configurationToEdit = nil
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
                isCancellationAllowed: !store.configurations.isEmpty,
                onSave: { configuration in
                    if configurationToEdit == nil {
                        store.add(configuration)
                    } else {
                        store.update(configuration)
                    }
                    configurationToEdit = nil
                    isPresentingConfigurationSheet = false
                },
                onCancel: {
                    configurationToEdit = nil
                    isPresentingConfigurationSheet = false
                }
            )
            .interactiveDismissDisabled(store.configurations.isEmpty)
        }
        .task {
            if store.configurations.isEmpty {
                isPresentingConfigurationSheet = true
            }
        }
        .onChange(of: store.configurations) { _, newValue in
            if newValue.isEmpty {
                isPresentingConfigurationSheet = true
            }
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

#Preview {
    let previewDefaults = UserDefaults(suiteName: "ParsePushPreview")
    previewDefaults?.removePersistentDomain(forName: "ParsePushPreview")
    let store = ParseServerStore(userDefaults: previewDefaults ?? .standard)
    if let url = URL(string: "https://api.example.com/parse") {
        store.add(ParseServerConfiguration(name: "Production", serverURL: url))
    }
    return ContentView(store: store)
}
