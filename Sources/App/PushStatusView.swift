//
//  PushStatusView.swift
//  ParsePush
//
//  Created by Thomas Kollbach on 06.02.26.
//

import Observation
import SwiftUI

@Observable
final class PushStatusViewModel {
    private let repository: PushStatusRepository

    var entries: [PushStatusEntry] = []
    var isLoading = false
    var errorMessage: String?
    var lastUpdated: Date?

    init(repository: PushStatusRepository = PushStatusRepository()) {
        self.repository = repository
    }

    @MainActor
    func load(configuration: ParseServerConfiguration, apiKey: String?) async {
        isLoading = true
        errorMessage = nil

        do {
            entries = try await repository.fetchStatuses(configuration: configuration, apiKey: apiKey)
            lastUpdated = Date()
        } catch {
            entries = []
            errorMessage = error.localizedDescription
        }

        isLoading = false
    }

    @MainActor
    func reset() {
        entries = []
        isLoading = false
        errorMessage = nil
        lastUpdated = nil
    }
}

@MainActor
struct PushStatusView: View {
    @Bindable var store: ParseServerStore
    @State private var viewModel = PushStatusViewModel()
    @State private var selectedConfigurationID: ParseServerConfiguration.ID?

    var body: some View {
        NavigationStack {
            Group {
                if store.configurations.isEmpty {
                    ContentUnavailableView(
                        "No Parse Servers",
                        systemImage: "server.rack",
                        description: Text("Add a Parse Server first on the Servers tab.")
                    )
                } else {
                    List {
                        Section("Server") {
                            Picker("Server", selection: $selectedConfigurationID) {
                                ForEach(store.configurations) { configuration in
                                    Text(configuration.name)
                                        .tag(Optional(configuration.id))
                                }
                            }
                        }

                        if viewModel.isLoading {
                            Section {
                                HStack {
                                    Spacer()
                                    ProgressView("Loading…")
                                    Spacer()
                                }
                            }
                        }

                        if let errorMessage = viewModel.errorMessage {
                            Section {
                                ContentUnavailableView(
                                    "Couldn’t Load Status",
                                    systemImage: "exclamationmark.triangle",
                                    description: Text(errorMessage)
                                )
                            }
                        }

                        if !viewModel.isLoading && viewModel.errorMessage == nil && viewModel.entries.isEmpty {
                            Section {
                                ContentUnavailableView(
                                    "No Push Statuses",
                                    systemImage: "bell",
                                    description: Text("No entries were returned from this server.")
                                )
                            }
                        }

                        ForEach(viewModel.entries) { entry in
                            NavigationLink {
                                PushStatusDetailView(entry: entry)
                            } label: {
                                PushStatusRow(entry: entry)
                            }
                        }
                    }
                }
            }
            .navigationTitle("Push Status")
            .toolbar {
                if selectedConfiguration != nil {
                    ToolbarItem(placement: .primaryAction) {
                        Button("Refresh", systemImage: "arrow.clockwise") {
                            refreshStatuses()
                        }
                    }
                }
            }
        }
        .onAppear {
            updateSelectionIfNeeded()
            if viewModel.entries.isEmpty {
                refreshStatuses()
            }
        }
        .onChange(of: store.configurations) { _, _ in
            updateSelectionIfNeeded()
            refreshStatuses()
        }
        .onChange(of: selectedConfigurationID) { _, _ in
            refreshStatuses()
        }
    }

    private var selectedConfiguration: ParseServerConfiguration? {
        if let selectedConfigurationID {
            return store.configurations.first { $0.id == selectedConfigurationID }
        }
        return store.configurations.first
    }

    private func updateSelectionIfNeeded() {
        guard !store.configurations.isEmpty else {
            selectedConfigurationID = nil
            viewModel.reset()
            return
        }

        if let selectedConfigurationID,
           store.configurations.contains(where: { $0.id == selectedConfigurationID }) {
            return
        }

        selectedConfigurationID = store.configurations.first?.id
    }

    private func refreshStatuses() {
        guard let configuration = selectedConfiguration else { return }
        let apiKey = store.apiKey(for: configuration)

        Task {
            await viewModel.load(configuration: configuration, apiKey: apiKey)
        }
    }
}

private struct PushStatusRow: View {
    let entry: PushStatusEntry

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text(entry.status ?? "Status")
                    .font(.headline)
                Spacer()
                Text(entry.id)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            if let createdAt = entry.createdAt {
                Text("Created: \(createdAt)")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }

            if let updatedAt = entry.updatedAt {
                Text("Updated: \(updatedAt)")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }
        }
    }
}

private struct PushStatusDetailView: View {
    let entry: PushStatusEntry

    var body: some View {
        ScrollView {
            Text(entry.rawJSON)
                .font(.system(.body, design: .monospaced))
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding()
        }
        .navigationTitle("Details")
        .navigationBarTitleDisplayMode(.inline)
    }
}

#Preview {
    @MainActor in
    let previewDefaults = UserDefaults(suiteName: "ParsePushPreview")
    previewDefaults?.removePersistentDomain(forName: "ParsePushPreview")
    let store = ParseServerStore(userDefaults: previewDefaults ?? .standard, keychain: KeychainStore())
    if let url = URL(string: "https://api.example.com/parse") {
        store.add(
            ParseServerConfiguration(name: "Production", serverURL: url, appID: "APP123"),
            apiKey: "preview-api-key"
        )
    }
    return PushStatusView(store: store)
}
