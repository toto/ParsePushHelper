//
//  ParseServerConfigurationFormView.swift
//  ParsePush
//
//  Created by Thomas Kollbach on 26.01.26.
//

import SwiftUI

struct ParseServerConfigurationFormView: View {
    private let existingConfiguration: ParseServerConfiguration?
    private let isCancellationAllowed: Bool
    private let onSave: (ParseServerConfiguration, String) -> Void
    private let onCancel: () -> Void

    @State private var name: String
    @State private var serverURLString: String
    @State private var appID: String
    @State private var apiKey: String
    @State private var validationMessage: String?

    init(
        existingConfiguration: ParseServerConfiguration?,
        existingAPIKey: String,
        isCancellationAllowed: Bool,
        onSave: @escaping (ParseServerConfiguration, String) -> Void,
        onCancel: @escaping () -> Void
    ) {
        self.existingConfiguration = existingConfiguration
        self.isCancellationAllowed = isCancellationAllowed
        self.onSave = onSave
        self.onCancel = onCancel
        _name = State(initialValue: existingConfiguration?.name ?? "")
        _serverURLString = State(initialValue: existingConfiguration?.serverURL.absoluteString ?? "")
        _appID = State(initialValue: existingConfiguration?.appID ?? "")
        _apiKey = State(initialValue: existingAPIKey)
    }

    var body: some View {
        NavigationStack {
            Form {
                if let validationMessage {
                    Section {
                        Text(validationMessage)
                            .foregroundStyle(.red)
                    }
                }
                
                Section("Details") {
                    TextField("Name", text: $name)
                        .textInputAutocapitalization(.words)
                    TextField("App ID", text: $appID)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                    TextField("Server URL", text: $serverURLString)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                        .keyboardType(.URL)
                    SecureField("API Key", text: $apiKey)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                }

                
            }
            .navigationTitle(existingConfiguration == nil ? "Add Parse Server" : "Edit Parse Server")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    if isCancellationAllowed {
                        Button("Cancel") {
                            onCancel()
                        }
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        saveConfiguration()
                    }
                }
            }
        }
    }

    private func saveConfiguration() {
        let trimmedName = name.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedURL = serverURLString.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedAppID = appID.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedAPIKey = apiKey.trimmingCharacters(in: .whitespacesAndNewlines)

        guard !trimmedName.isEmpty else {
            validationMessage = "Please enter a name for this server."
            return
        }

        guard !trimmedAppID.isEmpty else {
            validationMessage = "Please enter an App ID."
            return
        }

        guard trimmedAppID.range(of: "^[A-Za-z0-9]+$", options: .regularExpression) != nil else {
            validationMessage = "App ID can only contain ASCII letters and numbers."
            return
        }

        guard let url = URL(string: trimmedURL), let scheme = url.scheme else {
            validationMessage = "Please enter a valid URL."
            return
        }

        guard scheme == "https" || scheme == "http" else {
            validationMessage = "The server URL must start with http or https."
            return
        }

        guard !trimmedAPIKey.isEmpty else {
            validationMessage = "Please enter an API key."
            return
        }

        validationMessage = nil
        let configuration = ParseServerConfiguration(
            id: existingConfiguration?.id ?? UUID(),
            name: trimmedName,
            serverURL: url,
            appID: trimmedAppID
        )
        onSave(configuration, trimmedAPIKey)
    }
}

#Preview {
    if let url = URL(string: "https://api.example.com/parse") {
        ParseServerConfigurationFormView(
            existingConfiguration: ParseServerConfiguration(
                name: "Production",
                serverURL: url,
                appID: "APP123"
            ),
            existingAPIKey: "preview-api-key",
            isCancellationAllowed: true,
            onSave: { _, _ in },
            onCancel: {}
        )
    }
}
