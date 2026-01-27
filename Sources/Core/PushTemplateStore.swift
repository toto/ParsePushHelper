//
//  PushTemplateStore.swift
//  ParsePush
//
//  Created by Thomas Kollbach on 26.01.26.
//

import Foundation
import Observation
import SwiftUI

@MainActor
@Observable
public final class PushTemplateStore {
    private let fileManager: FileManager
    private let templatesURL: URL

    public private(set) var templates: [PushMessageTemplate] = []

    public init(fileManager: FileManager = .default, appSupportSubdirectory: String = "ParsePushHelper") {
        self.fileManager = fileManager
        guard let appSupport = fileManager.urls(for: .applicationSupportDirectory, in: .userDomainMask).first else {
            fatalError("Application Support directory is not available.")
        }
        self.templatesURL = appSupport
            .appending(path: appSupportSubdirectory, directoryHint: .isDirectory)
            .appending(path: "templates.json", directoryHint: .notDirectory)
        loadTemplates()
    }

    public func add(_ template: PushMessageTemplate) {
        templates.append(template)
        saveTemplates()
    }

    public func update(_ template: PushMessageTemplate) {
        if let index = templates.firstIndex(where: { $0.id == template.id }) {
            templates[index] = template
        } else {
            templates.append(template)
        }
        saveTemplates()
    }

    public func delete(ids: [PushMessageTemplate.ID]) {
        guard !ids.isEmpty else {
            return
        }
        templates.removeAll { ids.contains($0.id) }
        saveTemplates()
    }

    private func loadTemplates() {
        guard fileManager.fileExists(atPath: templatesURL.path) else {
            templates = []
            return
        }
        do {
            let data = try Data(contentsOf: templatesURL)
            templates = try JSONDecoder().decode([PushMessageTemplate].self, from: data)
        } catch {
            templates = []
        }
    }

    private func saveTemplates() {
        let directoryURL = templatesURL.deletingLastPathComponent()
        do {
            try fileManager.createDirectory(at: directoryURL, withIntermediateDirectories: true)
            let data = try JSONEncoder().encode(templates)
            try data.write(to: templatesURL)
        } catch {
            return
        }
    }
}
