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
    private let onSave: (ParseServerConfiguration) -> Void
    private let onCancel: () -> Void

    @State private var name: String
    @State private var serverURLString: String
    @State private var validationMessage: String?

    init(
        existingConfiguration: ParseServerConfiguration?,
        isCancellationAllowed: Bool,
        onSave: @escaping (ParseServerConfiguration) -> Void,
        onCancel: @escaping () -> Void
    ) {
        self.existingConfiguration = existingConfiguration
        self.isCancellationAllowed = isCancellationAllowed
        self.onSave = onSave
        self.onCancel = onCancel
        _name = State(initialValue: existingConfiguration?.name ?? "")
        _serverURLString = State(initialValue: existingConfiguration?.serverURL.absoluteString ?? "")
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
                    TextField("Server URL", text: $serverURLString)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                        .keyboardType(.URL)
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

        guard !trimmedName.isEmpty else {
            validationMessage = "Please enter a name for this server."
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

        validationMessage = nil
        let configuration = ParseServerConfiguration(
            id: existingConfiguration?.id ?? UUID(),
            name: trimmedName,
            serverURL: url
        )
        onSave(configuration)
    }
}

#Preview {
    if let url = URL(string: "https://api.example.com/parse") {
        ParseServerConfigurationFormView(
            existingConfiguration: ParseServerConfiguration(
                name: "Production",
                serverURL: url
            ),
            isCancellationAllowed: true,
            onSave: { _ in },
            onCancel: {}
        )
    }
}
