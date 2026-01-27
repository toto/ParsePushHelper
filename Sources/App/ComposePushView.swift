//
//  ComposePushView.swift
//  ParsePush
//
//  Created by Thomas Kollbach on 26.01.26.
//

import SwiftUI

struct ComposePushView: View {
    let template: PushMessageTemplate?
    let templateStore: PushTemplateStore

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
    @State private var isPresentingSaveAsTemplate = false
    @State private var newTemplateName = ""

    init(template: PushMessageTemplate? = nil, templateStore: PushTemplateStore) {
        self.template = template
        self.templateStore = templateStore
    }

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
            }
            .navigationTitle(template != nil ? "Edit Template" : "New Template")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel", role: .cancel) {
                        handleCancel()
                    }
                }
                ToolbarItem(placement: .primaryAction) {
                    Button("Save") {
                        if template != nil {
                            updateTemplate()
                        } else {
                            isPresentingSaveAsTemplate = true
                        }
                    }
                    .disabled(!isDirty)
                }
            }
        }
        .onAppear {
            if let t = template {
                title = t.title
                bodyText = t.bodyText
                target = t.target
                isSoundEnabled = t.isSoundEnabled
                isBadgeEnabled = t.isBadgeEnabled
                badgeCount = t.badgeCount
                isTimeSensitive = t.isTimeSensitive
                language = t.language
                urlString = t.urlString
                newTemplateName = t.name
            }
        }
        .interactiveDismissDisabled(isDirty)
        .confirmationDialog("Save your changes?", isPresented: $isPresentingDiscardConfirmation) {
            Button("Save as template") {
                isPresentingDiscardConfirmation = false
                isPresentingSaveAsTemplate = true
            }
            Button("Discard", role: .destructive) {
                dismiss()
            }
            Button("Keep Editing", role: .cancel) {}
        } message: {
            Text("Save as a template or discard your changes?")
        }
        .alert("Template Name", isPresented: $isPresentingSaveAsTemplate) {
            TextField("Name", text: $newTemplateName)
            Button("Cancel", role: .cancel) {
                newTemplateName = template?.name ?? ""
            }
            Button("Save") {
                saveAsTemplate(name: newTemplateName.trimmingCharacters(in: .whitespacesAndNewlines))
            }
            .disabled(newTemplateName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
        } message: {
            Text("Enter a name for this local template.")
        }
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

    private func saveAsTemplate(name: String) {
        let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        let newTemplate = PushMessageTemplate(
            name: trimmed,
            title: title,
            bodyText: bodyText,
            target: target,
            isSoundEnabled: isSoundEnabled,
            isBadgeEnabled: isBadgeEnabled,
            badgeCount: badgeCount,
            isTimeSensitive: isTimeSensitive,
            language: language,
            urlString: urlString
        )
        templateStore.add(newTemplate)
        dismiss()
    }

    private func updateTemplate() {
        guard let t = template else { return }
        let updated = PushMessageTemplate(
            id: t.id,
            name: t.name,
            title: title,
            bodyText: bodyText,
            target: target,
            isSoundEnabled: isSoundEnabled,
            isBadgeEnabled: isBadgeEnabled,
            badgeCount: badgeCount,
            isTimeSensitive: isTimeSensitive,
            language: language,
            urlString: urlString
        )
        templateStore.update(updated)
        dismiss()
    }
}

#Preview {
    ComposePushView(templateStore: PushTemplateStore())
}
