//
//  ComposePushView.swift
//  ParsePush
//
//  Created by Thomas Kollbach on 26.01.26.
//

import SwiftUI

struct ComposePushView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var title = ""
    @State private var bodyText = ""
    @State private var target = PushTarget.allDevices
    @State private var isSoundEnabled = true
    @State private var isBadgeEnabled = false
    @State private var badgeCount = 1
    @State private var isTimeSensitive = false
    @State private var language = PushLanguage.all
    @State private var urlString = ""
    @State private var isPresentingDiscardConfirmation = false

    var body: some View {
        NavigationStack {
            Form {
                Section("Message") {
                    TextField("Title", text: $title)
                        .textInputAutocapitalization(.sentences)
                    TextField("Body", text: $bodyText, axis: .vertical)
                        .lineLimit(3, reservesSpace: true)
                }

                Section("Target") {
                    Picker("Audience", selection: $target) {
                        ForEach(PushTarget.allCases) { option in
                            Text(option.title)
                                .tag(option)
                        }
                    }
                }

                Section("Options") {
                    Toggle("Sound", isOn: $isSoundEnabled)

                    Toggle("Badge", isOn: $isBadgeEnabled)

                    if isBadgeEnabled {
                        Stepper(value: $badgeCount, in: 1...99) {
                            Text("Badge Count: \(badgeCount)")
                        }
                    }

                    Toggle("Time Sensitive", isOn: $isTimeSensitive)

                    Picker("Language", selection: $language) {
                        ForEach(PushLanguage.allCases) { option in
                            Text(option.title)
                                .tag(option)
                        }
                    }
                }

                Section("Link") {
                    TextField("URL (optional)", text: $urlString)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                        .keyboardType(.URL)
                    if !isURLValid {
                        Text("Enter a valid http or https URL.")
                            .foregroundStyle(.red)
                    }
                }

                Section {
                    Text("Draft sending options will be added here.")
                        .foregroundStyle(.secondary)
                }
            }
            .navigationTitle("Compose")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        handleCancel()
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Send") {
                    }
                    .disabled(!canSend)
                }
            }
        }
        .interactiveDismissDisabled(isDirty)
        .confirmationDialog(
            "Save this draft?",
            isPresented: $isPresentingDiscardConfirmation
        ) {
            Button("Save as Draft") {
            }
            Button("Discard", role: .destructive) {
                dismiss()
            }
            Button("Keep Editing", role: .cancel) {}
        } message: {
            Text("You can save it as a draft or discard it.")
        }
    }

    private var canSend: Bool {
        !bodyText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty && isURLValid
    }

    private var isURLValid: Bool {
        let trimmedURL = urlString.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedURL.isEmpty else {
            return true
        }
        guard let url = URL(string: trimmedURL), let scheme = url.scheme else {
            return false
        }
        return scheme == "http" || scheme == "https"
    }

    private var isDirty: Bool {
        let trimmedTitle = title.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedBody = bodyText.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedURL = urlString.trimmingCharacters(in: .whitespacesAndNewlines)
        return !trimmedTitle.isEmpty ||
            !trimmedBody.isEmpty ||
            target != .allDevices ||
            isSoundEnabled != true ||
            isBadgeEnabled ||
            badgeCount != 1 ||
            isTimeSensitive ||
            language != .all ||
            !trimmedURL.isEmpty
    }

    private func handleCancel() {
        if isDirty {
            isPresentingDiscardConfirmation = true
        } else {
            dismiss()
        }
    }
}

private enum PushTarget: String, CaseIterable, Identifiable {
    case allDevices
    case testDevices
    case segment

    var id: String { rawValue }

    var title: String {
        switch self {
        case .allDevices:
            return "All Devices"
        case .testDevices:
            return "Test Devices"
        case .segment:
            return "Segment"
        }
    }
}

private enum PushLanguage: String, CaseIterable, Identifiable {
    case all
    case de
    case en

    var id: String { rawValue }

    var title: String {
        switch self {
        case .all:
            return "All Languages"
        case .de:
            return "DE"
        case .en:
            return "EN"
        }
    }
}

#Preview {
    ComposePushView()
}
