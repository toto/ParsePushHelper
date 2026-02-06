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
                ToolbarItem(placement: .principal) {
                    TitlePickerView(
                        configurations: store.configurations,
                        selectedConfigurationID: $selectedConfigurationID
                    )
                }

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

private struct TitlePickerView: View {
    let configurations: [ParseServerConfiguration]
    @Binding var selectedConfigurationID: ParseServerConfiguration.ID?

    var body: some View {
        VStack(spacing: 2) {
            if configurations.count > 1 {
                Picker("Server", selection: $selectedConfigurationID) {
                    ForEach(configurations) { configuration in
                        Text(configuration.name)
                            .tag(Optional(configuration.id))
                    }
                }
                .labelsHidden()
                .pickerStyle(.menu)
            } else if let configuration = configurations.first {
                Text(configuration.name)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
        }
    }
}

private struct PushStatusRow: View {
    let entry: PushStatusEntry

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                StatusLabel(status: entry.status)
                Spacer()
                Text(entry.id)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            if let createdAt = formattedDate(entry.createdAt) {
                Text("Created: \(createdAt)")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }

            if let updatedAt = formattedDate(entry.updatedAt) {
                Text("Updated: \(updatedAt)")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }

            if let numSent = entry.numSent {
                Text("Sent pushes: \(numSent)")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }

            if !entry.payloadItems.isEmpty {
                VStack(alignment: .leading, spacing: 2) {
                    ForEach(entry.payloadItems.prefix(3)) { item in
                        Text("\(item.id): \(item.value)")
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                            .lineLimit(1)
                            .truncationMode(.tail)
                    }

                    if entry.payloadItems.count > 3 {
                        Text("+\(entry.payloadItems.count - 3) more")
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                    }
                }
            }
        }
    }

    private func formattedDate(_ isoString: String?) -> String? {
        guard let isoString else {
            return nil
        }
        if let date = Self.isoFormatter.date(from: isoString) ?? Self.isoFallbackFormatter.date(from: isoString) {
            return Self.displayFormatter.string(from: date)
        }
        return nil
    }

    private static let isoFormatter: ISO8601DateFormatter = {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        return formatter
    }()

    private static let isoFallbackFormatter: ISO8601DateFormatter = {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime]
        return formatter
    }()

    private static let displayFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.locale = .autoupdatingCurrent
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter
    }()
}

private struct StatusLabel: View {
    let status: String?

    var body: some View {
        let display = StatusDisplay(status: status)
        Label(display.title, systemImage: display.systemImage)
            .font(.headline)
            .foregroundStyle(display.color)
    }
}

private struct StatusDisplay {
    let title: String
    let systemImage: String
    let color: Color

    init(status: String?) {
        switch status?.trimmingCharacters(in: .whitespacesAndNewlines).lowercased() {
        case "succeeded", "sent":
            title = "Sent"
            systemImage = "checkmark.circle.fill"
            color = .green
        case "sending":
            title = "Sending"
            systemImage = "paperplane.fill"
            color = .green
        case "failed", "error":
            title = "Failed"
            systemImage = "xmark.octagon.fill"
            color = .red
        default:
            title = status?.isEmpty == false ? (status ?? "Status") : "Status"
            systemImage = "bell"
            color = .secondary
        }
    }
}

private struct PushStatusDetailView: View {
    let entry: PushStatusEntry

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                if !entry.payloadItems.isEmpty {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Payload")
                            .font(.headline)

                        ForEach(entry.payloadItems) { item in
                            HStack(alignment: .top, spacing: 8) {
                                Text(item.id)
                                    .font(.subheadline)
                                    .foregroundStyle(.secondary)
                                    .frame(width: 120, alignment: .leading)

                                Text(item.value)
                                    .font(.subheadline)
                                    .frame(maxWidth: .infinity, alignment: .leading)
                            }
                        }
                    }
                }

                Text(entry.rawJSON)
                    .font(.system(.body, design: .monospaced))
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
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
